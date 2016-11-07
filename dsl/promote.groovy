import groovy.transform.BaseScript
import com.electriccloud.commander.dsl.util.BasePlugin

//noinspection GroovyUnusedAssignment
@BaseScript BasePlugin baseScript

// Variables available for use in DSL code
def pluginName = args.pluginName
def upgradeAction = args.upgradeAction
def otherPluginName = args.otherPluginName

def pluginKey = getProject("/plugins/$pluginName/project").pluginKey
def pluginDir = getProperty("/projects/$pluginName/pluginDir").value

def pluginCategory = 'Utilities'
project pluginName, {
	
	ec_visibility = 'pickListOnly'

	loadPluginProperties(pluginDir)
	loadProcedures(pluginDir, pluginKey, pluginName, pluginCategory)

}

//Grant permissions to the plugin project
def objTypes = ['resources', 'workspaces', 'projects'];

objTypes.each { type ->
		aclEntry principalType: 'user', 
			 principalName: "project: $pluginName",
			 systemObjectName: type,
             objectType: 'systemObject',
			 readPrivilege: 'allow', 
			 modifyPrivilege: 'allow',
			 executePrivilege: 'allow',
			 changePermissionsPrivilege: 'allow'
}

