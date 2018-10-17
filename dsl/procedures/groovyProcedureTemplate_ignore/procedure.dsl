import java.io.File

def procName = 'groovyProcedureTemplate'
procedure procName, {

	step 'Retrieve Dependencies',
    	  subproject: '',
          subprocedure: 'Setup',
          command: null

    step 'step1', {
        command: new File(pluginDir, "dsl/procedures/$procName/steps/step1.groovy").text
        shell: 'ec-groovy'
    }

}

