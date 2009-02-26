<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfparam name="attributes.name">
<cfparam name="attributes.refresh" default="false" type="boolean">

<cfif not reFind("^[A-Za-z]([A-Za-z0-9_]+)?$",attributes.name)>

	<cfoutput><h1>cf_spApp error: Required parameter "name" must be a valid variable name</h1></cfoutput>
	<cfabort>

</cfif>

<cfset doAppSetup = attributes.refresh>
<cfset doServerSetup = attributes.refresh>

<cflock scope="SERVER" timeout="3" type="READONLY">
<cfscript>

	if ( not isDefined("server.speck.speckInstallRoot") or not structKeyExists(server.speck.apps,attributes.name) )
		doServerSetup = true;

</cfscript>
</cflock>

<cfif doServerSetup>

	<!--- stop multiple threads attempting to do server setup at once (note: hard-coded 90 second timeout) --->
	<cflock scope="SERVER" type="READONLY" timeout="3">
	<cfset cfVersion = server.coldFusion.productVersion>
	<cfif isDefined("server.speck.starting") and dateDiff("s",server.speck.starting,now()) lt 90>
		
		<cfheader statuscode="503" statustext="Service Unavailable">
		<cfheader name="Retry-After" value="90">
		<cfabort>
	
	</cfif>
	</cflock>
	
	<cflock scope="SERVER" type="EXCLUSIVE" timeout="3">
	<cfif not isDefined("server.speck")>
		<cfset server.speck = structNew()>
	</cfif>
	<cfset server.speck.starting = now()>
	</cflock>

	<cftry>

		<!--- Derive speckInstallRoot from current template path --->
		<cfscript>
		
			speckInstallRoot = getCurrentTemplatePath();
			
			if (find("/", speckInstallRoot) neq 0)
				fs = "/";
			else
				fs = "\";
			
			speckOffset = findNoCase(fs & "speck" & fs, speckInstallRoot);
			speckInstallRoot = left(speckInstallRoot, speckOffset + 5);				

			stServer = structNew();
			stServer.apps = structNew();
			stServer.speckInstallRoot = speckInstallRoot;
			stServer.fs = fs;
			stServer.locale = getLocale();
		</cfscript>
		
		<!--- Load functions into server scope --->
		<cfinclude template="/speck/api/application/spFunctions.cfm">
		
		<!--- Load default strings into server scope --->
		<cf_spGetProfileStructure file="#speckInstallRoot##fs#config#fs#system#fs#strings.cfg" variable="stProfile">
		<cfset stServer.strings = duplicate(stProfile.strings)>
		
		<!--- Load MIME map --->
		<cf_spGetProfileStructure file="#speckInstallRoot##fs#config#fs#system#fs#mimemap.cfg" variable="stProfile">
		<cfset stServer.mimemap = duplicate(stProfile.mimemap)>
		
		<!--- Load databases config --->
		<cf_spGetProfileStructure file="#speckInstallRoot##fs#config#fs#system#fs#databases.cfg" variable="stProfile">
		<cfset stServer.databases = duplicate(stProfile)>
		
		<!--- Load applications --->
		<cfset appsDir = "#speckInstallRoot##fs#config#fs#apps">
		<cfdirectory action="LIST" directory="#appsDir#" filter="*.app" name="qApps">	

		<cfloop query="qApps">
		
			<cf_spGetProfileStructure file="#appsDir##fs##qApps.name#" variable="stProfile" context=#stServer#>

			<!--- if appName not set in configuration file, assume it's to be the same as the filename --->
			<cfif not structKeyExists(stProfile.settings,"appName")>
				
				<cfset stProfile.settings.appName = REReplaceNoCase(qApps.name,"\.app$","")>
				
			</cfif>
		
			<cfif structKeyExists(stServer.apps,stProfile.settings.appName)>
				
				<cf_spError error="APP_DUPLICATE_NAME" lParams="#stProfile.settings.appName#,#appsDir##fs##qApps.name#" context=#stServer#>
			
			</cfif>

			<cfset stServer.apps[stProfile.settings.appName] = duplicate(stProfile.settings)>
		
		</cfloop>

		<!--- Write to the server.speck structure --->
		<cflock scope="SERVER" timeout="3" type="EXCLUSIVE">	
		<cfset server.speck = structNew()>
		<cfset server.speck = duplicate(stServer)>
		<cfset server.speck.cfVersion = server.coldFusion.productVersion>
		</cflock>

	<cfcatch>
		
		<!--- allow another thread do the server setup... --->
		<cflock scope="SERVER" type="EXCLUSIVE" timeout="3">
		<cfset void = structDelete(server.speck,"starting")>
		</cflock>
	
		<cfrethrow>
	
	</cfcatch>
	</cftry>
	
</cfif>

<!--- get basic application details from server scope and call cfapplication --->

<cflock scope="SERVER" type="READONLY" timeout="3">

<cfif not isDefined("server.speck.apps.#attributes.name#")>

	<!--- need context for spError --->
	<cfset stServer = duplicate(server.speck)>

	<cf_spError error="APP_NOT_EXIST" lParams="#attributes.name#" context=#stServer#>	<!--- No such application --->

</cfif>

<!--- grab the basic application settings from server scope --->
<cfset stApp = duplicate(server.speck.apps[attributes.name])>

</cflock>

<cfif compare(attributes.name,stApp.appName) neq 0>

	<!--- need context for spError --->
	<cfset stServer = duplicate(server.speck)>
	
	<!--- appName configuration setting and name attribute must be exact case-sensitive matches --->
	<cf_spError error="APP_NAME_MISMATCH" lParams="#attributes.name#,#stApp.appName#" context=#stServer#>

</cfif>

<!--- default application configuration setting values to pass to CFAPPLICATION --->
<cfparam name="stApp.clientManagement" default="No">
<cfparam name="stApp.clientStorage" default="">
<cfparam name="stApp.setClientCookies" default="Yes">
<cfparam name="stApp.sessionManagement" default="Yes">
<cfparam name="stApp.setDomainCookies" default="No">
<cfscript>
	// handle timespans from application configuration files
	if ( isDefined("stApp.sessionTimeout") ) {
		if ( isNumeric(stApp.sessionTimeout) ) {
			stApp.sessionTimeout = createTimeSpan(0, 0, stApp.sessionTimeout, 0);
		} else {
			stApp.sessionTimeout = evaluate(stApp.sessionTimeout);
		}	
	} else {
		stApp.sessionTimeout = createTimeSpan(0, 0, 30, 0);
	}
	if ( isDefined("stApp.applicationTimeout") ) {
		if ( isNumeric(stApp.applicationTimeout) ) {
			stApp.applicationTimeout = createTimeSpan(0, 0, stApp.applicationTimeout, 0);
		} else {
			stApp.applicationTimeout = evaluate(stApp.applicationTimeout);
		}	
	} else {
		stApp.applicationTimeout = createTimeSpan(1, 0, 0, 0);
	}
</cfscript>

<!--- call CFAPPLICATION --->
<!--- 
I'm sure this all used to be necessary in CF5
<cfset cfapplicationDomainCookies = ( stApp.setDomainCookies and stApp.setClientCookies )>

