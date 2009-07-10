<cfsetting enablecfoutputonly="yes" showdebugoutput="no">

<cfquery name="qSubscribers" datasource="#request.speck.codb#">
	SELECT fullname, email
	FROM spNewsletterSubscribers
</cfquery>

<cfscript>
/**
* Convert the query into a CSV format using Java StringBuffer Class.
*
* @param query      The query to convert. (Required)
* @param headers      A list of headers to use for the first row of the CSV string. Defaults to all the columns. (Optional)
* @param cols      The columns from the query to transform. Defaults to all the columns. (Optional)
* @return Returns a string.
* @author Qasim Rasheed (qasimrasheed@hotmail.com)
* @version 1, March 23, 2005
*/
/* modified by Mark Woods - replace new lines with spaces within fields */
function QueryToCSV2(query){
    var csv = createobject( 'java', 'java.lang.StringBuffer');
    var i = 1;
    var j = 1;
    var cols = "";
    var headers = "";
    var endOfLine = chr(13) & chr(10);
    if (arraylen(arguments) gte 2) headers = arguments[2];
    if (arraylen(arguments) gte 3) cols = arguments[3];
    if (not len( trim( cols ) ) ) cols = query.columnlist;
    if (not len( trim( headers ) ) ) headers = cols;
    headers = listtoarray( headers );
    cols = listtoarray( cols );
    
    for (i = 1; i lte arraylen( headers ); i = i + 1)
        csv.append( '"' & headers[i] & '",' );
    csv.append( endOfLine );
    
    for (i = 1; i lte query.recordcount; i= i + 1){
        for (j = 1; j lte arraylen( cols ); j=j + 1){
            if (isNumeric( query[cols[j]][i] ) )
                csv.append( query[cols[j]][i] & ',' );
            else
                csv.append( '"' & reReplace(query[cols[j]][i],"(#chr(10)#|#chr(13)#){1,}"," ","all") & '",' );
            
        }
        csv.append( endOfLine );
    }
    return csv.toString();
}
</cfscript>

<cfset lColumns = "fullname,email">
<cfset lHeaders = "Full Name,Email">

<cfset tmpFile = request.speck.appInstallRoot & "/tmp/newsletter_export_" & dateFormat(now(),"YYYYMMDD") & timeFormat(now(),"HHmmss") & ".csv">

<cffile action="write" file="#tmpFile#" mode="664" output="#queryToCsv2(qSubscribers,lHeaders,lColumns)#" charset="utf-8">

<cfcontent type="text/comma-separated-values; charset=UTF-8" file="#tmpFile#" deletefile="true">