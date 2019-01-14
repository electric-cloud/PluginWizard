import java.io.File

def procName = 'Deploy'
def procFolder = 'Deploy'

// Imagine this code to be generated from
/*
procedures:
    - name: 'My Generated Procedure'
      description: 'procedure description'
      steps:
        step1:
            shell: 'ec-groovy'
            timeout: ...
            aboutOnError: ...
      attachCrdentials: true
      parameters:
        - name: param1
          documentation: Some doc, maybe in MD??
          type: entry
          required: 1
          label: Param 1
          ....

*/
procedure procName, description: 'procedure description', {

	step 'step1',
	  command: new File(pluginDir, "dsl/procedures/$procFolder/steps/step1.groovy").text,
      shell: 'ec-groovy'
}