<cfif stApp.clientManagement>

	<cfapplication name = "#attributes.name#"
		clientManagement = "#stApp.clientManagement#"
		clientStorage = "#stApp.clientStorage#"
		setClientCookies = "#stApp.setClientCookies#" 
		sessionManagement = "#stApp.sessionManagement#"
		sessionTimeout = "#stApp.sessionTimeout#"
		applicationTimeout = "#stApp.applicationTimeout#"
		setDomainCookies = "#cfapplicationDomainCookies#">
	
<cfelse>

	<cfapplication name = "#attributes.name#"
		setClientCookies = "#stApp.setClientCookies#" 
		sessionManagement = "#stApp.sessionManagement#"
		sessionTimeout = "#stApp.sessionTimeout#"
		applicationTimeout = "#stApp.applicationTimeout#"
		setDomainCookies = "#cfapplicationDomainCookies#"> 

</cfif> --->

<cfapplication name = "#attributes.name#"
	clientManagement = "#stApp.clientManagement#"
	clientStorage = "#stApp.clientStorage#"
	setClientCookies = "#stApp.setClientCookies#" 
	sessionManagement = "#stApp.sessionManagement#"
	sessionTimeout = "#stApp.sessionTimeout#"
	applicationTimeout = "#stApp.applicationTimeout#"
	setDomainCookies = "#stApp.setDomainCookies#">

<!--- force per-session cfid and cftoken cookies if not set by cfapplication (regardless of whether j2ee session management is enabled) --->
<cfif not isDefined("cookie.cfid")>
	
	<cflock scope="SESSION" timeout="3" type="READONLY">
	<cfset variables.cfid = listGetAt(session.urltoken,2,"&=")>
	<cfset variables.cftoken = listGetAt(session.urltoken,4,"&=")>
	</cflock>

	<cfif stApp.setDomainCookies and listLen(cgi.http_host,".") gte 3>
	
		<cfset domain = "." & listRest(cgi.http_host,".")>
		
		<cfcookie name="cfid" value="#variables.cfid#" path="/" domain="#domain#">
		<cfcookie name="cftoken" value="#variables.cftoken#" path="/" domain="#domain#">
		
	<cfelse>
	
		<cfcookie name="cfid" value="#variables.cfid#">
		<cfcookie name="cftoken" value="#variables.cftoken#">
	
	</cfif>
	
</cfif>

<!--- Set up application scope --->

<cflock scope="APPLICATION" timeout="3" type="READONLY">
<cfscript>

	if ((not isDefined("application.speck.speckInstallRoot")))
		doAppSetup = true;

</cfscript>
</cflock>

