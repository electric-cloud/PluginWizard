#
#  Copyright 2016 Electric Cloud, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
# File Version: Wed Oct 17 15:14:57 2018

=head1 NAME

retrieveGrapeDependencies.pl

=head1 DESCRIPTION


Retrieves artifacts published as artifact EC-Docker-Grapes
to the grape root directory configured with ec-groovy.

=head1 METHODS

=cut

use File::Copy::Recursive qw(rcopy);
use File::Path;
use ElectricCommander;

use warnings;
use strict;
$|=1;


$::gAdditionalArtifactVersion = "$[additionalArtifactVersion]";

sub main() {
    my $ec = ElectricCommander->new();
    $ec->abortOnError(1);

    my $pluginName = eval {
        $ec->getProperty('additionalPluginName')->findvalue('//value')->string_value
    };
    my @projects = ();
    push @projects, '$[/myProject/projectName]';

    if ($pluginName) {
        # This is a new one
        my @names = split(/\s*,\s*/, $pluginName);
        for my $name (@names) {
            my $projectName = $ec->getPlugin($pluginName)->findvalue('//projectName')->string_value;
            push @projects, $projectName;
        }
    }

    retrieveDependencies($ec, @projects);

    # This part remains as is
    if ($::gAdditionalArtifactVersion ne '') {
        my @versions = split(/\s*,\s*/, $::gAdditionalArtifactVersion);
        for my $version (@versions) {
            retrieveGrapeDependency($ec, $version);
        }
    }
}


sub retrieveDependencies {
    my ($ec, @projects) = @_;

    my $dep = EC::DependencyManager->new($ec);
    $dep->grabResource();
    eval {
        $dep->sendDependencies(@projects);
    };
    if ($@) {
        my $err = $@;
        print "$err\n";
        $ec->setProperty('/myJobStep/summary', $err);
        exit 1;
    }
}

########################################################################
# retrieveGrapeDependency - Retrieves the artifact version and copies it
# to the grape directory used by ec-groovy for @Grab dependencies
#
# Arguments:
#   -ec
#   -artifactVersion
########################################################################
sub retrieveGrapeDependency($){
    my ($ec, $artifactVersion) = @_;

    my $xpath = $ec->retrieveArtifactVersions({
        artifactVersionName => $artifactVersion
    });

    # copy to the grape directory ourselves instead of letting
    # retrieveArtifactVersions download to it directly to give
    # us better control over the over-write/update capability.
    # We want to copy only files the retrieved files leaving
    # the other files in the grapes directory unchanged.
    my $dataDir = $ENV{COMMANDER_DATA};
    die "ERROR: Data directory not defined!" unless ($dataDir);

    my $grapesDir = $ENV{COMMANDER_DATA} . '/grape/grapes';
    my $dir = $xpath->findvalue("//artifactVersion/cacheDirectory");

    mkpath($grapesDir);
    die "ERROR: Cannot create target directory" unless( -e $grapesDir );

    rcopy( $dir, $grapesDir) or die "Copy failed: $!";
    print "Retrieved and copied grape dependencies from $dir to $grapesDir\n";
}

main();

1;


# File Version: Wed Oct 17 15:24:07 2018

package EC::DependencyManager;
use strict;
use warnings;

use File::Spec;
use JSON qw(decode_json);
use File::Copy::Recursive qw(rcopy rmove);

our $VERSION = '1.0.0';

sub new {
    my ($class, $ec) = @_;

    my $self = { ec => $ec };
    return bless $self, $class;
}

sub ec {
    return shift->{ec};
}

sub grabResource {
    my ($self) = @_;

    my $resName = '$[/myResource/resourceName]';
    $self->ec->setProperty('/myJob/grabbedResource', $resName);
    print "Grabbed Resource: $resName\n";
}

sub getLocalResource {
    my ($self) = @_;

    my @filterList = ();

    my $propertyPath = '/server/settings/localResourceName';
    my $serverResource = eval {
        $self->ec->getProperty($propertyPath)->findvalue('//value')->string_value
    };

    if ($serverResource) {
        print "Configured Local Resource is $serverResource (taken from $propertyPath)\n";
        return $serverResource;
    }

    push (@filterList, {"propertyName" => "hostName",
                            "operator" => "equals",
                            "operand1" => "localhost"});

    push (@filterList, {"propertyName" => "hostName",
                            "operator" => "equals",
                            "operand1" => "127.0.0.1"});

    my $hostname = $self->ec->getProperty('/server/hostName')->findvalue('//value')->string_value;
    print "Hostname is $hostname\n";

    push (@filterList, {"propertyName" => "hostName",
                            "operator" => "equals",
                            "operand1" => "$hostname"});

    push (@filterList, {"propertyName" => "resourceName",
                            "operator" => "equals",
                            "operand1" => "local"});


    my $result = $self->ec->findObjects('resource',
            {filter => [
         { operator => 'or',
             filter => \@filterList,
        }
      ], numObjects => 1}
    );

    my $resourceName = eval {
        $result->findvalue('//resourceName')->string_value;
    };
    unless($resourceName) {
        die "Cannot find local resource and there is no local resource in the configuration. Please set property $propertyPath to the name of your local resource or resource pool.";
    }
    print "Found local resource: $resourceName\n";
    return $resourceName;
}


