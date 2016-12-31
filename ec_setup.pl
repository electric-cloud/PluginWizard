use Cwd;
use File::Spec;
use POSIX;
my $dir = getcwd;
my $logfile ="";
my $pluginDir;


if ( defined $ENV{QUERY_STRING} ) {    # Promotion through UI
    $pluginDir = $ENV{COMMANDER_PLUGINS} . "/$pluginName";
}
else {
    my $commanderPluginDir = $commander->getProperty('/server/settings/pluginsDirectory')->findvalue('//value');
    unless ( $commanderPluginDir && -d $commanderPluginDir ) {
        die "Cannot find commander plugin dir, please ensure that the option server/settings/pluginsDirectory is set up correctly";
    }
    $pluginDir = File::Spec->catfile($commanderPluginDir, $pluginName);
}

$logfile .= "Plugin directory is $pluginDir";

$commander->setProperty("/plugins/$pluginName/project/pluginDir", {value=>$pluginDir});
$logfile .= "Plugin Name: $pluginName\n";
$logfile .= "Current directory: $dir\n";

# Evaluate promote.groovy or demote.groovy based on whether plugin is being promoted or demoted ($promoteAction)
local $/ = undef;
# If env variable QUERY_STRING exists:
my $dslFilePath;
if(defined $ENV{QUERY_STRING}) { # Promotion through UI
    $dslFilePath = File::Spec->catfile($ENV{COMMANDER_PLUGINS}, $pluginName, "dsl", "$promoteAction.groovy");
} else {  # Promotion from the command line
    $dslFilePath = File::Spec->catfile($pluginDir, "dsl", "$promoteAction.groovy");
}

open FILE, $dslFilePath or die "Couldn't open file: $dslFilePath: $!";
my $dsl = <FILE>;
close FILE;
my $dslReponse = $commander->evalDsl(
    $dsl, {
        parameters => qq(
                     {
                       "pluginName":"$pluginName",
                       "upgradeAction":"$upgradeAction",
                       "otherPluginName":"$otherPluginName"
                     }
              ),
        debug             => 'false',
        serverLibraryPath => File::Spec->catdir( $pluginDir, 'dsl' ),
    },
);


$logfile .= $dslReponse->findnodes_as_string("/");

my $errorMessage = $commander->getError();

# Create output property for plugin setup debug logs
my $nowString = localtime;
$commander->setProperty( "/plugins/$pluginName/project/logs/$nowString", { value => $logfile } );

die $errorMessage unless !$errorMessage
