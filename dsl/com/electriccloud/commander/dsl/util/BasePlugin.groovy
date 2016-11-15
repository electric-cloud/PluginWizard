package com.electriccloud.commander.dsl.util

import groovy.io.FileType
import groovy.util.XmlSlurper
import java.io.File

import org.codehaus.groovy.control.CompilerConfiguration
import com.electriccloud.commander.dsl.DslDelegatingScript

abstract class BasePlugin extends DslDelegatingScript {

    def stepPicker (String pickerLabel, String pluginKey, String procedureName, String category, String description  = '') {

		// This is important, if the step-picker property does not have a description,
		// then the plugin lookup when defining procedure step fails with a GWT/JavaScript error.
		String propDescription = description ?: procedureName

		property "/server/ec_customEditors/pickerStep/$pickerLabel",
			value:
				"""<step>
						<project>/plugins/$pluginKey/project</project>
						<procedure>$procedureName</procedure>
						<category>$category</category>
					</step>
				""".stripIndent(),
			description: propDescription
	} 

	def setupCustomEditorData(String pluginKey, String pluginName, String pluginCategory) {
		getProcedures(pluginName).each { proc ->
			procedure proc.procedureName, {
				getFormalParameters(pluginName, procedureName: proc.procedureName).each { param ->
					property 'ec_customEditorData', procedureName: proc.procedureName, {

						property 'parameters', {

							property param.formalParameterName, {
								formType = 'standard'
								if ('checkbox'.equals(param.type)) {
									checkedValue = 'true'
									initiallyChecked = '0'
									uncheckedValue = 'false'
								}
							}
						}
					}
				}
			}

			def addStepPicker = shouldAddStepPicker(pluginName, proc.procedureName)
			println "/projects/${pluginName}/procedures/${proc.procedureName}/standardStepPicker: '$addStepPicker'"
			if (addStepPicker) {
				def label = "$pluginKey - $proc.procedureName"
				def description = proc.description
				stepPicker (label, pluginKey, proc.procedureName, pluginCategory, description)
			}
			
		}
	}
	
	def cleanup(String pluginKey, String pluginName, String pluginCategory) {
		getProcedures(pluginName).each { proc ->
			
			def addStepPicker = shouldAddStepPicker(pluginName, proc.procedureName)
			// delete the step picker if it was added by setupCustomEditorData
			if (addStepPicker) {
				def label = "$pluginKey - $proc.procedureName"
				def propName = "/server/ec_customEditors/pickerStep/$label"
				def stepPickerProp = getProperty(propName, suppressNoSuchPropertyException: true)
				if (stepPickerProp) {
					deleteProperty propertyName: propName
				}
			}
			
		}
	}

	def shouldAddStepPicker(def pluginName, def procedureName) {
		if (procedureName == 'CreateConfiguration' || procedureName == 'DeleteConfiguration') {
			return false
		}
		def standardStepPicker = getProperty("/projects/${pluginName}/procedures/${procedureName}/standardStepPicker", suppressNoSuchPropertyException: true)
		return !(standardStepPicker == 'false' || standardStepPicker == '0')
	}

	def loadPluginProperties(String pluginDir) {

		// Recursively navigate each file or sub-directory in the properties directory
		//Create a property corresponding to a file,
		// or create a property sheet for a sub-directory before navigating into it
		loadNestedProperties(new File(pluginDir, 'dsl/properties'))
	}

	def loadNestedProperties(File propsDir) {

		propsDir.eachFile { dir ->
			int extension = dir.name.lastIndexOf('.')
			int endIndex = extension > -1 ? extension : dir.name.length()
			String propName = dir.name.substring(0, endIndex)
			if (dir.directory) {
				property propName, {
					loadNestedProperties(dir)
				}
			} else {
				property propertyName: propName, value: dir.text
			}
		}
	}

