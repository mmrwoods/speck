<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!---
Return a query containing all application keywords
TODO: Allow for multiple keywords sources (tricky one that, 'cos it'll have to deal with queries that can't simply be unioned)
--->

<!--- Validate attributes --->
<cfif not isdefined("attributes.r_qKeywords")>

	<cf_spError error="ATTR_REQ" lParams="r_qKeywords">	<!--- Missing attribute --->
	
</cfif>

<cfif not isDefined("attributes.context")>

	<cfif isDefined("request.speck")>
	
		<cfset attributes.context = request.speck>
	
	<cfelse>
	
		<cfexit method="EXITTAG">
	
	</cfif>

</cfif>

<cfparam name="attributes.source" default="spKeywords">

<cfset fs = attributes.context.fs>

<cfif attributes.source neq "spKeywords">

	<cf_spGetProfileStructure file="#attributes.context.speckInstallRoot##fs#config#fs#keywords#fs##attributes.source#.cfg" variable="stProfile">

	<cfif stProfile.options.source eq "file">
		
		<cfscript>
			stKeywords = duplicate(stProfile.file);
			qKeywords = queryNew("keyword,roles");
			for ( key in stKeywords ) {
				queryAddRow(qKeywords,1);
				querySetCell(qKeywords, "keyword", key);
				querySetCell(qKeywords, "roles", stKeywords[key]);
			}
		</cfscript>
	
	<cfelseif stProfile.options.source eq "database">
	
		<cfparam name="stProfile.database.datasource" default="#attributes.context.codb#">
		<cfparam name="stProfile.database.username" default="#attributes.context.database.username#">
		<cfparam name="stProfile.database.password" default="#attributes.context.database.password#">
		<cfparam name="stProfile.database.dbtype" default="">
		<cfparam name="stProfile.database.query" default="SELECT keyword, keyId, name, title, description, keywords, roles, groups FROM spKeywords ORDER BY sortId, keyword">
		
		<cfif stProfile.database.dbtype eq "query">
		
			<!--- check if we need to use a scoped lock when executing the query --->
			<cfset stQueryScope = REFindNoCase("FROM[[:space:]]+((Server|Application|Session)\.)",stProfile.database.query,1,true)>
			
			<cfif arrayLen(stQueryScope.pos) eq 3>
			
				<cfset lockScope = mid(stProfile.database.query,stQueryScope.pos[3],stQueryScope.len[3])>
			
				<cflock type="readonly" scope="#lockScope#" timeout="3">
				<cfquery name="qKeywords" dbtype="query">
				
					#preserveSingleQuotes(stProfile.database.query)#
				
				</cfquery>
				</cflock>
				
			<cfelse>
			
				<cfquery name="qKeywords" dbtype="query">
				
					#preserveSingleQuotes(stProfile.database.query)#
				
				</cfquery>
			
			</cfif>
		
		<cfelse>
		
			<cfquery name="qKeywords" datasource=#stProfile.database.datasource# username=#stProfile.database.username# password=#stProfile.database.password#>
			
				#preserveSingleQuotes(stProfile.database.query)#
			
			</cfquery>
		
		</cfif>
	
	</cfif>
	
<cfelseif attributes.source eq "spKeywords">

	<!--- keywords type has revisioning off, so we can do a simple query to get the keywords --->

	<cfquery name="qKeywords" datasource=#attributes.context.codb# username=#attributes.context.database.username# password=#attributes.context.database.password#>
	
		SELECT * FROM spKeywords ORDER BY sortId, keyword
	
	</cfquery>
					
</cfif>

<cfif isDefined("qKeywords")>

	<cfset "caller.#attributes.r_qKeywords#" = qKeywords>

</cfif>
