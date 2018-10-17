import java.io.File

procedure 'Setup',
	description: 'Downloads grape dependencies from the repository server and stores in the agent\'s grape directory for use by ec-groovy.', {

    // don't add a step picker for this procedure since it is internally invoked
    property 'standardStepPicker', value: false

	step 'setup',
    	  command: new File(pluginDir, 'dsl/procedures/setup/steps/retrieveGrapeDependencies.pl').text,
    	  errorHandling: 'failProcedure',
    	  exclusiveMode: 'none',
    	  postProcessor: 'postp',
    	  releaseMode: 'none',
    	  shell: 'ec-perl',
    	  timeLimitUnits: 'minutes'

}

