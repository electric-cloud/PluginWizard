import java.io.File

def procName = 'groovyProcedureTemplate'
procedure procName, {

	step 'Retrieve Dependencies',
    	  command: new File(pluginDir, "dsl/procedures/$procName/steps/retrieveDependencies.pl").text,
    	  shell: 'ec-perl'

    step 'step1', {
        command: new File(pluginDir, "dsl/procedures/$procName/steps/step1.groovy").text
        shell: 'ec-groovy'
    }

}

