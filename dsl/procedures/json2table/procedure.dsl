import java.io.File

def procName = 'json2table'
procedure procName, {

	formalParamter "jsonData"
	formalParamter "reportName"
	formalParamter "columnOrnamentation"
	
	def ReportName = '$[reportName]'?'$[reportName]':'report'

	step 'Generate Report',
    	  command: new File(pluginDir, "dsl/procedures/$procName/steps/GenerateReport.groovy").text,
    	  shell: 'ec-groovy'
		  
	step 'Create Report Directory',
		subproject : '/plugins/EC-FileOps/project',
		subprocedure : 'CreateDirectory',
		actualParameter : [
			Path: 'artifacts'
		]
	
	step 'Save report to a file',
		subproject : '/plugins/EC-FileOps/project',
		subprocedure : 'AddTextToFile',
		actualParameter : [
			AddNewLine: '1',
			Append: '1',
			Content: '$[/myJob/reportHtml]',
			Path: 'artifacts/' + ReportName + '.html'
		] 
  
    step 'Create Job Link',
        command: """
			ectool \"/myJob/report-urls/Report\" \"/commander/jobSteps/\$[/myJobStep/jobStepId]/${ReportName}.html\"
		""".stripIndent()
		
	step 'Create Pipeline Link',
		command: """\
			ectool setProperty \"/myPipelineStageRuntime/ec_summary/Report\" \"<html><a href=\\\"../commander/jobSteps/\$[/myJobStep/jobStepId]/${ReportName}..html\\\" target=\\\"_blank\\\">Link</a></html>\"
			""".stripIndent(),
		condition: '$[/javascript getProperty("/myPipelineStageRuntime")']

}

