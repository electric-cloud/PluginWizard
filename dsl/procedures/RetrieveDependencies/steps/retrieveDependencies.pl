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
use MIME::Base64;
use File::Temp qw(tempfile tempdir);
use warnings;
use strict;
use Archive::Zip;
use Digest::MD5 qw(md5_hex);
use File::Spec;
use JSON qw(decode_json);

$|=1;

my $ec = ElectricCommander->new();

sub main() {

    grabResource();

    eval {
        sendDependencies();
    };
    if ($@) {
        my $err = $@;
        $ec->setProperty('/myJobStep/summary', $err);
        exit 1;
    }
}

sub grabResource {
    my $resName = '$[/myResource/resourceName]';
    $ec->setProperty('/myJob/grabbedResource', $resName);
    print "Grabbed Resource: $resName\n";
}

sub getServerResource {
    return 'local';
}


sub sendDependencies {
    my $serverResource = getServerResource();
    my $grapeFolder = File::Spec->catfile($ENV{COMMANDER_DATA}, 'grape');
    my $channel = int rand 9999999;
    my $sendStep = q{
use strict;
use warnings;
use ElectricCommander;
use JSON qw(encode_json);
use Data::Dumper;

my $ec = ElectricCommander->new;

my $pluginsFolder = eval {
    $ec->getProperty('/server/settings/pluginsDirectory')->findvalue('//value')->string_value;
};
if ($@) {
    handleError("Cannot get plugins folder, check for /server/settings/pluginsDirectory server property");
}

unless( -d $pluginsFolder ){
    handleError("Plugins folder $pluginsFolder does not exist");
}

my $projectName = '$[/myProject/projectName]';
my $folder = File::Spec->catfile($pluginsFolder, $projectName, 'lib');
unless(-d $folder) {
    handleError("Folder $folder does not exist");
}

my @files = scanFiles($folder);

my %mapping = ();
my $channel = '#channel#';
print "Channel: $channel\n";
# Will be replaced
my $grapeFolder = '#grapeFolder#';
# TODO checksums
for my $file (@files) {
    my $relPath = File::Spec->abs2rel($file, $folder);
    my $destPath = "$grapeFolder/$relPath";
    $mapping{$file} = $destPath;
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

    $sendStep =~ s/\#grapeFolder\#/$grapeFolder/;
    $sendStep =~ s/\#channel\#/$channel/;
    my $xpath = $ec->createJobStep({
        jobStepName => 'Grab Dependencies',
        command => $sendStep,
        shell => 'ec-perl',
        resourceName => $serverResource
    });

    my $jobStepId = $xpath->findvalue('//jobStepId')->string_value;
    print "Job Step ID: $jobStepId\n";
    my $completed = 0;
    while(!$completed) {
        my $status = $ec->getJobStepStatus($jobStepId)->findvalue('//status')->string_value;
        if ($status eq 'completed') {
            $completed = 1;
        }
    }

    my $err;
    my $timeout = 60;
    $ec->getFiles({error => \$err, channel => $channel, timeout => $timeout});
    if ($err) {
        die $err;
    }
    my $files = eval {
        $ec->getProperty('/myJob/ec_dependencies_files')->findvalue('//value')->string_value;
    };
    if ($@) {
        die "Cannot get property ec_dependencies_files from the job: $@";
    }

    my $mapping = decode_json($files);
    for my $file (keys %$mapping) {
        my $dest = $mapping->{$file};
        if (-f $dest) {
            print "Got file $dest\n";
        }
        else {
            die "The file $dest was not received\n";
        }
    }
}



main();

1;
