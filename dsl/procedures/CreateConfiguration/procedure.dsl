import java.io.File

def procName = 'CreateConfiguration'
procedure procName,
        description: 'Creates a plugin configuration', {

    step 'createConfiguration',
            command: new File(pluginDir, "dsl/procedures/$procName/steps/createConfiguration.pl").text,
            errorHandling: 'abortProcedure',
            exclusiveMode: 'none',
            postProcessor: 'postp',
            releaseMode: 'none',
            shell: 'ec-perl',
            timeLimitUnits: 'minutes'

    step 'createAndAttachCredential',
        command: new File(pluginDir, "dsl/procedures/$procName/steps/createAndAttachCredential.pl").text,
        errorHandling: 'failProcedure',
        exclusiveMode: 'none',
        releaseMode: 'none',
        shell: 'ec-perl',
        timeLimitUnits: 'minutes'

}
