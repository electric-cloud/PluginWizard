use Cwd;
use File::Spec;
use POSIX;
use MIME::Base64;
use File::Temp qw(tempfile tempdir);
use Archive::Zip;

my $dir = getcwd;
my $logfile ="";
my $pluginDir;


if ( defined $ENV{QUERY_STRING} ) {    # Promotion through UI
    $pluginDir = $ENV{COMMANDER_PLUGINS} . "/$pluginName";
}
else {
    my $commanderPluginDir = $commander->getProperty('/server/settings/pluginsDirectory')->findvalue('//value');
    # We are not checking for the directory, because we can run this script on a different machine
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

my $demoteDsl = q{
# demote.groovy placeholder
};

my $promoteDsl = q{
# promote.groovy placeholder
};


my $dsl;
if ($promoteAction eq 'promote') {
  $dsl = $promoteDsl;
}
else {
  $dsl = $demoteDsl;
}


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

if ( !$errorMessage ) {
    # This is here because we cannot do publishArtifactVersion in dsl today
    # delete artifact if it exists first

    my $dependenciesProperty = '/projects/@PLUGIN_NAME@/ec_groovyDependencies';
    my $base64 = '';
    eval {
      $base64 = $commander->getProperty($dependenciesProperty)->findvalue('//value')->string_value;
      1;
    };

    if ($base64) {
      my $grapesVersion = '1.0.0';
      my $groupId = 'com.electriccloud';
      $commander->deleteArtifactVersion($groupId . ':@PLUGIN_KEY@-Grapes:' . $grapesVersion);
      my $binary = decode_base64($base64);
      my ($tempFh, $tempFilename) = tempfile(CLEANUP => 1);
      binmode($tempFh);
      print $tempFh $binary;
      close $tempFh;

      my ($tempDir) = tempdir(CLEANUP => 1);
      my $zip = Archive::Zip->new();
      unless($zip->read($tempFilename) == Archive::Zip::AZ_OK()) {
        die "Cannot read .zip dependencies: $!";
      }
      $zip->extractTree("", File::Spec->catfile($tempDir, ''));

      if ( $promoteAction eq "promote" ) {
          #publish jars to the repo server if the plugin project was created successfully
          my $am = new ElectricCommander::ArtifactManagement($commander);
          my $artifactVersion = $am->publish(
              {   groupId         => $groupId,
                  artifactKey     => '@PLUGIN_KEY@-Grapes',
                  version         => $grapesVersion,
                  includePatterns => "**",
                  fromDirectory   => "$tempDir/lib/grapes",
                  description => 'JARs that @PLUGIN_KEY@ plugin procedures depend on'
              }
          );

          # Print out the xml of the published artifactVersion.
          $logfile .= $artifactVersion->xml() . "\n";

          if ( $artifactVersion->diagnostics() ) {
              $logfile .= "\nDetails:\n" . $artifactVersion->diagnostics();
          }
      }
    }
}


# Create output property for plugin setup debug logs
my $nowString = localtime;
$commander->setProperty( "/plugins/$pluginName/project/logs/$nowString", { value => $logfile } );

die $errorMessage unless !$errorMessage
