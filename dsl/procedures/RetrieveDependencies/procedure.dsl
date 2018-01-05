import java.io.File

def procName = 'RetrieveDependencies'
procedure procName, description: 'Retrieves Groovy dependencies', {
    property 'standardStepPicker', value: false

	step 'Setup',
        command: new File(pluginDir, "dsl/procedures/$procName/steps/retrieveDependencies.pl").text,
        shell: 'ec-perl'
}

