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

use ElectricCommander;
use constant {
               SUCCESS => 0,
               ERROR   => 1,
             };
             
my $ec = new ElectricCommander();
$ec->abortOnError(0);

# check to see if a config with this name already exists before we do anything else
my $xpath    = $ec->getProperty("/myProject/ec_plugin_cfgs/$[config]");
my $property = $xpath->findvalue("//response/property/propertyName");

if (! defined $property or "$property" eq "") {
    my $msg = "Configuration $[config] doesn't exist.";
    print $msg;
    $ec->setProperty("/myCall/summary", $msg);
    $ec->setProperty('/myJobStep/outcome', 'error');
    exit ERROR;
}

$ec->deleteProperty("/myProject/ec_plugin_cfgs/$[config]");
$ec->deleteCredential("$[/myProject/projectName]", "$[config]");
exit SUCCESS;