<cfif doAppSetup>

	<!--- stop multiple threads attempting to do the app setup at once (note: hard-coded 90 second timeout) --->
	<cflock scope="APPLICATION" type="READONLY" timeout="3">
	<cfif isDefined("application.speck.starting") and dateDiff("s",application.speck.starting,now()) lt 90>
		
		<cfheader statuscode="503" statustext="Service Unavailable">
		<cfheader name="Retry-After" value="90">
		<cfabort>
	
	</cfif>
	</cflock>
	
	<!--- flag this application as restarting --->
	<cflock scope="APPLICATION" type="EXCLUSIVE" timeout="3">
	<cfif not isDefined("application.speck")>
		<cfset application.speck = structNew()>
	</cfif>
	<cfset application.speck.starting = now()>
	</cflock>

	<cflog type="information" 
		file="#stApp.appName#" 
		application="no"
		text="CF_SPAPP: Refreshing application">
	
	<cftry>
	
		<!--- 
		If an exception is caught during application setup, delete the starting key from 
		application.speck so another thread can try to refresh the application once the 
		problem causing the exception is solved (rather than have to wait 90 seconds)
		--->

		<cflock scope="SERVER" type="READONLY" timeout="3">
		<cfscript>
			
			// Copy across stuff we want to make available in application scope from server.speck
			for (key in server.speck)
				if (isCustomFunction(server.speck[key]) or listFindNoCase("mimemap,fs,speckInstallRoot,cfVersion", key))
					stApp[key] = duplicate(server.speck[key]);
					
			// copy across database info
			if ( isDefined("stApp.dbType") and structKeyExists(server.speck.databases, stApp.dbType) )
				stApp.database = duplicate(server.speck.databases[stApp.dbType]);
			else
				stApp.database = structNew();			
		
		</cfscript>
		</cflock>

		<cfif listFirst(stApp.cfVersion) neq 5>
	
			<cf_spSetRefreshTimeout>
	
		</cfif>
					
		<!--- filesystem separator (need this in a few places within doAppSetup) --->
		<cfset fs = stApp.fs>
		
		<!--- if application has timed out, used cached configuration if exists --->
		<cfset bAppLoadedFromCache = false>
		<cfif not attributes.refresh and fileExists("#stApp.speckInstallRoot##fs#config#fs#cache#fs##stApp.appName#.wddx")>
			
			<cflock scope="application" type="readonly" timeout="3">
			<cf_spFileRead file="#stApp.speckInstallRoot##fs#config#fs#cache#fs##stApp.appName#.wddx" variable="stAppWddx">
			</cflock>
			
			<cfwddx action="wddx2cfml" input="#stAppWddx#" output="stAppCached">
			
			<cfif isStruct(stAppCached)>
			
				<!--- copy functions from stApp to stAppCached (custom functions don't get saved in wddx format) --->
				<cfscript>
					for (key in stApp)
						if ( isCustomFunction(stApp[key]) )
							stAppCached[key] = duplicate(stApp[key]);
				</cfscript>
				
				<!--- read in application keywords from source (source may have been updated since application configuration was last cached) --->
				<cf_spKeywordsGet source="#stAppCached.keywordsSources#" context=#stAppCached# r_qKeywords="stAppCached.qKeywords">
				
				<cfscript>
					stAppCached.keywords = structNew();
					if ( isDefined("stAppCached.qKeywords") ) { // cf_spKeywordsGet only returns a query to the caller if application keywords have been configured
						for(i=1; i le stAppCached.qKeywords.recordCount; i = i + 1) {
							structInsert(stAppCached.keywords, stAppCached.qKeywords.keyword[i], stAppCached.qKeywords.roles[i]);
						}
					}
				</cfscript>
				
				<!--- Write to the application.speck structure --->
				<cflock scope="APPLICATION" type="EXCLUSIVE" timeout="3">
				<cfset application.speck = structNew()>
				<cfset application.speck = duplicate(stAppCached)>	
				</cflock>
				
				<cfset bAppLoadedFromCache = true>
				
			</cfif>
		
		</cfif>
		
		<cfif not bAppLoadedFromCache> <!--- reading from cached configuration failed --->
		
			<!--- default values for some general application settings --->
			<cfparam name="stApp.appWebRoot" default="">
			<cfparam name="stApp.codb" default="#stApp.appName#">
			<cfparam name="stApp.securityZones" default="#stApp.appName#">
			<cfparam name="stApp.debug" type="boolean" default="no">
			<cfparam name="stApp.locale" default="#getLocale()#">
			<cfparam name="stApp.language" default=""> <!--- leave empty to automatically obtain from locale --->
			<cfparam name="stApp.description" default="">
			<cfparam name="stApp.strings" default="">
			<cfparam name="stApp.keywords" default="spKeywords"> <!--- source of keywords, default is the spKeywords type --->
			
			<!--- default values for database settings --->
			<cfparam name="stApp.dbType" default="ansicompliant">
			<cfparam name="stApp.database.username" default="">
			<cfparam name="stApp.database.password" default="">
			<cfparam name="stApp.database.type" default="#stApp.dbType#">
			<cfparam name="stApp.database.varcharType" default="varchar">
			<cfparam name="stApp.database.varcharMaxLength" default="">
			<cfparam name="stApp.database.longVarcharType" default="">
			<cfparam name="stApp.database.specifyLongVarcharMaxLength" type="boolean" default="no">
			<cfparam name="stApp.database.longVarcharCFSQLType" default=""> <!--- defaults to CF_SQL_CLOB if the longVarcharType is a clob or nclob, otherwise defaults to CF_SQL_LONGVARCHAR - only use this setting to override default behaviour --->
			<cfparam name="stApp.database.tsDDLString" default="timestamp(3)">
			<cfparam name="stApp.database.integerDDLString" default="integer">
			<cfparam name="stApp.database.floatDDLString" default="float">
			<cfparam name="stApp.database.maxIndexKeyLength" default="500">
			<cfparam name="stApp.database.concatOperator" default="||">
			<cfparam name="stApp.database.concatFunction" default="">
			<cfparam name="stApp.database.tableAliasKeyword" default="">
			<cfparam name="stApp.database.tableNotFound" default="">
			
			<cfparam name="stApp.enableOutputCaching" type="boolean" default="yes">
			<cfparam name="stApp.persistentOutputCache" type="boolean" default="yes">

			<cfparam name="stApp.enableRevisions" type="boolean" default="no">
			<cfparam name="stApp.enablePromotion" type="boolean" default="no">
			<cfparam name="stApp.enableChangeControl" type="boolean" default="no">
			
			<cfparam name="stApp.manageKeywords" default="no" type="boolean">
			<cfparam name="stApp.maxKeywordLevels" default="3">
			<cfparam name="stApp.useKeywordsIndex" type="boolean" default="no">
			
			<!--- allow stylesheets to be customised (empty values means use the default stylesheet) --->
			<cfparam name="stApp.adminStylesheet" default="">
			<cfparam name="stApp.toolbarStylesheet" default="">
			<cfparam name="stApp.contentStylesheet" default="">
			
			<!--- look for stylesheets in this sub-directory of speck/www/stylesheets/ --->
			<cfparam name="stApp.stylesheets" default="custom">
			
			<!--- TODO: move system stylesheets to system directory --->
			
			<cfscript>
				// if default stylesheets location not set, look in custom sub-directory
				if ( not len(stApp.stylesheets) ) {
					stApp.stylesheets = "custom";
				}
				customStylesPath = stApp.speckInstallRoot & fs & "www" & fs & "stylesheets" & fs & stApp.stylesheets & fs;
				if ( not len(stApp.adminStylesheet) ) {
					if ( fileExists(customStylesPath & "admin.css") ) {
						stApp.adminStylesheet = "/speck/stylesheets/" & stApp.stylesheets & "/admin.css";
					} else {
						stApp.adminStylesheet = "/speck/stylesheets/system/admin.css";
					}
				}
				if ( not len(stApp.toolbarStylesheet) ) {
					if ( fileExists(customStylesPath & "admin.css") ) {
						stApp.toolbarStylesheet = "/speck/stylesheets/" & stApp.stylesheets & "/toolbar.css";
					} else {
						stApp.toolbarStylesheet = "/speck/stylesheets/system/toolbar.css";
					}
				}
				if ( not len(stApp.contentStylesheet) ) {
					if ( fileExists(customStylesPath & "admin.css") ) {
						stApp.contentStylesheet = "/speck/stylesheets/" & stApp.stylesheets & "/content.css";
					} else {
						stApp.contentStylesheet = "/speck/stylesheets/system/content.css";
					}
				}
			</cfscript>
			
			<cfparam name="stApp.mapping" default="">
			
			<cfif stApp.mapping eq "">
			
				<!--- 
				if no mapping provided, create one based on the assumption that the 
				speck directory and the appInstallRoot directory have the same parent 
				--->
				<!---<cfset stApp.mapping = "speck/../../#stApp.appName#/tags">--->
				<cfset stApp.mapping = "speck/../../#listLast(stApp.appInstallRoot,"\/")#/tags">

			<cfelseif left(stApp.mapping,1) eq "/">
			
				<!--- 
				fix the mapping if necessary, Speck originally assumed there would be one mapping for each app, 
				so it builds paths using the mapping value like this... "/#request.speck.mapping#/something"
				--->
				<cfset stApp.mapping = removeChars(stApp.mapping,1,1)>
				
			</cfif>
			
			<!--- temporary code - remove when change control code is finally finished --->
			<cfif stApp.enableChangeControl>
				
				<!--- only temp code, no going to bother adding this error to the strings file --->
				<cfthrow 
				  	message="Speck encountered an error while processing spApp" 
				  	detail="Application configuration setting 'enableChangeControl' is set to 'yes', but change control is not available in this version of Speck. Please change this setting to 'no'." 
				  	type="speckError">
			
			</cfif>	
			
			<cfscript>
				// copy the securityZones list - the list gets replaced with a struct before copying into 
				// application.speck scope, but we still need the values in the list during app setup
				lSecurityZones = REReplace(stApp.securityZones,"[[:space:]]+","","all"); // remove spaces just in case
				
				// create application structures and queries
				stApp.types = structNew();
				stApp.securityZones = structNew();
				stApp.cache = structNew();
				stApp.queryCache = structNew();
				
				// get java style locale (we'll use the java locale identifier to look for a local strings file)
				// TODO: update to handle locale identifiers that aren't two letter language code and two letter country code
				javaLocale = stApp.locale;
				if ( reFind("^[a-zA-Z]{2}_[a-zA-Z]{2}",javaLocale) ) {
					// application locale is java stylee
					// remove any variant info from the locale, we just want the language and country codes
					javaLocale = left(javaLocale,5);
				} else {
					// old style cf locale, get java equivalent
					stJavaLocales = structNew();
					stJavaLocales.zh_CH = "Chinese (China)";
					stJavaLocales.zh_HK = "Chinese (Hong Kong)";
					stJavaLocales.zh_TW = "Chinese (Taiwan)";
					stJavaLocales.nl_BE = "Dutch (Belgian)";
					stJavaLocales.nl_NL = "Dutch (Standard)";
					stJavaLocales.en_AU = "English (Australian)";
					stJavaLocales.en_CA = "English (Canadian)";
					stJavaLocales.en_NZ = "English (New Zealand)";
					stJavaLocales.en_GB = "English (UK)";
					stJavaLocales.en_US = "English (US)";
					stJavaLocales.fr_BE = "French (Belgian)";
					stJavaLocales.fr_CA = "French (Canadian)";
					stJavaLocales.fr_FR = "French (Standard)"; 
					stJavaLocales.fr_CH = "French (Swiss)";
					stJavaLocales.de_AT = "German (Austrian)";
					stJavaLocales.de_DE = "German (Standard)";
					stJavaLocales.de_CH = "German (Swiss)";
					stJavaLocales.it_IT = "Italian (Standard)";
					stJavaLocales.it_CH = "Italian (Standard)";
					stJavaLocales.ja_JP = "Japanese";
					stJavaLocales.ko_KR = "Korean";
					stJavaLocales.no_NO = "Norwegian (Bokmal)";
					stJavaLocales.no_NO = "Norwegian (Nynorsk)";
					stJavaLocales.pt_BR = "Portuguese (Brazilian)";
					stJavaLocales.pt_PT = "Portuguese (Standard)";
					stJavaLocales.es_MX = "Spanish (Mexican)";
					stJavaLocales.es_ES = "Spanish (Modern)";
					stJavaLocales.es_ES = "Spanish (Standard)";
					stJavaLocales.sv_SE = "Swedish";
					
					aKeys = structFindValue(stJavaLocales,javaLocale);
					if ( arrayIsEmpty(aKeys) ) {
						javaLocale = "en_US";
					} else {
						javaLocale = aKeys[1]["key"];
					}
				}
				javaLocale = lCase(left(javaLocale,2)) & "_" & uCase(right(javaLocale,2));	
					
				if ( not len(stApp.language) ) {
					stApp.language = listFirst(javaLocale,"_");
				}
			</cfscript>
			
			<!--- get application strings --->
			<cfset stringsDir = stApp.speckInstallRoot & fs & "config" & fs & "strings">
			
			<cfif len(stApp.strings)>
			
				<!--- user provided strings setting - file must exist in strings directory --->
				<cfset localStringsFile = "#stringsDir##fs##stApp.strings#.cfg">
				
				<cfif fileExists(localStringsFile)>
					
					<cf_spGetProfileStructure file="#localStringsFile#" variable="stProfile">
					<cfset stApp.strings = duplicate(stProfile.strings)>
				
				<cfelse>
				
					<cfthrow 
					  	message="Speck encountered an error while processing spApp" 
					  	detail="Strings file '#stApp.strings#' not found in strings directory '#stringsDir#'." 
					  	type="speckError">
					
				</cfif>
				
			<cfelse>
			
				<!--- look for strings file matching locale or language, if not found, use system strings --->
				<cfscript>					
					if ( fileExists(stringsDir & fs & lCase(javaLocale) & ".cfg") ) {
						localStringsFile = stringsDir & fs & lCase(javaLocale) & ".cfg";
					} else if ( len(javaLocale) gt 2 and fileExists(stringsDir & fs & listFirst(lCase(javaLocale),"_") & ".cfg") ) {
						localStringsFile = stringsDir & fs & listFirst(lCase(javaLocale),"_") & ".cfg";
					}
				</cfscript>
				
				<cfif isDefined("localStringsFile")>
				
					<cf_spGetProfileStructure file="#localStringsFile#" variable="stProfile">
					<cfset stApp.strings = duplicate(stProfile.strings)>
					
				<cfelse>
	
					<!--- use default system string --->
					<cflock scope="SERVER" type="READONLY" timeout="3">
					<cfset stApp.strings = duplicate(server.speck.strings)>
					</cflock>
					
					<cflog type="information" 
						file="#stApp.appName#" 
						application="no"
						text="CF_SPAPP: No localised strings file found for locale #javaLocale#. Using system default strings.">
				
				</cfif>
				
			</cfif>
			
			<!--- Validate application settings --->
			<cfif not directoryExists(stApp.appInstallRoot)>
			
				<cf_spError error="APP_NO_INSTALL_ROOT" lParams="#stApp.appInstallRoot#" context=#stApp#>
			
			</cfif>
			
			<cfif (not stApp.enableRevisions) and stApp.enablePromotion>
			
				<cf_spError error="APP_PRO_R_REV" context=#stApp#> <!--- The application setting 'enablePromotion' cannot be set to 'yes' without setting 'enableRevisions' to 'yes' --->
			
			</cfif>
			
			<cfif stApp.enableChangeControl and (not stApp.enableRevisions) and (not stApp.enablePromotion)>
		
				<cf_spError error="APP_CC_R_PR" context=#stApp#> <!--- The application setting 'enableChangeControl' cannot be set to 'yes' without setting 'enablePromotion' and 'enableRevisions' to 'yes' --->
			
			</cfif>	
			
			<!--- load database and security settings for this app --->
			
			<!--- read app config file to get additional database settings --->
			<cf_spGetProfileStructure file="#stApp.speckInstallRoot##fs#config#fs#apps#fs##stApp.appName#.app" variable="stProfile">
			
			<cfscript>
				// if app config file has a database section, copy the settings into the database struct
				if ( structKeyExists(stProfile, "database") ) {
					for (key in stProfile.database) {
						if ( structKeyExists(stApp.database, key) )
							// replace key value
							stApp.database[key] = stProfile.database[key];
						else
							// insert key and value
							structInsert(stApp.database,key,stProfile.database[key]);
					}
				}
				// set the cfsqltype to use for longVarchar
				if ( trim(stApp.database.longVarcharCFSQLType) eq "" ) {
					if ( stApp.database.longVarcharType eq "clob" or stApp.database.longVarcharType eq "nclob" ) {
						stApp.database.longVarcharCFSQLType = "CF_SQL_CLOB";
					} else {
						stApp.database.longVarcharCFSQLType = "CF_SQL_LONGVARCHAR";
					}
				}
			</cfscript>
		
			<!--- Load security zones --->
			<cfset securityDir = "#stApp.speckInstallRoot##fs#config#fs#security">

			<cfif lSecurityZones eq stApp.appName and not fileExists("#securityDir##fs##stApp.appName#.users")>
				
				<!--- if the default security zone deoesn't exist, let's be nice and create it --->
				<cflog type="information" 
					file="#stApp.appName#" 
					application="no"
					text="CF_SPAPP: Security zone #stApp.appName# not found. Creating...">

				<!---
					
					This library is part of the Common Function Library Project. An open source
					collection of UDF libraries designed for ColdFusion 5.0. For more information,
					please see the web site at:
						
						http://www.cflib.org
						
					Warning:
					You may not need all the functions in this library. If speed
					is _extremely_ important, you may want to consider deleting
					functions you do not plan on using. Normally you should not
					have to worry about the size of the library.
						
					License:
					This code may be used freely. 
					You may modify this code as you see fit, however, this header, and the header
					for the functions must remain intact.
					
					This code is provided as is.  We make no warranty or guarantee.  Use of this code is at your own risk.
				--->
				
				<cfscript>
				/**
				* Generates an 8-character random password free of annoying similar-looking characters such as 1 or l.
				* 
				* @return Returns a string. 
				* @author Alan McCollough (amccollough@anmc.org) 
				* @version 1, December 18, 2001 
				*/
				function MakePassword() {
					var valid_password = 0;
					var loopindex = 0;
					var this_char = "";
					var seed = "";
					var new_password = "";
					var new_password_seed = "";
					while (valid_password eq 0) {
						new_password = "";
						new_password_seed = CreateUUID();
						for(loopindex=20; loopindex LT 35; loopindex = loopindex + 2) {
							this_char = inputbasen(mid(new_password_seed, loopindex,2),16);
							seed = int(inputbasen(mid(new_password_seed,loopindex/2-9,1),16) mod 3)+1;
							switch(seed){
								case "1": {
								new_password = new_password & chr(int((this_char mod 9) + 48));
								break;
								}
								case "2": {
								new_password = new_password & chr(int((this_char mod 26) + 65));
								break;
								}
								case "3": {
								new_password = new_password & chr(int((this_char mod 26) + 97));
								break;
								}
							} //end switch
						}
						valid_password = iif(refind("(O|o|0|i|l|1|I|5|S)",new_password) gt 0,0,1);	
					}
					return new_password;
				}
				</cfscript>
				
				<!--- users file, note auto-generated password --->
				<cfset generatedPassword = makePassword()>
				<cfset usersFile = "
					[options]
					source=file

					[file]
					admin=Admin User,
				">
				<cfset usersFile = trim(usersFile) & generatedPassword>
				<cf_spFileWrite
					file="#securityDir##fs##stApp.appName#.users" 
					output="#replace(usersFile,chr(9),"","all")#">
				
				<!--- groups file --->
				<cfset groupsFile = "
					[options]
					source=file

					[file]
					admins=admin
				">
				<cf_spFileWrite
					file="#securityDir##fs##stApp.appName#.groups" 
					output="#trim(replace(groupsFile,chr(9),"","all"))#">
				
				<!--- roles file --->
				<cfset rolesFile = "
					[options]
					source=file

					[file]
					spSuper=admins
				">
				<cf_spFileWrite
					file="#securityDir##fs##stApp.appName#.roles" 
					output="#trim(replace(rolesFile,chr(9),"","all"))#">
				

				<!--- tell the user what we've done --->
				<!--- TODO: localisation! --->
				<cfoutput>
				<script type="text/javascript">
					<!--
					//<![CDATA[		
					alert("NOTE: Security zone '#stApp.appName#' created.\n\nYou can log in as user 'admin', password '#generatedPassword#'.");
					//]]>
					//-->
				</script>
				</cfoutput>

			</cfif>
		
			<cfloop list="#lSecurityZones#" index="zone">
				
				<cfset stApp.securityZones[zone] = structNew()>
			
				<cf_spGetProfileStructure file="#securityDir##fs##zone#.users" variable="stProfile">
				<cfset stApp.securityZones[zone].users = duplicate(stProfile)>
				
				<cfif fileExists("#securityDir##fs##zone#.groups")>
				
					<cf_spGetProfileStructure file="#securityDir##fs##zone#.groups" variable="stProfile">
					<cfset stApp.securityZones[zone].groups = duplicate(stProfile)>
				
				</cfif>
				
				<cfif fileExists("#securityDir##fs##zone#.roles")>
				
					<cf_spGetProfileStructure file="#securityDir##fs##zone#.roles" variable="stProfile">
					<cfset stApp.securityZones[zone].roles = duplicate(stProfile)>
				
				</cfif>
			
			</cfloop>
		
			<!--- check application directory structure, add directories if necessary --->
		
			<cfloop list="config,secureassets,tags,tmp,www" index="dir">
		
				<cfset path = stApp.appInstallRoot & fs & dir>
		
				<cfif not directoryExists(path)>
		
					<cftry>
						<cfdirectory action="CREATE" directory="#path#" mode="775">
					<cfcatch>
						<cf_spError error="DIR_NO_CREATE" lParams="#path#" context=#stApp#>
					</cfcatch>
					</cftry>
		
				</cfif>
		
				<cfif dir eq "tags">
		
					<cfloop list="properties,types" index="subdir">
		
						<cfif not directoryExists(path & fs & subdir)>
		
							<cftry>
								<cfdirectory action="CREATE" directory="#path##fs##subdir#" mode="775">
							<cfcatch>
								<cf_spError error="DIR_NO_CREATE" lParams="#path##fs##subdir#" context=#stApp#>
							</cfcatch>
							</cftry>
		
						</cfif>
		
					</cfloop>
		
				<cfelseif dir eq "www">
		
					<cfloop list="assets,properties,types" index="subdir">
		
						<cfif not directoryExists(path & fs & subdir)>
		
							<cftry>
								<cfdirectory action="CREATE" directory="#path##fs##subdir#" mode="775">
							<cfcatch>
								<cf_spError error="DIR_NO_CREATE" lParams="#path##fs##subdir#" context=#stApp#>
							</cfcatch>
							</cftry>
		
						</cfif>
		
					</cfloop>
		
				</cfif>
		
			</cfloop>
		
			<!--- 
			read application configuration information from .cfg files in <appInstallRoot>/config directory into stApp.config 
			Note, this configuration information is not required for a Speck application to run, but can be used to store other 
			information required by this particular application (strings to use as meta keywords and description for example) 
			--->
			<cfset stApp.config = structNew()>
			<cfdirectory action="list" directory="#stApp.appInstallRoot##fs#config" filter="*.cfg" name="qConfig">
			<cfloop query="qConfig">
				
				<cftry>
				
					<cf_spGetProfileStructure file="#stApp.appInstallRoot##fs#config#fs##qConfig.name#" variable="stProfile">
					<cfset stApp.config[replaceNoCase(qConfig.name,".cfg","")] = duplicate(stProfile)>
				
				<cfcatch>
					<cflog type="warning" 
						file="#stApp.appName#"
						application="no"
						text="CF_SPAPP: Could not parse configuration file #stApp.appInstallRoot##fs#config#fs##qConfig.name#">
				</cfcatch>
				</cftry>
			
			</cfloop>
			
			<!--- Check to see that the spCache table exists, create it if necessary --->
				
			<cfset bCreateTable=false>
			
			<cftry>
			
				<cfquery name="qTableCheck" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
				
					SELECT * FROM spCache
					WHERE cacheName='noSuchCache'
				
				</cfquery>
			
			<cfcatch type="Database">
			
				<cfif cfcatch.sqlstate eq "S0002" or stApp.dbTableNotFound(cfcatch.detail,stApp)> <!--- ODBC Error base table does not exist --->
				
					<cfset bCreateTable=true>
					
				<cfelse>
				
					<cfrethrow>
				
				</cfif>
			
			</cfcatch>
			</cftry>
			
			<cfif isDefined("qTableCheck") and listFindNoCase(qTableCheck.columnList,"appName")>
			
				<!--- 
				we're no longer recording the appName, drop the spCache and spWasCached tables and 
				allow them to be re-created and drop the appName column from the history table
				--->
				<cfquery name="qDropTable" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
					DROP TABLE spCache
				</cfquery>
				<cfquery name="qDropTable" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
					DROP TABLE spWasCached
				</cfquery>
				<cfquery name="qAlterTable" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
					ALTER TABLE spHistory DROP COLUMN appName
				</cfquery>
				
				<cfset bCreateTable = true>
			
			</cfif>
		
			<cfif bCreateTable>
				
				<cfquery name="qCreateTable" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
				
					CREATE TABLE spCache (
						cacheName #stApp.textDDLString(250,stApp)# NOT NULL,
						content #stApp.textDDLString(64000,stApp)#, <!--- note: hard-coded max length for cache items stored in database --->
						created #stApp.database.tsDDLString# NOT NULL, 
						expires #stApp.database.tsDDLString#, <!--- note: NULL means cache never expires --->
						contentLength #stApp.database.integerDDLString#,
						PRIMARY KEY (cacheName)
					)
					
				</cfquery>
				
			</cfif>	
			
			<!--- Check to see that the spWasCached table exists, create it if necessary --->
				
			<cfset bCreateTable=false>
		
			<cftry>
			
				<cfquery name="qTableCheck" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
				
					SELECT * FROM spWasCached
					WHERE id='noSuchId'
				
				</cfquery>		
			
			<cfcatch type="Database">
			
				<cfif cfcatch.sqlstate eq "S0002" or stApp.dbTableNotFound(cfcatch.detail,stApp)> <!--- ODBC Error base table does not exist --->
				
					<cfset bCreateTable=true>
					
				<cfelse>
				
					<cfrethrow>
				
				</cfif>
			
			</cfcatch>
			</cftry>
			
			<cfif bCreateTable>
				
				<cfquery name="qCreateTable" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
				
					CREATE TABLE spWasCached (
						contentType #stApp.textDDLString(50,stApp)# NOT NULL,
						id #stApp.textDDLString(stApp.database.maxIndexKeyLength,stApp)# ,
						label #stApp.textDDLString(250,stApp)# ,
						keywords #stApp.textDDLString(stApp.database.maxIndexKeyLength,stApp)# ,
						cacheName #stApp.textDDLString(250,stApp)# ,
						scriptName #stApp.textDDLString(250,stApp)# ,
						pathInfo #stApp.textDDLString(250,stApp)# ,
						queryString #stApp.textDDLString(250,stApp)# ,
						ts #stApp.database.tsDDLString# NOT NULL
					)
					
				</cfquery>
				
				<cftry>

					<cfquery name="qAddIndex" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
						
						CREATE INDEX spWasCachedIdx1
						ON spWasCached (cacheName,contentType)
						
					</cfquery>
				
				<cfcatch>

					<cfquery name="qAddIndex" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
							
						CREATE INDEX spWasCachedIdx1
						ON spWasCached (cacheName)
						
					</cfquery>

				</cfcatch>
				</cftry>

				<cfquery name="qAddIndex" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
					
					CREATE INDEX spWasCachedIdx2
					ON spWasCached (contentType)
					
				</cfquery>
		
			</cfif>
			
			
			<!--- Check to see that the spHistory table exists, create it if necessary --->
				
			<cfset bCreateTable=false>
			
			<cftry>
			
				<cfquery name="qTableCheck" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
				
					SELECT id FROM spHistory
					WHERE id='noSuchId'
				
				</cfquery>
			
			<cfcatch type="Database">
			
				<cfif cfcatch.sqlstate eq "S0002" or stApp.dbTableNotFound(cfcatch.detail,stApp)> <!--- ODBC Error base table does not exist --->
				
					<cfset bCreateTable=true>
					
				<cfelse>
				
					<cfrethrow>
				
				</cfif>
			
			</cfcatch>
			</cftry>
			
			<cfif bCreateTable>
			
				<cf_spError logOnly="true" error="NO_HISTORY_TABLE" lParams=#stApp.codb# context=#stApp#>
				
				<cfquery name="qCreateTable" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
				
					CREATE TABLE spHistory (
						id CHAR (35) NOT NULL,
						contentType #stApp.textDDLString(50,stApp)# NOT NULL,
						revision #stApp.database.integerDDLString# NOT NULL,
						promoLevel #stApp.database.integerDDLString# NOT NULL,
						editor #stApp.textDDLString(20,stApp)# ,
						changeId CHAR (35) ,
						ts #stApp.database.tsDDLString# NOT NULL,
						PRIMARY KEY (id,revision,promoLevel,ts)
					)
					
				</cfquery>
				
				<cfquery name="qAddIndex" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
				
					CREATE INDEX spHistoryIdx1
					ON spHistory (id,ts)
		
				</cfquery>
				
				<cfquery name="qAddIndex" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
				
					CREATE INDEX spHistoryIdx2
					ON spHistory (id,revision,ts)
				
				</cfquery>
				
				<cfquery name="qAddIndex" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
				
					CREATE INDEX spHistoryIdx3
					ON spHistory (id,promoLevel,ts)
				
				</cfquery>
				
			</cfif>	
			
			<!--- Check to see that the spKeywordsIndex table exists, create it if necessary --->
				
			<cfset bCreateTable=false>
			
			<cftry>
			
				<cfquery name="qTableCheck" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
				
					SELECT id FROM spKeywordsIndex
					WHERE id='noSuchId'
				
				</cfquery>
			
			<cfcatch type="Database">
			
				<cfif cfcatch.sqlstate eq "S0002" or stApp.dbTableNotFound(cfcatch.detail,stApp)> <!--- ODBC Error base table does not exist --->
				
					<cfset bCreateTable=true>
					
				<cfelse>
				
					<cfrethrow>
				
				</cfif>
			
			</cfcatch>
			</cftry>
			
			<cfif bCreateTable>
			
				<cf_spError logOnly="true" error="NO_KEYWORDSINDEX_TABLE" lParams=#stApp.codb# context=#stApp#>
				
				<cfquery name="qCreateTable" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
				
					CREATE TABLE spKeywordsIndex (
						contentType #stApp.textDDLString(45,stApp)# NOT NULL,
						keyword #stApp.textDDLString(250,stApp)# NOT NULL,
						id CHAR (35) NOT NULL,
						PRIMARY KEY (keyword,contentType,id)
					)
					
				</cfquery>
				
				<cfquery name="qAddIndex" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
					
					CREATE INDEX spKeywordsIdx1
					ON spKeywordsIndex (id)
					
				</cfquery>
				
			</cfif>	
			
			
			<!--- Check to see that the spSequences table exists, create it if necessary --->
				
			<cfset bCreateTable=false>
			
			<cftry>
			
				<cfquery name="qTableCheck" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
				
					SELECT * FROM spSequences
					WHERE contentType = 'noSuchType'
				
				</cfquery>
			
			<cfcatch type="Database">
			
				<cfif cfcatch.sqlstate eq "S0002" or stApp.dbTableNotFound(cfcatch.detail,stApp)> <!--- ODBC Error base table does not exist --->
				
					<cfset bCreateTable=true>
					
				<cfelse>
				
					<cfrethrow>
				
				</cfif>
			
			</cfcatch>
			</cftry>
			
			<cfif bCreateTable>
			
				<cf_spError logOnly="true" error="NO_KEYWORDSINDEX_TABLE" lParams=#stApp.codb# context=#stApp#>
				
				<cfquery name="qCreateTable" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
				
					CREATE TABLE spSequences (
						contentType #stApp.textDDLString(45,stApp)# NOT NULL,
						sequenceId INTEGER NOT NULL,
						PRIMARY KEY (contentType,sequenceId)
					)
					
				</cfquery>
				
			<cfelseif stApp.dbtype neq "access">
				
				<!--- temporary code to upper case all type names in spSequences table - I forgot that the case won't always match on windows, oops --->
				<cfquery  name="qUpdateSequences" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
					UPDATE spSequences SET contentType = UPPER(contentType)
				</cfquery>
				
			</cfif>	
		
			<!--- Load speck's type definitions (do these before loading the application's type definitions so 
				the methods for the default type will be known when loading the application's types - see spType) --->
			<cfset stApp.types = structNew()>
			<cfset fs = stApp.fs>
			<cfdirectory action="LIST" directory="#stApp.speckInstallRoot##fs#tags#fs#types" name="qTypes" filter="*.cfm">
			
			<cfloop query="qTypes">
				
				<cfif type eq "File">
				
					<cfset typeName = spanExcluding(name, ".")>
						
					<!--- <cftry> --->
					
						<cfmodule 
							template="/speck/types/#name#" 
							r_stType="stApp.types.#typeName#"
							context=#stApp#
							refresh="yes">
						
					<!--- <cfcatch>
					
						<cfthrow message="Error loading type definition /speck/types/#name#" detail="#cfcatch.message##cfcatch.detail#">
					
					</cfcatch>
					</cftry> --->
						
					<cfif stApp.types[typeName].name neq typeName>
					
						<cf_spError error="TYPENAME_NOT_FILENAME" lParams="#stApp.types[typeName].name#,/speck/types/#name#" context=#stApp#>
					
					</cfif>
		
				</cfif>
						
			</cfloop>
		
			<!--- Load application's type definitions --->
			<cfdirectory action="LIST" directory="#stApp.appInstallRoot##fs#tags#fs#types" name="qTypes" filter="*.cfm">
			
			<cfloop query="qTypes">			
				
				<cfset typeName = spanExcluding(name, ".")>
				
				<!--- do not allow default type to be extended or overridden --->
				<cfif type eq "File" and not listFindNoCase("spDefault",typeName)>

					<!--- <cftry> --->
					
						<cfmodule
							template="/#stApp.mapping#/types/#name#" 
							r_stType="stApp.types.#typeName#"
							context=#stApp#
							refresh="yes">
						
					<!--- <cfcatch>
					
						<cfthrow message="Error loading type definition /#stApp.mapping#/types/#name#<br>" detail="#cfcatch.message##cfcatch.detail#">
					
					</cfcatch>
					</cftry> --->
						
					<cfif stApp.types[typeName].name neq typeName>
					
						<cf_spError error="TYPENAME_NOT_FILENAME" lParams="#stApp.types[typeName].name#,/#stApp.mapping#/types/#name#" context=#stApp#>
					
					</cfif>				
		
				</cfif>
						
			</cfloop>
			
			<!--- loop over all types and call refresh method for each type if it exists --->
			<cfloop collection="#stApp.types#" item="type">
			
				<cfset stType = stApp.types[type]>
				
				<cfif isDefined("stType.methods.refresh")>

					<cfmodule template="#stType.methods.refresh#" type="#type#" method="refresh" context=#stApp#>
				
				</cfif>
			
			</cfloop>
			
			
			<!--- get keywords into stApp.keywords... --->

			<cf_spKeywordsGet source="#stApp.keywords#" context=#stApp# r_qKeywords="stApp.qKeywords">
			
			<cfscript>
				// save keywords sources for future reference - we're going to use the keywords key of stApp to store a struct containing all keywords
				stApp.keywordsSources = stApp.keywords;
				stApp.keywords = structNew();
				if ( isDefined("stApp.qKeywords") ) { // cf_spKeywordsGet only returns a query to the caller if application keywords have been configured
					for(i=1; i le stApp.qKeywords.recordCount; i = i + 1) {
						structInsert(stApp.keywords, stApp.qKeywords.keyword[i], stApp.qKeywords.roles[i]);
					}
				}
			</cfscript>
			
		
			<cfif attributes.refresh>
			
				<!--- delete cached configuration --->
				<cfif fileExists("#stApp.speckInstallRoot##fs#config#fs#cache#fs##stApp.appName#.wddx")>
				
					<cffile action="delete" file="#stApp.speckInstallRoot##fs#config#fs#cache#fs##stApp.appName#.wddx">
				
				</cfif>
			
				<cftry> <!--- try/catch added to allow Speck to run using a read-only database, eg. on a backup server with a replicated version of a live db --->
				
					<cftry>

						<!--- dump cache info for this application --->
						<cfquery name="qTruncateCache" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
						
							TRUNCATE TABLE spCache
						
						</cfquery>
						
						<!--- dump wasCached info for this application --->
						<cfquery name="qTruncateWasCached" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
						
							TRUNCATE TABLE spWasCached
						
						</cfquery>
						
					<cfcatch>
					
						<!--- dump cache info for this application --->
						<cfquery name="qDeleteCache" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
						
							DELETE FROM spCache
						
						</cfquery>
						
						<!--- dump wasCached info for this application --->
						<cfquery name="qDeleteWasCached" datasource=#stApp.codb# username=#stApp.database.username# password=#stApp.database.password#>
						
							DELETE FROM spWasCached
						
						</cfquery>
					
					</cfcatch>
					</cftry>
				
				<cfcatch>
					
					<!--- this should only happen when either the database is read-only or one of the queries timed out --->
					<cflog type="warning" 
						file="#stApp.appName#" 
						application="no"
						text="CF_SPAPP: Could not flush persistent cache. #cfcatch.message#">

				</cfcatch>
				</cftry>
			
			</cfif>
			
			<!--- Write to the application.speck structure and cache a copy as a wddx format file --->
			<cflock scope="APPLICATION" type="EXCLUSIVE" timeout="3">
			<cfset application.speck = structNew()>
			<cfset application.speck = duplicate(stApp)>
			</cflock>
			
			<cfwddx action="cfml2wddx" input="#stApp#" output="stAppWddx">
			<cf_spFileWrite file="#stApp.speckInstallRoot##fs#config#fs#cache#fs##stApp.appName#.wddx" output="#stAppWddx#">
			
		</cfif> <!--- not bAppLoadedFromCache --->
		
	<cfcatch>
		
		<!--- 
		an error occurred during application initialisation...
		Delete "starting" key from application.speck structure
		and delete application configuration from server scope 
		to force a reload of the application config (in case
		the error is due to the app being mis-configured) 
		--->
		
		<cflock scope="APPLICATION" type="EXCLUSIVE" timeout="3">
		<cfset application.speck = structNew()>
		</cflock>
		
		<cflock scope="SERVER" type="EXCLUSIVE" timeout="3">
		<cfset void = structDelete(server.speck.apps,attributes.name)>
		</cflock>
		
		<cfrethrow>
	
	</cfcatch>
	</cftry>		
	
</cfif> <!--- end doAppSetup --->
		
<!--- Copy application.speck excluding cache structures to the request scope so that we can use it without read locks --->
<cfset request.speck = structNew()>
<cflock scope="APPLICATION" timeout="3" type="READONLY">
<cfscript>
	for (key in application.speck) {
		if (key neq "cache" and key neq "queryCache" and key neq "wasCached" and key neq "securityZones") {
			request.speck[key] = duplicate(application.speck[key]);
		}
	}
</cfscript>
</cflock>

<!--- Set Locale --->
<cfset void = setLocale(request.speck.locale)>

<!--- Set up Session scope --->
<cflock scope="SESSION" timeout="3" type="READONLY">
<cfset sessionExists = structKeyExists(session,"speck") and isStruct(session.speck) and not structIsEmpty(session.speck)>
</cflock>

<!--- Do we have a reason to lock up the session scope? --->
<cfif not sessionExists or ( isDefined("form.spLogonUser") and isDefined("form.spLogonPassword") ) or isDefined("form.spLogout")>

	<!--- Set up the session.speck structure --->
	
	<cflock scope="SESSION" timeout="3" type="EXCLUSIVE">
	
	<cfif not sessionExists>
		
		<!--- get list of security zones --->
		<cflock scope="APPLICATION" timeout="3" type="READONLY">
		<cfset lSecurityZones = structKeyList(application.speck.securityZones)>
		</cflock>
		
		<cfscript>
			session.speck = structNew();
			session.speck.fullName = "";
			session.speck.email = "";
			session.speck.groups = structNew();
			session.speck.roles = structNew();
			session.speck.viewLevel = "live";		// Default to live
			session.speck.viewDate = "";			// "" = now
			session.speck.showAdminLinks = false;	// Default showAdminLinks to no, spToolbar can change 
			session.speck.showCacheInfo = false;	// Default showCacheInfo to no, spToolbar can change - not implemented yet
			session.speck.auth = "none";			// Not authenticated - valid values are none, cookie, or logon
			session.speck.securityZone = ""; 		// Security zone within which this user was found (we need this to differentiate users with the same username in different zones)
			
			if ( isDefined("cookie.#request.speck.appName#_user") ) {
				// We recognise the user
				session.speck.user = cookie[request.speck.appName & "_user"];			
				if ( isDefined("cookie.#request.speck.appName#_zone") ) {
					// We can determine the security zone for the user
					zoneHash = cookie[request.speck.appName & "_zone"];
					for ( i=1; i lte listLen(lSecurityZones); i=i+1 ) { // the cookie value is hashed so loop over the list of security zone to find a match
						zone = listGetAt(lSecurityZones,i);
						if ( hash(zone) eq zoneHash ) {
							session.speck.securityZone = zone;
							break;
						}
					}
				}											
			} else {
				// Anonymous user
				session.speck.user = "anonymous";
			}
		</cfscript>	
	
	</cfif>
	
	<!--- Get user's details if they're not anonymous --->
	
	<cfif session.speck.user neq "anonymous" and not isDefined("session.speck.fullName")>
	
		<cf_spUserGet user="#session.speck.user#" securityZone="#session.speck.securityZone#" r_stUser="stUser">
			
		<cfscript>
			if ( isDefined("stUser") ) {
				// copy keys from stUser to session.speck
				for (key in stUser) {
					if ( structKeyExists(session.speck, key) )
						// replace key value
						session.speck[key] = stUser[key];
					else
						// insert key and value
						structInsert(session.speck,key,stUser[key]);	
				}
				// Upgrade authentication level to "cookie"
				session.speck.auth = "cookie";
			}
		</cfscript>
	
	</cfif>
	
	<!--- Is someone trying to authenticate? --->
	
	<cfif isDefined("form.spLogonUser") and isDefined("form.spLogonPassword")>
		
		<!--- Get user details, making sure that the password matches --->
		<cf_spUserGet user="#form.spLogonUser#" password="#form.spLogonPassword#" r_stUser="stUser">
	
		<cfif not isDefined("stUser")>
			
			<!--- unknown user or password incorrect --->
			<cfset request.speck.failedLogon = true>
			
			<cf_spError error="APP_LOGIN_FAILED" lParams="#form.spLogonUser#,#form.spLogonPassword#" logOnly="true">
			
		<cfelse>
			
			<!--- Successful authentication --->
			<cfscript>
				// copy keys from stUser to session.speck
				for (key in stUser) {
					if ( structKeyExists(session.speck, key) )
						// replace key value
						session.speck[key] = stUser[key];
					else
						// insert key and value
						structInsert(session.speck,key,stUser[key]);	
				}
				// upgrade authentication level to logon
				session.speck.auth = "logon";
			</cfscript>
			
			<!--- TODO: obtain log text from strings file --->
			<cflog text="User '#form.spLogonUser#' logged in from #cgi.remote_addr#"
				file="#request.speck.appName#"
				type="information"
				application="no">
			
			<cfcookie name="#request.speck.appName#_user" value="#stUser.user#" expires="30">
			<cfcookie name="#request.speck.appName#_zone" value="#hash(stUser.securityZone)#" expires="30">
		
		</cfif>

	</cfif>	
	
	<!--- User wants to logout --->
	<cfif isDefined("form.spLogout")>
	
		<cfset session.speck = structNew()>
		<cfset session.speck.user = "anonymous">
		<cfset session.speck.fullName = "">
		<cfset session.speck.email = "">
		<cfset session.speck.auth = "none">
		<cfset session.speck.securityZone = "">
		<cfset session.speck.showAdminLinks = false>
		<cfset session.speck.showCacheInfo = false>
		<cfset session.speck.groups = structNew()>
		<cfset session.speck.roles = structNew()>
		<cfset session.speck.viewLevel = "live">
		<cfset session.speck.viewDate = "">
	
	</cfif>
	
	</cflock>

</cfif>

<!--- Copy the session scope to request.speck.session for reference during remainder of request --->
<cflock scope="SESSION" timeout="3" type="READONLY">
<cfset request.speck.session = duplicate(session.speck)>
</cflock>

<!--- temporary code to support old stylesheet locations and the fact that these settings weren't cfparamed within application initialisation --->
<cfparam name="request.speck.stylesheet" default=""> <!--- deprecated config setting, use adminStylesheet instead --->
<cfparam name="request.speck.adminStylesheet" default="#request.speck.stylesheet#">
<cfif not len(request.speck.adminStylesheet)>
	<cfset request.speck.adminStylesheet = "/speck/stylesheets/admin.css">
</cfif>
<cfparam name="request.speck.toolbarStylesheet" default="">
<cfif not len(request.speck.toolbarStylesheet)>
	<cfset request.speck.toolbarStylesheet = "/speck/stylesheets/toolbar.css">
</cfif>
<cfparam name="request.speck.contentStylesheet" default="">
<cfif not len(request.speck.contentStylesheet)>
	<cfset request.speck.contentStylesheet = "/speck/stylesheets/content.css">
</cfif>

<!--- temporary code, can be removed once all applications have been refrehed --->
<cfparam name="request.speck.database.longVarcharCFSQLType" default="CF_SQL_LONGVARCHAR">

<cfif not structKeyExists(request.speck,"getDomainFromHostName")>

	<!--- TODO: move function to spFunctions and add code to read spFunctions and copy missing function to application.speck and request.speck if necessary --->
	<cfscript>
		function getDomainFromHostName() {
			// some crude code to get an email domain from the current host name
			var domain = "";
			if ( arrayLen(arguments) ) {
				domain = lCase(arguments[1]);
			} else {
				domain = lCase(cgi.HTTP_HOST);
			}
			if ( listLen(domain,".") gt 2 ) {
				domain = listDeleteAt(domain,1,".");
			}
			return lCase(domain);
		}
		request.speck.getDomainFromHostName = getDomainFromHostName;
	</cfscript>

</cfif>
