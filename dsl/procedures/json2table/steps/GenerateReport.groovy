import groovy.xml.MarkupBuilder
import groovy.json.*

def TableData = new JsonSlurper().parseText '''
$[jsonData]
'''

def ColumnOrnamentation = new JsonSlurper().parseText '''
$[columnOrnamentation]
'''

//assert TableData.getClass() == "java.util.ArrayList"

// Identify all the Column names in the JSON object
ColumnHeaders = []
TableData.each { row ->
	//assert row.getClass() == "groovy.json.internal.LazyMap"
	row.each { key, value ->
		if (!(key in ColumnHeaders)) ColumnHeaders.push(key)
	}
}
ColumnHeaders

def sb = new StringWriter()
def html = new MarkupBuilder(sb)

html.doubleQuotes = true
html.expandEmptyElements = true
html.omitEmptyAttributes = false
html.omitNullAttributes = false
html.html {
    head {
        title ('Sample Table')
        script (src: 'https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js', type: 'text/javascript', integrity:'sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa', crossorigin:'anonymous')
		link (rel:'stylesheet', href:'https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css', integrity: 'sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u', crossorigin:'anonymous')
		link (rel:'stylesheet', href:'https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css', integrity: 'sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp', crossorigin:'anonymous')
    }
    body {
        mkp.yieldUnescaped('<!--')
        mkp.yield('<test>')
        mkp.yieldUnescaped('-->')

        div (class:'container-fluid'){
			div (class:'row'){
				div (class:'col-md-12'){
					table (class:'table table-hover table-striped') {
						thead () {
							tr () {
								ColumnHeaders.each { ColumnHeader -> 
									th (ColumnHeader)
								}
							}
						}
						tbody () {
							TableData.each { row ->
								tr (class: 'active', style:'box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19)') {	
									ColumnHeaders.each { column ->
										// TODO: add column ornamentation
										td(row[column])
									}
								}
						    }
						}
					}
				}
			}	
		}
    }
}

println sb.toString()