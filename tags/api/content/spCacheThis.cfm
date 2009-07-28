<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- Cache a chunk of HTML output in the application scope --->

<cfparam name="attributes.cacheExpires" default="">
<cfparam name="request.speck.persistentOutputCache" default="true" type="boolean">
<cfparam name="attributes.persistent" default="#request.speck.persistentOutputCache#" type="boolean">
<cfparam name="request.speck.session.showCacheInfo" default="false" type="boolean">
<cfparam name="request.speck.enableOutputCaching" default="true" type="boolean">

<cfif request.speck.enableOutputCaching> <!--- do nothing if output caching disabled --->
	
	<cfif thisTag.executionMode eq "start">
		
		<cfset thisTag.bSave = false>
		
		<!--- 
		Do some minor cleaning up of the provided cache name. Cache names are often generated 
		based on input from the client request (querystring parameters etc.), we'll just allow 
		for slightly mangled user input here (spContentGet does some similar cleaning up).
		Note: this code also replaces dots with underscores, allowing application keywords 
		to be passed as part or all of a cache name without having to do any pre-processing.
		--->
		<cfset attributes.cacheName = reReplace(attributes.cacheName,"[[:space:]]+","","all")>
		<cfset attributes.cacheName = reReplace(attributes.cacheName,"[^A-Za-z0-9_]+$","","all")>
		<cfset attributes.cacheName = replace(attributes.cacheName,".","_","all")>
		
		<cfif len(attributes.cacheName) gt 250>
		
			<!--- cacheName gt max allowed length --->
			<cf_spError error="ATTR_INV" lParams="#attributes.cacheName#,cacheName"> <!--- Invalid attribute --->
		
		</cfif>
		
		<cflock scope="APPLICATION" type="READONLY" timeout=3>
		<cfset bCacheExists = isDefined("application.speck.cache." & attributes.cacheName)>
	
		<cfif bCacheExists>
		
			<cfset content = application.speck.cache[attributes.cacheName].content>
			<cfset created = application.speck.cache[attributes.cacheName].created>
			<cfset expires = application.speck.cache[attributes.cacheName].expires>
	
		</cfif>
		
		</cflock>
		
		<cfif not bCacheExists>
			
			<cfif attributes.persistent>
				
				<!--- cacheName not found in memory cache, check database cache --->
				<cfquery name="qCache" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
					SELECT * FROM spCache 
					WHERE cacheName = '#uCase(attributes.cachename)#'
				</cfquery>
				
				<cfif qCache.recordCount>
			
					<!--- cache exists in database, copy to local and application scope --->
					<cfset content = qCache.content>
					<cfset created = qCache.created>
					<cfset expires = qCache.expires>
				
					<cflock scope="APPLICATION" type="EXCLUSIVE" timeout=3 throwontimeout="Yes">
					<cfset application.speck.cache[attributes.cacheName] = structNew()>
					<cfset application.speck.cache[attributes.cacheName].content = content>
					<cfset application.speck.cache[attributes.cacheName].created = created>
					<cfset application.speck.cache[attributes.cacheName].expires = expires>
					</cflock>
					
					<cfset bCacheExists = true>
			
				</cfif>
			
			</cfif>
		
		</cfif>

		<cfif request.speck.session.showCacheInfo>
	
			<cfscript>
				if ( not isDefined("expires") ) {
					if (isNumeric(attributes.cacheExpires)) {
						// Numeric, set expiry at now + cacheExpires minutes
						expires = dateAdd("n", attributes.cacheExpires, now());
					} else if (isDate(attributes.cacheExpires)) {
						// Date, expire at this date
						expires = parseDateTime(attributes.cacheExpires);
					} else {
						expires = "never";
					}
				} else if ( not len(expires) ) {
					expires = "never";
				}
				cacheNameCaption = request.speck.buildString("A_CACHE_INFO_NAME_CAPTION");
				if ( find("A_CACHE_INFO_NAME_CAPTION",cacheNameCaption) )
					cacheNameCaption = "cache name:"; // default value
				cacheExpiresCaption = request.speck.buildString("A_CACHE_INFO_EXPIRES_CAPTION");
				if ( find("A_CACHE_INFO_EXPIRES_CAPTION",cacheExpiresCaption) )
					cacheExpiresCaption = "expires:"; // default value
			</cfscript>
			
			<cfoutput>
			<style type="text/css">@import "#request.speck.contentStylesheet#";</style>
			<span style="display:block;" class="spCacheInfo">
			<span style="display:block;" class="spCacheInfoHeading">#cacheNameCaption#'#attributes.cacheName#', #cacheExpiresCaption##expires#</span>
			</cfoutput>
	
		<cfelseif bCacheExists>
		
			<!--- check if cache is due to expire or url.resetCache is defined and user has permission to reset the cache --->
			<cfif ( isDate(expires) and expires lt now() )
				or ( ( isdefined("url.resetCache") and ( not isDefined("url.cacheList") or not len(url.cacheList) or listFindNoCase(url.cacheList,attributes.cacheName) ) ) 
					and request.speck.userHasPermission("spLive,spSuper") )>
				
				<!--- clear existing cache contents and save new --->
				
				<!--- dump cache from memory --->
				<cflock scope="APPLICATION" type="EXCLUSIVE" timeout=3>
				<cfset void = structDelete(application.speck.cache, attributes.cachename)>
				</cflock>
				
				<!--- dump cache from database --->
				<cfquery name="qDeleteCache" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
					DELETE FROM spCache 
					WHERE cacheName = '#uCase(attributes.cachename)#'
				</cfquery>
				
				<!--- remove this cache from wasCached query --->
				<cfquery name="qDeleteWasCached" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
					DELETE FROM spWasCached 
					WHERE cacheName = '#uCase(attributes.cachename)#'
				</cfquery>
				
				<cfset thisTag.bSave = true>
	
			<!--- only output the content from the cache if viewing the live site and admin links are off --->
			<cfelseif request.speck.session.viewLevel eq "live"
				and request.speck.session.showAdminLinks neq "true"
				and request.speck.session.viewDate eq "">
		
				<!--- Otherwise, since it already exists, display contents and exit --->
				<cfoutput>#content#</cfoutput>
				<cfexit method="EXITTAG">
				
			</cfif>
		
		<cfelse>
		
			<!--- Cache not created, tell closing tag to save content --->
			<cfset thisTag.bSave = true>
		
		</cfif>
		
	<cfelse> 
	
		<!--- do end tag --->
		
		<cfif request.speck.session.showCacheInfo>
		
			<cfoutput></span></cfoutput>	
		
		<!--- only save content in cache if viewlevel is live and admin links are off --->
		<cfelseif thisTag.bSave 
			and request.speck.session.viewLevel eq "live"
			and request.speck.session.showAdminLinks neq "true"
			and request.speck.session.viewDate eq "">
			
			<cfscript>
			
				if (isNumeric(attributes.cacheExpires)) {
					// Numeric, set expiry at now + cacheExpires minutes
					expires = dateAdd("n", attributes.cacheExpires, now());
				} else if (isDate(attributes.cacheExpires)) {
					// Date, expire at this date
					expires = parseDateTime(attributes.cacheExpires);
				} else {
					expires = "";
				}
				
			</cfscript>
			
			<cfset created = now()>
			<cfset content = trim(thisTag.generatedContent)>
			<cfset contentLength = len(content)>
		
			<!--- save cache to memory --->
	 		<cflock scope="APPLICATION" type="EXCLUSIVE" timeout=3 throwontimeout="Yes">
			<cfset application.speck.cache[attributes.cacheName] = structNew()>
			<cfset application.speck.cache[attributes.cacheName].content = content>
			<cfset application.speck.cache[attributes.cacheName].created = created>
			<cfset application.speck.cache[attributes.cacheName].expires = expires>
			</cflock>
			
			<!--- Save cache to database? --->
			<cfif attributes.persistent>
				
				<!--- Hard-coded max length for cache content in database. A bit of a hack really, but it avoids any problems with long text retrieval. --->
				<cfif contentLength gt 64000>
				
					<!--- auto-delete from spCache table - this cached content is only to be stored in memory --->
					<cfquery name="qDeleteCache" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
						DELETE FROM spCache 
						WHERE cacheName = '#uCase(attributes.cachename)#'				
					</cfquery>
				
				<cfelse>
					
					<!--- check if cache exists, so we know whether to update or insert --->
					<cfquery name="qCacheExists" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
						SELECT cacheName FROM spCache 
						WHERE cacheName = '#uCase(attributes.cachename)#'
					</cfquery>
					
					<cfif qCacheExists.recordCount>
					
						<cftry>
	
							<cfquery name="qUpdateCache" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
								UPDATE spCache
								SET created = #createODBCDateTime(created)# ,
									expires = <cfif isDate(expires)>#createODBCDateTime(expires)#<cfelse>NULL</cfif> ,
									content = <cfqueryparam null=#evaluate('content eq ""')# value="#content#" cfsqltype="#request.speck.database.longVarcharCFSQLType#" maxlength="64000">, 
									contentLength = #contentLength#
								WHERE cacheName = '#uCase(attributes.cachename)#'
							</cfquery>
							
						<cfcatch>
							
							<!--- if the update fails, delete the row so the db cache doesn't get out of sync with memory cache --->
							<cfquery name="qDeleteCache" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
								DELETE FROM spCache 
								WHERE cacheName = '#uCase(attributes.cachename)#'				
							</cfquery>
							
						</cfcatch>
						</cftry>
						
					<cfelse>
					
						<cftry>
					
							<cfquery name="qInsertCache" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
								INSERT INTO spCache (cacheName, content, contentLength, created, expires)
								VALUES (
									'#uCase(left(attributes.cacheName,250))#',
									<cfqueryparam null=#evaluate('content eq ""')# value="#content#" cfsqltype="#request.speck.database.longVarcharCFSQLType#" maxlength="64000">, 
									#contentLength#, 
									#createODBCDateTime(created)#, 
									<cfif isDate(expires)>#createODBCDateTime(expires)#<cfelse>NULL</cfif>
								)
							</cfquery>
							
						<cfcatch><!--- Do nothing. Another thread may have already inserted the cache since we checked if it existed. ---></cfcatch>
						</cftry>								
					
					</cfif> <!--- qCache.recordCount --->
	
				</cfif> <!--- len(content) gt 64000 --->
				
			</cfif> <!--- attributes.persistent --->
	
		</cfif>
		
	</cfif>

</cfif>