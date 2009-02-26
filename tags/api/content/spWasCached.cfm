<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- 
add items to application.speck.wasCached and spWasCached table to keep track of attributes passed to 
contentGet calls within cf_spCacheThis tags. The spFlushCache tag can then be used to flush caches as
required when content items are added, deleted or updated.

Possible TODO: get rid of this tag entirely and just move the code to spContentGet or spCacheThis 
(moving to spCacheThis is tricky tho, would need to look for cf_spContentGet calls within the opening 
and closing cf_spCacheThis tags)
--->

<cfparam name="attributes.type" default="">
<cfparam name="attributes.id" default="">
<cfparam name="attributes.label" default="">
<cfparam name="attributes.keywords" default="">
<cfparam name="attributes.cacheName" default="">
<cfparam name="request.speck.enableOutputCaching" default="true" type="boolean">

<cfif isDefined("attributes.action") and attributes.action eq "flush">

	<!--- maintain backwards compatibility with previous interface --->
	<cfmodule template="/speck/api/content/spFlushCache.cfm" attributeCollection="#attributes#">

<cfelseif request.speck.enableOutputCaching>
	
	<cfset varcharMaxLength = request.speck.database.varcharMaxLength>
	<cfset maxIndexKeyLength = request.speck.database.maxIndexKeyLength>	

	<!--- add a row for each instance of cf_spCacheThis in the ancestor tag list --->
	<cfloop from="1" to="#listValueCount(getBaseTagList(),'CF_SPCACHETHIS')#" index="cacheInstance">

		<cfscript>
			baseTagData = getBaseTagData("cf_spCacheThis",cacheInstance);
			cacheName = baseTagData.attributes.cacheName;
		</cfscript>
					
		<cfquery name="qCheckExists" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			SELECT COUNT(*) AS matches
			FROM spWasCached
			WHERE 
				cacheName = <cfqueryparam value="#uCase(left(cacheName,250))#" cfsqltype="CF_SQL_VARCHAR"> <!--- hmm, is it a dangerous assumption to make that varcharMaxLength will always be more than 250? --->
				AND contentType = <cfqueryparam value="#uCase(attributes.type)#" cfsqltype="CF_SQL_VARCHAR">
				AND label <cfif len(attributes.label)>= <cfqueryparam value="#uCase(attributes.label)#" cfsqltype="CF_SQL_VARCHAR"><cfelse>IS NULL</cfif>
				<cfif isNumeric(varcharMaxLength) and varcharMaxLength le maxIndexKeyLength>
					AND id <cfif len(attributes.id)>= <cfqueryparam value="#uCase(left(attributes.id,maxIndexKeyLength))#" cfsqltype="#request.speck.database.longVarcharCFSQLType#"><cfelse>IS NULL</cfif>
					AND keywords <cfif len(attributes.keywords)>= <cfqueryparam value="#uCase(left(attributes.keywords,maxIndexKeyLength))#" cfsqltype="#request.speck.database.longVarcharCFSQLType#"><cfelse>IS NULL</cfif>
				<cfelse>
					AND id <cfif len(attributes.id)>= <cfqueryparam value="#uCase(left(attributes.id,maxIndexKeyLength))#" cfsqltype="CF_SQL_VARCHAR"><cfelse>IS NULL</cfif>
					AND keywords <cfif len(attributes.keywords)>= <cfqueryparam value="#uCase(left(attributes.keywords,maxIndexKeyLength))#" cfsqltype="CF_SQL_VARCHAR"><cfelse>IS NULL</cfif>
				</cfif>	
		</cfquery>	
		
		<cfif qCheckExists.matches eq 0>
		
			<!--- <cftry> ---> <!--- try/catch added to allow Speck to run using a read-only database, eg. on a backup server with a replicated version of a live db --->
		
				<cfquery name="qInsertWasCached" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
					INSERT INTO spWasCached (
						contentType, 
						id, 
						label, 
						keywords, 
						cacheName, 
						scriptName, 
						pathInfo, 
						queryString, 
						ts
					) VALUES (
						'#uCase(attributes.type)#', 
						<cfif len(attributes.id)>'#uCase(left(attributes.id,maxIndexKeyLength))#'<cfelse>NULL</cfif>, 
						<cfif len(attributes.label)>'#uCase(attributes.label)#'<cfelse>NULL</cfif>, 
						<cfif len(attributes.keywords)>'#uCase(left(attributes.keywords,maxIndexKeyLength))#'<cfelse>NULL</cfif>, 
						'#uCase(left(cacheName,250))#', 
						'#left(cgi.script_name,250)#', 
						'#left(replace(cgi.path_info,cgi.script_name,""),250)#', 
						'#left(cgi.query_string,250)#', 
						#createODBCDateTime(now())#
					)
				</cfquery>
				
			<!--- <cfcatch>
				<!--- do nothing, should add a call to spError here if we continue to use the spWasCached 
					table long term (it was only intended as a temp fix, though is working nicely) --->
			</cfcatch>
			</cftry> --->		
		
		</cfif>
		
	</cfloop>

</cfif>