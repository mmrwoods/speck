<cfsetting enablecfoutputonly="yes">

<cfquery name="qSubscribers" datasource="#request.speck.codb#">
	SELECT fullname, email, keyword AS newsletter
	FROM newslettersubscribers x, spusers y 
	WHERE x.confirmedAt IS NOT NULL 
		AND x.id = y.spId
		AND y.suspended IS NULL
</cfquery>

<cfscript>
/**
 * Transform a query result into a csv formatted variable.
 * 
 * @param query 	 The query to transform. (Required)
 * @param headers 	 A list of headers to use for the first row of the CSV string. Defaults to cols. (Optional)
 * @param cols 	 The columns from the query to transform. Defaults to all the columns. (Optional)
 * @return Returns a string. 
 * @author adgnot sebastien (sadgnot@ogilvy.net) 
 * @version 1, June 26, 2002 
 */
 
// hacked to use comma as separator and replace new lines with spaces within fields
function QueryToCsv(query){
	var csv = "";
	var cols = "";
	var headers = "";
	var i = 1;
	var j = 1;
	
	if(arrayLen(arguments) gte 2) headers = arguments[2];
	if(arrayLen(arguments) gte 3) cols = arguments[3];
	
	if(cols is "") cols = query.columnList;
	if(headers IS "") headers = cols;
	
	headers = listToArray(headers);
	
	for(i=1; i lte arrayLen(headers); i=i+1){
		csv = csv & """" & headers[i] & """,";
	}

	csv = csv & chr(13) & chr(10);
	
	cols = listToArray(cols);
	
	for(i=1; i lte query.recordCount; i=i+1){
		for(j=1; j lte arrayLen(cols); j=j+1){
			//csv = csv & """" & query[cols[j]][i] & """,";
			csv = csv & """" & reReplace(query[cols[j]][i],"(#chr(10)#|#chr(13)#){1,}"," ","all") & """,";
		}		
		csv = csv & chr(13) & chr(10);
	}
	return csv;
}
</cfscript>

<cfheader name="content-disposition" value="attachment; filename=subscribers_export.csv">
<cfcontent type="text/comma-separated-values; charset=UTF-8">

<cfset lColumns = "fullname,email,newsletter">
<cfset lHeaders = "Full Name,Email,Newsletter">

<cfoutput>#queryToCsv(qSubscribers,lHeaders,lColumns)#</cfoutput>