<cfsetting enablecfoutputonly="yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

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

<cfheader name="content-disposition" value="attachment; filename=users_export.csv">
<cfcontent type="text/comma-separated-values">

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


<cfoutput>#queryToCsv(qUsers,lHeaders,lColumns)#</cfoutput>