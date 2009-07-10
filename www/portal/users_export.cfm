<cfsetting enablecfoutputonly="yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- TODO: append csv lines to tmp file directly rather than to a string buffer --->

<cfparam name="url.search" default="">
<cfparam name="url.field" default="username">
<cfparam name="url.match" default="start">
<cfparam name="url.orderby" default="username">
<cfparam name="url.group" default="">

<!--- get groups to allow search by group membership --->
<cfquery name="qGroups" datasource="#request.speck.codb#">
	SELECT * 
	FROM spGroups
</cfquery>

<cfquery name="qUsers" datasource="#request.speck.codb#">
	SELECT *, '' AS groups
	FROM spUsers
	WHERE 1 = 1
	<cfif len(trim(url.search))>
		AND UPPER(#url.field#)
		<cfswitch expression="#url.match#">
			<cfcase value="start">LIKE '#trim(uCase(url.search))#%'</cfcase>
			<cfcase value="anywhere">LIKE '%#trim(uCase(url.search))#%'</cfcase>
			<cfcase value="exact">= '#trim(uCase(url.search))#'</cfcase>
			<cfcase value="end">LIKE '%#trim(uCase(url.search))#'</cfcase>
		</cfswitch>
	</cfif>
	<cfif len(trim(url.group))>
	    AND username IN ( SELECT DISTINCT username FROM spUsersGroups WHERE groupname = '#trim(url.group)#' )
	</cfif>
	ORDER BY UPPER(#url.orderby#)
</cfquery>


<cfloop query="qUsers">

	<!--- ok, this is slow, but there's only ever 20 of these queries per page --->
	<cfquery name="qGroups" datasource="#request.speck.codb#">
		SELECT groupname 
		FROM spUsersGroups 
		WHERE username = '#username#' 
			AND ( expires IS NULL OR expires > CURRENT_TIMESTAMP )
	</cfquery>
	
	<cfset qUsers.groups[currentRow] = valueList(qGroups.groupname)>
	
</cfloop>

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

<cfset lColumns = "username,fullname,email,groups,phone">
<cfset lHeaders = "Username,Full Name,Email,Groups,Phone">

<cfset lSystemProperties = "username,fullname,password,email,phone,notes,suspended">
<cfset stType = request.speck.types.spUsers>
<cfloop from="1" to="#arrayLen(stType.props)#" index="i">

	<cfif not listFindNoCase(lSystemProperties,stType.props[i].name)>
	
		<cfset lColumns = listAppend(lColumns,stType.props[i].name)>
		<cfset lHeaders = listAppend(lHeaders,stType.props[i].caption)>

	</cfif>

</cfloop>

<cfif isDefined("request.speck.portal.trackUserActivity") and request.speck.portal.trackUserActivity>
	
	<cfset lColumns = lColumns & ",lastactive">
	<cfset lHeaders = lHeaders & ",Last Active">

</cfif>

<cfset lColumns = lColumns & ",lastlogon,registered,suspended,notes">
<cfset lHeaders = lHeaders & ",Last Logon,Registered,Suspended,Notes">

<cfset tmpFile = request.speck.appInstallRoot & "/tmp/users_export_" & dateFormat(now(),"YYYYMMDD") & timeFormat(now(),"HHmmss") & ".csv">

<cffile action="write" file="#tmpFile#" mode="664" output="#queryToCsv2(qUsers,lHeaders,lColumns)#" charset="utf-8">

<cfcontent type="text/comma-separated-values; charset=UTF-8" file="#tmpFile#" deletefile="true">