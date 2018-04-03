## EC-ReportingTools
Tools to help create reports from Electric Flow data

# json2table
Create a table from a JSON string:
[
	{
		"col1": "123",
		"col2": "456",
	},
	{
		"col1": "789",
		"col2": "012",
		"col3": "345"
	}
[

col1	col2	col3
123		456
789		012		345

## Parameters
jsonData: required, string, JSON array with one or more key-value pairs for each array element
reportName: optional, string, report name to be used as file name as well
columnOrnamentation: optional, string JSON key-value pairs of column names and desired HTML formatting
{
	"col1": "class: 'active', style:'box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19)'",
	"col3": "a href: 'http://mycompany.com/link/' + $cellValue"
}



