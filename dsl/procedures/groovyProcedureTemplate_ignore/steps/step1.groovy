// the following line will load all the classes referenced in scripts/preamble file
$[/myProject/scripts/preamble]

// Working with dependencies
import com.google.common.collect.HashBiMap
@Grab(group='com.google.code.google-collections', module='google-collect', version='snapshot-20080530')

def getFruit() { [grape:'purple', lemon:'yellow', orange:'orange'] as HashBiMap }
assert fruit.lemon == 'yellow'
assert fruit.inverse().yellow == 'lemon'


// Working with plugin's own libraries
EFPlugin efPlugin = new EFPlugin() // we have access to the class thanks to the preamble at the top of this file
def configName = '$[config]' // getting configName parameter value
def configuration = efPlugin.getConfiguration(configName)
PluginLogic logic = new PluginLogic()
def result = logic.processSomeProcedure(configuration)
efPlugin.setProperty_1('/myJob/result', result)
