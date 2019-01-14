// Not a part of auto-generated code, but a library. Maybe in jar form?
// Or maybe is distributed between the plugins in form of framework.groovy script
class Plugin {
    def runCli(command) {

    }

    def trim(String input) {

    }

    // idk other utilities

    // Used to get to some plugin component, like template engine, http client - some shared library that may or may not be a part of plugin
    def getComponent(String componentName) {
        // will create a component object and return it
    }
}



class Configuration {
    def name
    def parameters
    def credentials
}


class Parameters {
    List<Parameter> parameters

    // parameters[name]
    def getAt(name) {
        return parameters.find { it.name == name }
    }
}

class Parameter {
    def name
    def value
    // expandable?
}


class StepResponse {

}


