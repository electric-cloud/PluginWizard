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

$|=1;


sub main() {
    my $ec = ElectricCommander->new();
    $ec->abortOnError(1);
    retrieveLibs($ec);
}

sub retrieveLibs {
    my ($ec) = @_;

    my $property = '/projects/$[/myProject/projectName]/ec_groovyDependencies';
    print "Libs property: $property\n";
    my $libsBase64 = '';
    my $xpath;
    eval {
        $xpath = $ec->getProperties({path => $property});
        1;
    } or do {
        print "[ERROR] cannot get property $property: $@";
        exit -1;
    };

    my $checksum = '';
    my $blocks = {};
    for my $prop ($xpath->findnodes('//property')) {
        my $name = $prop->findvalue('propertyName')->string_value;
        my $value = $prop->findvalue('value')->string_value;
        if ($name eq 'checksum') {
            $checksum = $value;
        }
        else {
            $name =~ s/ec_dependencyChunk_//;
            $blocks->{$name} = $value;
        }
    }

    unless($checksum) {
        print "[ERROR] No checksum found";
        exit -1;
    }

    for my $name (sort { $a <=> $b } keys %$blocks) {
        $libsBase64 .= $blocks->{$name};
    }
    my $finalChecksum = md5_hex($libsBase64);
    if ($finalChecksum ne $checksum) {
        print "[ERROR] checksums do not match, expected checksum: $checksum, got checksum: $finalChecksum";
        exit -1;
    }

    my $binary = decode_base64($libsBase64);

    my ($tempFh, $tempFilename) = tempfile(CLEANUP => 1);
    binmode($tempFh);
    print $tempFh $binary;
    close $tempFh;

    my $zip = Archive::Zip->new($tempFilename);

    my @members = $zip->members;
    for my $member ( $zip->members ) {
        print $member->fileName . "\n";
    }
    my $dataDirectory = $ENV{COMMANDER_DATA} || die 'Data directory is not defined!';
    my $destinationFolder = File::Spec->catfile($ENV{COMMANDER_DATA}, 'grape', '');

    $zip->extractTree('lib', $destinationFolder);
    print "Extracted dependencies into $destinationFolder\n";
}


main();

1;