sub copyDependencies {
    my ($self, $projectName) = @_;

    my $source = $self->getPluginsFolder() . "/$projectName/lib";
    my $dest = File::Spec->catfile($ENV{COMMANDER_DATA}, 'grape');
    unless(-d $source) {
        die "Folder $source does not exist, please try to reinstall the plugin."
    }

    unless(-d $dest) {
        mkdir($dest);
    }

    unless( -w $dest) {
        die "$dest is not writable. Please allow agent user to write to this directory."
    }

    my $filesCopied = rcopy($source, $dest);
    if ($filesCopied == 0) {
        die "Copy failed, no files were copied from $source to $dest, please check permissions for $dest";
    }
}


sub getPluginsFolder {
    my ($self) = @_;

    return $self->ec->getProperty('/server/settings/pluginsDirectory')->findvalue('//value')->string_value;
}

sub sendDependencies {
    my ($self, @projects) = @_;

    my $serverResource = $self->getLocalResource();
    my $currentResource = '$[/myResource/resourceName]';
    if ($serverResource eq $currentResource) {
        for my $projectName (@projects) {
            $self->copyDependencies($projectName);
        }
        return;
    }

    my $grapeFolder = File::Spec->catfile($ENV{COMMANDER_DATA}, 'grape');
    my $windows = $^O =~ /win32/;

    my $channel = int rand 9999999;

    my $pluginsFolder = $self->getPluginsFolder;
    my @folders = map {
        $pluginsFolder . '/' . $_;
    } @projects;

    my $sendStep = q{
use strict;
use warnings;
use ElectricCommander;
use JSON qw(encode_json);
use Data::Dumper;

my $pluginFolders = '#pluginFolders#';
my @folders = split(';', $pluginFolders);

my $ec = ElectricCommander->new;
my $channel = '#channel#';
print "Channel: $channel\n";

my %mapping = ();
for my $folder (@folders) {
    $folder = File::Spec->catfile($folder, 'lib');
    print "$folder\n";
    unless(-d $folder) {
        handleError("Folder $folder does not exist");
    }
    my @files = scanFiles($folder);


    for my $file (@files) {
        my $relPath = File::Spec->abs2rel($file, $folder);
        my $destPath = "grape/$relPath";
        $mapping{$file} = $destPath;
    }
}

my $response = $ec->putFiles($ENV{COMMANDER_JOBID}, \%mapping, {channel => $channel});
$ec->setProperty('/myJob/ec_dependencies_files', encode_json(\%mapping));

sub handleError {
    my ($error) = @_;

    print 'Error: ' . $error;
    $ec->setProperty('/myJobStep/summary', $error);
    exit 1;
}

sub scanFiles {
    my ($dir) = @_;

    my @files = ();
    opendir my $dh, $dir or handleError("Cannot open folder $dir: $!");
    for my $file (readdir $dh) {
        next if $file =~ /^\./;

        my $fullPath = File::Spec->catfile($dir, $file);
        if (-d $fullPath) {
            push @files, scanFiles($fullPath);
        }
        else {
            push @files, $fullPath;
        }
    }
    return @files;
}

    };

    my $pluginFolders = join(';', @folders);
    $sendStep =~ s/\#pluginFolders\#/$pluginFolders/;
    $sendStep =~ s/\#channel\#/$channel/;

    my $xpath = $self->ec->createJobStep({
        jobStepName => 'Grab Dependencies',
        command => $sendStep,
        shell => 'ec-perl',
        resourceName => $serverResource
    });

    my $jobStepId = $xpath->findvalue('//jobStepId')->string_value;
    print "Job Step ID: $jobStepId\n";
    my $completed = 0;
    while(!$completed) {
        my $status = $self->ec->getJobStepStatus($jobStepId)->findvalue('//status')->string_value;
        if ($status eq 'completed') {
            $completed = 1;
        }
    }

    my $err;
    my $timeout = 60;
    $self->ec->getFiles({error => \$err, channel => $channel, timeout => $timeout});
    if ($err) {
        die $err;
    }
    my $files = eval {
        $self->ec->getProperty('/myJob/ec_dependencies_files')->findvalue('//value')->string_value;
    };
    if ($@) {
        die "Cannot get property ec_dependencies_files from the job: $@";
    }

    my $mapping = decode_json($files);
    for my $file (keys %$mapping) {
        my $dest = $mapping->{$file};
        if (-f $dest) {

        }
        else {
            die "The file $dest was not received\n";
        }
    }

    unless(-d $grapeFolder) {
        mkdir $grapeFolder;
    }

    unless( -w $grapeFolder) {
        die "$grapeFolder is not writable. Please allow agent user to write to this directory."
    }
    my $filesCopied = rmove('grape', $grapeFolder);
    if ($filesCopied == 0) {
        die "Copy failed, no files were copied to $grapeFolder, please check permissions for the directory $grapeFolder";
    }
}

1;

