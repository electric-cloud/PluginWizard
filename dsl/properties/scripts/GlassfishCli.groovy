
// bindings:
//   type: cli
//   commands:
//     deploy:
//       parameters:
//         - name: appName
//           required: 1
//         - name: appPath
//           required: 0
//       command: "{{clipath}} deploy -app {appName} -appPath {appPath}"
// Generated code
class GlassfishCli {
    def cliPath
    // ??? configuration

    def deploy(appName) {
        def commandTemplate = "{{clipath}} deploy -app {appName} -appPath {appPath}"
        def command = generateCommand(commandTemplate, appName: appName)
        def response = runCommand(command)
        if (response.code != 0) {
            throw new RuntimeException("Error: ${response.stderr}")
        }
        return response
    }

    def deploy(appName, Map parameters) {

    }
}
