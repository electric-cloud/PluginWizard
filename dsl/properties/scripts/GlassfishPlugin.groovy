// Generated code
class GlassfishPlugin extends Plugin {
    def stepDeploy(Parameters parameters, Configuration configuration) {
        // ... you code goes here

        logger.info "Some info"
        logger.debug "Debug information"

        def response = runCli("some command")
        if (response.code != 0) {
            throw new PluginException("Error while execution command")
        }

        def httpClient = httpClient()
        httpClient.get("url")

        // Autogenerated code....

        def response = new StepResponse() // a part of the framework
            .withCode(0)
            .withSummary("Deployed Successfully")
            .withOutputParameters([new OutputParameter('name', value)])
        return response
    }
}