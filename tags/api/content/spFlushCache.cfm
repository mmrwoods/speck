<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- 
flush items from cache based on criteria used by contentGet to return content (type, id, label, keywords) 
* if given a cachename, just remove that cache
* else if startsWith attribute used, look for caches where the leftmost part of the cachename matches the startsWith attribute value
* else look for matching caches using the type, id, label and keywords attributes
--->

<cfparam name="attributes.cacheName" default="">

<cfparam name="attributes.startsWith" default=""> <!--- call me a hack, I don't care, nah, nah, nah, nah, nah!! So there, back to you with knobs on boss! --->

<cfparam name="attributes.type" default="">
<cfparam name="attributes.id" default="">
<cfparam name="attributes.label" default="">
<cfparam name="attributes.keywords" default="">

<cfscript>
	keywordsWhere = "";
	if ( len(attributes.keywords) ) {
		sqlIdentifier = "keywords";
		for ( i=1; i le listLen(attributes.keywords); i = i+1 ) 
			keywordsWhere = keywordsWhere & " OR " & request.speck.dbConcat("','",sqlIdentifier,"','") & " LIKE '%," & uCase(replace(trim(listGetAt(attributes.keywords,i)),"'","''","all")) & ",%'";
	}				
	
	idWhere = "";
	if ( len(attributes.id) ) {
		sqlIdentifier = "id";
		for ( i=1; i le listLen(attributes.id); i = i+1 ) {	
			idWhere = idWhere & " OR " & request.speck.dbConcat("','",sqlIdentifier,"','") & " LIKE '%," & uCase(trim(listGetAt(attributes.id,i))) & ",%'";			
		}
	}
</cfscript>

<cfquery name="qCachesToDelete" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
	SELECT DISTINCT cacheName <!--- DISTINCT necessary because we record a row for each contentGet call, not each cacheThis (makes flushing easier) --->
	FROM spWasCached
	WHERE 
		<cfif len(attributes.cacheName)>
			cacheName = '#uCase(left(attributes.cacheName,250))#'
		<cfelseif len(attributes.startsWith)>
			cacheName LIKE '#uCase(attributes.startsWith)#%'
		<cfelse>
			contentType = '#uCase(attributes.type)#'
			<cfif len(attributes.keywords) or len(attributes.id) or len(attributes.label)>
				AND ( 1 = 0
					<cfif len(attributes.label)>
						OR label = '#uCase(attributes.label)#'
					</cfif>
					#preserveSingleQuotes(idWhere)#
					#preserveSingleQuotes(keywordsWhere)#
				)
			</cfif>
		</cfif>
</cfquery>

<cfif qCachesToDelete.recordCount>

	<cflock scope="application" type="exclusive" timeout=3>

	<cfloop query="qCachesToDelete">
	
		<cftry>
		
			<cfset void = structDelete(application.speck.cache, cacheName)> 
			
		<cfcatch><!--- do nothing ---></cfcatch>
		
		</cftry>
		
	</cfloop>	
	
	</cflock>
	
	<cfquery name="qDeleteCache" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		DELETE FROM spCache 
		WHERE cacheName IN ( #uCase(quotedValueList(qCachesToDelete.cacheName))# )
	</cfquery>
	
	<cfquery name="qDeleteWasCached" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		DELETE FROM spWasCached 
		WHERE cacheName IN ( #uCase(quotedValueList(qCachesToDelete.cacheName))# )
	</cfquery>

</cfif>
