import java.io.File

def procName = 'groovyProcedureTemplate'
procedure procName, description: 'Sample Groovy-based procedure', {

	step 'Setup', {
        subprocedure = 'Setup'
    }

    step 'step1', {
        command = new File(pluginDir, "dsl/procedures/$procName/steps/step1.groovy").text
        shell = 'ec-groovy'
    }

}