	def loadProcedures(String pluginDir, String pluginKey, String pluginName, pluginCategory) {

		// Loop over the sub-directories in the procedures directory
		// and evaluate procedures if a procedure.dsl file exists
		
		File procsDir = new File(pluginDir, 'dsl/procedures')
		procsDir.eachDir { 
			
			File procDslFile = new File(it, 'procedure.dsl')
			println "Processing procedure DSL file ${procDslFile.absolutePath}"
			if (procDslFile.exists()) {
				def proc = loadProcedure(pluginDir, pluginKey, pluginName, procDslFile.absolutePath)
				
				//create formal parameters using form.xml
				File formXml = new File(it, 'form.xml')
				if (formXml.exists()) {
				    println "Processing form XML $formXml.absolutePath"
					buildFormalParametersFromFormXml(proc, formXml)
				}

			}
			
		}
		
		// plugin boiler-plate
		setupCustomEditorData(pluginKey, pluginName, pluginCategory)
	}
	
	def loadProcedure(String pluginDir, String pluginKey, String pluginName, String dslFile) {
		return evalInlineDsl(dslFile, [pluginKey: pluginKey, pluginName: pluginName, pluginDir: pluginDir])
	}
	
	//Helper function to load another dsl script and evaluate it in-context
	def evalInlineDsl(String dslFile, Map bindingMap) {
	
		CompilerConfiguration cc = new CompilerConfiguration();
		cc.setScriptBaseClass(DelegatingScript.class.getName());
		GroovyShell sh = new GroovyShell(this.class.classLoader, bindingMap? new Binding(bindingMap) : new Binding(), cc);
		DelegatingScript script = (DelegatingScript)sh.parse(new File(dslFile))
		script.setDelegate(this);
		return script.run();
	}
	
	def buildFormalParametersFromFormXml(def proc, File formXml) {
	
		def formElements = new XmlSlurper().parseText(formXml.text)
		
		procedure proc.procedureName, {
				
				ec_parameterForm = formXml.text
				//TODO: Update help link in form.xml 
				formElements.formElement.each {
						formalParameter it.property, 
							defaultValue: it.value,
							required: it.required,
							description: it.description,
							type: it.type,
							label: it.label

						if (it['attachedAsParameterToStep'] && it['attachedAsParameterToStep'] != '') {

								attachParameter(projectName: proc.projectName,
										procedureName: proc.procedureName,
										stepName: it['attachedAsParameterToStep'],
										formalParameterName: it.property)
						}

				}	
		}
	}

	def upgrade(String upgradeAction, String pluginName,
								String otherPluginName, Map steps,
								String configName = 'ec_plugin_cfgs') {

		migrationConfigurations(upgradeAction, pluginName, otherPluginName, steps, configName)
	}

	def migrationConfigurations(String upgradeAction, String pluginName,
								String otherPluginName, Map steps,
								String configName = 'ec_plugin_cfgs') {

		if (upgradeAction == 'upgrade') {

			//Copy configurations from otherPluginName
			def configs = getProperty("/plugins/$otherPluginName/project/$configName", suppressNoSuchPropertyException: true)
			def credentials = getCredentials("/plugins/$otherPluginName")

			if (configs) {
				clone path: "/plugins/$otherPluginName/project/$configName",
						cloneName: "/plugins/$pluginName/project/$configName"
			}

			if (credentials) {
				credentials.each { cred ->
					clone path: "/plugins/$otherPluginName/project/credentials/${cred.credentialName}",
							cloneName: "/plugins/$pluginName/project/credentials/${cred.credentialName}"

					aclEntry principalType: 'user',
							principalName: "project: $pluginName",
							projectName: pluginName,
							credentialName: cred.credentialName,
							objectType: 'credential',
							readPrivilege: 'allow',
							modifyPrivilege: 'allow',
							executePrivilege: 'allow',
							changePermissionsPrivilege: 'allow'

					steps.each { s ->
						attachCredential projectName: pluginName,
								credentialName: cred.credentialName,
								procedureName: s.procedureName,
								stepName: s.stepName
					}

				}
			}
		}
	}
}