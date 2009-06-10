<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- initialises portal application - reads portal config, writes speck app config, creates user database tables, calls cf_spApp, does SES stuff --->

<cfparam name="attributes.name" default="">
<cfparam name="attributes.refresh" default="false" type="boolean">

<cfif not len(attributes.name)>

	<cfscript>
		// obtain application name from path - assumes that public web root directory 
		// is a sub-directory of the appInstallRoot and that the application install 
		// directory name is the same as the application name. 
		webDocumentRoot = getBaseTemplatePath();
		if ( find("/",webDocumentRoot) ) {
			fs = "/";
		} else {
			fs = "\";
		}
		for ( i = listLen(cgi.script_name,"/"); i gte 1; i = i-1 ) { // this lunacy to handle applications running inside virtual directories and requests within sub-directories
			if ( listLast(webDocumentRoot,fs) eq listGetAt(cgi.script_name,i,"/") ) {
				webDocumentRoot = listDeleteAt(webDocumentRoot,listLen(webDocumentRoot,fs),fs);
			}
		}
		attributes.name = listGetAt(webDocumentRoot,listLen(webDocumentRoot,fs)-1,fs);
	</cfscript>
	
</cfif>

<!--- minimal call to cfapplication so we can look for things in application scope - spApp overrides this by calling cfapplication again --->
<cfapplication name="#attributes.name#" sessionmanagement="Yes" setclientcookies="no">

<!--- 
Check if we need to refresh the application. Set bRefresh to true to refresh portal (this may happen due to an application 
timeout or CF server restart). Set attributes.refresh to true to force a refresh of the Speck application if necessary.
--->
<cfset bRefresh = attributes.refresh>
<cfscript>
	function fileLastModified(fileName) {
	    var oFile = createObject("java","java.io.File");
	    var oDate = createObject("java","java.util.Date");
	    oFile.init(fileName);
	    return oDate.init(oFile.lastModified());
	}
</cfscript>
<cflock scope="application" type="readonly" timeout="5">
<cfif not isDefined("application.speck.portal")>

	<cfset bRefresh = true>
	<cfif isDefined("application.speck.speckInstallRoot")>
		<!--- 
		speck application exists but has been initialised outside of the portal 
		framework - force a refresh, flushes application configuration cache etc.
		--->
		<cfset attributes.refresh = true>
	</cfif>
	
<cfelseif isDefined("application.speck.started") 
	and fileExists("#application.speck.appInstallRoot#/tmp/refresh.txt") 
	and fileLastModified("#application.speck.appInstallRoot#/tmp/refresh.txt") gt application.speck.started>
	
	<!--- idea nicked from passenger/mod_rails - if tmp/refresh.txt exists, and last modified date later than date application was started, force refresh --->
	<cfset bRefresh = true>
	<cfset attributes.refresh = true>
	
	<cflog type="information" 
		file="#attributes.name#" 
		application="no"
		text="CF_SPPORTAL: Found refresh.txt file in tmp directory with modified date later than date application started - forcing application refresh.">
	
	<cftry>
		<!--- delete the file if possible to avoid issues with backups, or maybe issues with jvm and os time differences --->
		<cffile action="delete" file="#application.speck.appInstallRoot#/tmp/refresh.txt">
	<cfcatch>
		<cflog type="warning" 
			file="#attributes.name#" 
			application="no"
			text="CF_SPPORTAL: Warning - could not delete tmp/refresh.txt, this is probably a permissions issue.">
	</cfcatch>
	</cftry>
	
</cfif>
</cflock>

<!--- allow users with spSuper role to refresh the application via the toolbar --->
<cfif isDefined("url.refreshapp")>
	<cflock scope="session" type="readonly" timeout="5">
	<cfif isDefined("session.speck.roles.spSuper")>
		<cfset bRefresh = true>
		<cfset attributes.refresh = true> <!--- force a speck app refresh --->
	</cfif>
	</cflock>
</cfif>

<cfif bRefresh>

	<!--- 
	* read portal configuration file and write speck application configuration file
	* check that security database tables exist, if not create
	* check that required directories exist, if not create
	* call cf_spApp 
	* save portal configuration to application.speck.portal
	--->

	<cfscript>
		speckInstallRoot = getCurrentTemplatePath();	
		
		if (find("/", speckInstallRoot) neq 0)
			fs = "/";
		else
			fs = "\";
			
		nl = chr(13) & chr(10);
		
		speckOffset = findNoCase(fs & "speck" & fs, speckInstallRoot);
		speckInstallRoot = left(speckInstallRoot, speckOffset + 5);
		
		// Derive appInstallRoot from base template path. This is not 100% failsafe, symlinks/junctions can 
		// cause problems and if this happens we derive the appInstallRoot from the speckInstallRoot and 
		// the appName, assuming that the speck and application directories have the same parent directory.

		// get the web document root first (note: this code is the exact same as the code used when aut-detecting the appName, maybe it should be a function)
		webDocumentRoot = getBaseTemplatePath();
		for ( i = listLen(cgi.script_name,"/"); i gte 1; i = i-1 ) { // this lunacy to handle applications running inside virtual directories and requests within sub-directories
			if ( listLast(webDocumentRoot,fs) eq listGetAt(cgi.script_name,i,"/") ) {
				webDocumentRoot = listDeleteAt(webDocumentRoot,listLen(webDocumentRoot,fs),fs);
			}
		}
		// and remove the final directory in web document root to get the app install root
		appInstallRoot = listDeleteAt(webDocumentRoot,listLen(webDocumentRoot,fs),fs);
			
		stPortal = structNew(); // save all configuration settings here and save to application scope when finished initialising	
	</cfscript>
	
	<!--- default portal specific configuration settings (i.e. things that are not passed to spApp) --->
	<cfparam name="stPortal.docType" default="xhtml"> <!--- html|xhtml --->
	<cfparam name="stPortal.docSubtype" default="transitional"> <!--- strict|transitional|frameset --->
	<!--- possible TODO: add docTypeVersion configuration setting --->
	<cfparam name="stPortal.name" default="#attributes.name#"> <!--- name of site, can be used by shared templates when outputting site name --->
	<cfparam name="stPortal.domain" default=""> <!--- domain name used by default when building email address etc. - if left blank, will be derived from host name --->
	<cfparam name="stPortal.stylesheet" default=""> <!--- will default to /stylesheets/screen.css or /stylesheets/main.css if files exist --->
	<cfparam name="stPortal.importStyles" default="">
	<cfparam name="stPortal.printStylesheet" default=""> <!--- will default to /stylesheets/print.css if file exists --->
	<cfparam name="stPortal.popupStylesheet" default=""> <!--- will default to /stylesheets/popup.css if file exists --->
	<cfparam name="stPortal.layout" default="">
	<cfparam name="stPortal.template" default="">
	<cfparam name="stPortal.fileManager" default="yes" type="boolean">
	<cfparam name="stPortal.fileManagerIps" default="127.0.0.1">
	<cfparam name="stPortal.fileManagerUsers" default="">
	<cfparam name="stPortal.titleSeparator" default="-">
	<cfparam name="stPortal.breadCrumbPageTitles" type="boolean" default="no"> <!--- deprecated setting, do not use, likely to be removed --->
	<cfparam name="stPortal.trackUserActivity" type="boolean" default="no"> <!--- record when user was last active in spUsers database table (use with caution, results in an update statement eveyr 90 seconds or so) --->
	<cfparam name="stPortal.logRequests" type="boolean" default="no">
	<cfparam name="stPortal.passwordEncryption" default=""> <!--- set to name of function to encrypt/hash passwords - gets passed to portal security zone, see speck docs --->	
	<cfparam name="stPortal.pngfix" type="boolean" default="no"> <!--- hack for IE6 to provide support for transparent backgrounds in png images --->
	<cfparam name="stPortal.prototype" type="boolean" default="no"> <!--- the dogs bollox! I love you prototype, in whatever way a man can love a javascript library. --->
	<cfparam name="stPortal.scriptaculous" type="boolean" default="no"> <!--- note: depends on prototype --->
	<cfparam name="stPortal.lightbox" type="boolean" default="no"> <!--- note: depends on scriptaculous. If enabled, Image content type will use lightbox to display popup images. --->
	<cfparam name="stPortal.clearfix" type="boolean" default="no"> <!--- define a clearfix class selector which can be used to clear floats within block level elements (it's a hack Jim, but a necessary one to make the new FCKeditor config "just work" --->
	<cfparam name="stPortal.seoIdentifiers" type="boolean" default="no"> <!--- if true, templates should try to avoid using UUIDs in URLs and instead use labels or some other search engine optimized/friendly identifiers in URLs (typically the label) --->
	<cfparam name="stPortal.rewriteEngine" default="no" type="boolean"> <!--- external url rewriting engine enabled (see below) --->
	<cfparam name="stPortal.rewritePrefix" default="go/"> <!--- prefix urls to allow for a simple rewrite rule to match speck urls (see below) --->
	<!---
	If rewrite engine is enabled (e.g. mod_rewrite), you need to add rewrite rules to the engine's config.
	Speck has two rewrite URL formats. The old format assumes a prefix of roman characters followed by 
	a dash (e.g. do-). The new format either has no prefix or a prefix of roman characters followed by 
	a forward slash (e.g. go/). The default value for the rewrite prefix was changed from do- to go/ when 
	the new rewrite URL format was introduced (April 2008). I never really agreed with the old format, 
	but a colleague who had more seo experience than me insisted on it for some early portal projects. 
	Speck will automatically output urls in the old format if the rewrite prefix ends with '-', and the 
	new format if there is no rewrite prefix or the rewrite prefix ends with '/'.
	
	The old rewrite format assumes the prefix is to be replaced with /index.cfm/spKey/ and that the rest 
	of the URL can be handled by the fusiom ses converter code included in this tag. 
	
	The new rewrite format removes the prefix and sends the rest of the path along as the spPath querystring 
	parameter, which is parsed for every request. The spPath paramter should contain at least a keyword, 
	optionally followed by the id of a content item (or some string which can be used to uniquely identify a 
	content item) and some other stuff. There is no need to prefix the keyword and id with spKey and spId, 
	speck assumes a format of keyword with forward slash in place of dots, followed by an id. For example, 
	the path /go/news/irish/bertie-ahern-resigns should be translated to 
	/index.cfm?spPath=/news/irish/bertie-ahern-resigns by the rewrite engine. When spPath is parsed, new url 
	parameters spKey and spId will be created with values 'news.irish' and 'bertie-ahern-resigns' respectively. 
	
	Example mod_rewrite rules for old rewrite URL format:
		RewriteRule ^/do\-([^/]+)(/[^/]+)/spId/(.*)$ /index.cfm/spKey/$1/spId/$3 [PT,QSA,L]
		RewriteRule ^/do\-(.*)$ /index.cfm/spKey/$1 [PT,QSA,L]
		
	Example mod_rewrite rules for new rewrite URL format, with prefix:
		RewriteRule ^/go/(.*)$ /index.cfm?spPath=$1 [PT,QSA,L]
	
	Example mod_rewrite rules for new rewrite URL format, without prefix:
		# Always rewrite / to /index.cfm. Not strictly required, but
		# avoids checking the next set of conditions unnecessarily
		# and passing each file specified in the DirectoryIndex
		# directive through the rewrite rule.
		RewriteRule ^/$ /index.cfm [PT,QSA,L]
		
		# Ignore requests for real files or directories
		RewriteCond %{DOCUMENT_ROOT}/%{SCRIPT_FILENAME} !-f
		RewriteCond %{DOCUMENT_ROOT}/%{SCRIPT_FILENAME} !-d
		
		# Ignore aliases and requests that might be handled by a servlet
		RewriteCond %{REQUEST_URI} !^/(speck|cf|flash) [NC]
		
		# Allow for search engine safe URLs that don't use the rewrite engine
		RewriteCond %{REQUEST_URI} !\.cfm/
		
		# Finally, rewrite the URL, passing the path as a url parameter.
		# We need to pass the request through to the next handler so jrun
		# gets to process it. Query strings should be appended, internal
		# sub-requests should be ignored and this should be the last rule.
		RewriteRule ^/(.*)$ /index.cfm?spPath=$1 [PT,QSA,L,NS]

	--->
	
	<!--- default Speck config settings for portal apps (set the few required settings and cfparam any others where the default for portal apps is different to the default for standard speck apps) --->
	<cfset stApp = structNew()>
	<cfset stApp.appName = attributes.name>
	<cfset stApp.appInstallRoot = appInstallRoot>
	<cfparam name="stApp.codb" default="#stApp.appName#">
	<cfparam name="stApp.dbType" default="ansicompliant">
	<cfparam name="stApp.labelRoles" default="spSuper,spEdit=r">
	<cfparam name="stApp.keywordsRoles" default="spSuper,spEdit=r">
	<cfparam name="stApp.sesSuffix" default=".html"> <!--- dummy suffix appended to the end of urls (when rewrite engine enabled, this only gets appended to urls referencing a content item) --->	
	<cfparam name="stApp.securityZones" default="portal">
	<cfif compareNoCase(replace(speckInstallRoot,"#fs#speck",""),listDeleteAt(appInstallRoot,listLen(appInstallRoot,fs),fs)) neq 0> 
		<cfparam name="stApp.mapping" default="/webapps/#attributes.name#/tags"> <!--- if speck and application directories do not have same parent, assume a /webapps mapping exists --->
	</cfif>
	<cfparam name="stApp.sesUrls" default="yes" type="boolean">
	<cfparam name="stApp.manageKeywords" default="yes" type="boolean">
	<cfparam name="stApp.appWebRoot" default="">
	
	<!--- read portal config file --->
	<cfset stConfig = structNew()>
	<cfif fileExists("#appInstallRoot##fs#config#fs#portal.cfg")>
	
		<cf_spGetProfileStructure file="#appInstallRoot##fs#config#fs#portal.cfg" variable="stProfile">
		<cfset stConfig = duplicate(stProfile)>
	
	<cfelse>
	
		<!--- 
		If configuration file not found, there may have been a problem deriving the appInstallRoot.
		This is possible if the home directory for the web server is a symbolic link or junction file.
		Assume in this case that the speck and application directories have the same parent and derive 
		the appInstallRoot from the speckInstallRoot and the appName. Lots of assumptions here! ;->
		--->
		<cfset appInstallRoot = listDeleteAt(speckInstallRoot,listLen(speckInstallRoot,fs),fs) & fs & attributes.name>
		
		<cfif fileExists("#appInstallRoot##fs#config#fs#portal.cfg")>
	
			<cf_spGetProfileStructure file="#appInstallRoot##fs#config#fs#portal.cfg" variable="stProfile">
			<cfset stConfig = duplicate(stProfile)>
			
		<cfelse>
		
			<!--- cannot find portal configuration file --->
			<cfthrow message="Portal configuration file not found" detail="This probably means that the app name was not passed as an attribute and the code to detect the web document root and app name failed (the cf_spPortal tag was probably called from a script running in a virtual directory).">
			
		</cfif>
	
	</cfif>

	<cfif not structKeyExists(stConfig,"settings")>
	
		<cfthrow message="Invalid portal configuration file format - settings section not found">
	
	</cfif>
	
	<cfscript>
		// copy settings from portal config file to stPortal and stApp (almost anything not pre-defined as a portal config setting also gets copied to stApp)
		for ( key in stConfig.settings ) {
			if ( not structKeyExists(stPortal,key) and not listFindNoCase("appName,keywords",key) ) {
				// copy setting to stApp
				stApp[key] = stConfig.settings[key];
			}
			stPortal[key] = stConfig.settings[key];
		}
	</cfscript>
	
	<!--- look for default stylesheets --->
	<cfscript>
		if ( not len(stPortal.stylesheet) ) {
			if ( fileExists("#appInstallRoot#/www/stylesheets/screen.css") ) {
				stPortal.stylesheet = "/stylesheets/screen.css";
			} else if ( fileExists("#appInstallRoot#/www/stylesheets/main.css") ) {
				stPortal.stylesheet = "/stylesheets/main.css";
			}
		}
		if ( not len(stPortal.printStylesheet) and fileExists("#appInstallRoot#/www/stylesheets/print.css") ) {
			stPortal.printStylesheet = "/stylesheets/print.css";
		}
		if ( not len(stPortal.popupStylesheet) and fileExists("#appInstallRoot#/www/stylesheets/popup.css") ) {
			stPortal.popupStylesheet = "/stylesheets/popup.css";
		}
	</cfscript>

	<!--- look for a favourite icon in the web root --->
	<cfif fileExists(appInstallRoot & fs & "www" & fs & "favicon.ico")>
		<cfset stPortal.favIcon = true>
	<cfelse>
		<cfset stPortal.favIcon = false>
	</cfif>	
	
	<cfif stPortal.rewriteEngine and len(stPortal.rewritePrefix) and not reFind("^([a-z]+(\-|/)){1,}$",stPortal.rewritePrefix)> <!--- note: allow pattern to be repeated for backwards compatibility --->
		
		<cfthrow message="Invalid rewrite prefix format."
			detail="Rewrite prefix must be a string of lower case roman letters followed by either a dash or a forward slash">
		
	</cfif>

	<!--- always pad titleSeparator with spaces --->
	<cfset stPortal.titleSeparator = " " & stPortal.titleSeparator & " ">
	
	<cfset stApp.securityZones = REReplace(stApp.securityZones,"[[:space:]]+","","all")> <!--- remove spaces from list --->
	
	<!--- create speck application config file --->
	<cfscript>
		fileContents = "[settings]" & nl;
		for ( key in stApp ) {
			fileContents = fileContents & key & " = " & stApp[key] & nl;
		}

		// allow portal apps to override default system database configuration
		if ( structKeyExists(stConfig,"database") and isStruct(stConfig.database) ) {
			fileContents = fileContents & nl & "[database]" & nl;
			for ( key in stConfig.database ) {
				fileContents = fileContents & key & " = " & stConfig.database[key] & nl;
			}
		}
	</cfscript>

	<cf_spFileWrite file="#speckInstallRoot##fs#config#fs#apps#fs##attributes.name#.app" output="#fileContents#">
	
	<!--- create directories if required --->
	<cfloop list="layouts,templates" index="dir">

		<cfif not directoryExists(appInstallRoot & fs & dir)>

			<cfdirectory action="create" directory="#appInstallRoot##fs##dir#" mode="775">

		</cfif>
		
		<!--- create an includes directory for storing included layout and template parts --->
		<cfif not directoryExists(appInstallRoot & fs & dir & fs & "includes")>

			<cfdirectory action="create" directory="#appInstallRoot##fs##dir##fs#includes" mode="775">
				
		</cfif>

	</cfloop>
	
	<!--- create directories if required --->
	<cfloop list="javascripts,stylesheets,images" index="dir">

		<cfif not directoryExists(appInstallRoot & fs & "www" & fs & dir)>

			<cfdirectory action="create" directory="#appInstallRoot##fs#www#fs##dir#" mode="775">

		</cfif>

	</cfloop>
	
	<!--- 
	Read databases config file to get DDL strings for SQL statements.
	Note that until the Speck application has initialised, we can't guarantee that settings will exist 
	because they are cfparamed during Speck application initialisation, hence the use of structKeyExists()
	--->
	<cf_spGetProfileStructure file="#speckInstallRoot##fs#config#fs#system#fs#databases.cfg" variable="stDatabases">
	
	<cfscript>
		if ( structKeyExists(stDatabases, stApp.dbType) ) {
			stDatabase = duplicate(stDatabases[stApp.dbType]);
		} else {
			stDatabase = structNew();
		}

		// timestamp DDL string
		if ( structKeyExists(stDatabase,"tsDDLString") )
			tsDDLString = stDatabase.tsDDLString;
		else
			tsDDLString = "timestamp";
			
		// integer DDL string
		if ( structKeyExists(stDatabase,"integerDDLString") )
			integerDDLString = stDatabase.integerDDLString;
		else
			integerDDLString = "integer";		
			
		// maximum index key length 
		if ( structKeyExists(stDatabase,"maxIndexKeyLength") )
			maxIndexKeyLength = stDatabase.maxIndexKeyLength;
		else
			maxIndexKeyLength = 500;						

		
		// some db related functions copied from spFunctions (with some minor modifications)
		
		function dbTableNotFound(errorMsg) {
			if ( REFindNoCase("(table|relation|object).*(unknown|invalid|not found|doesn't exist|does not exist)",errorMsg)
				or REFindNoCase("(unknown|invalid|cannot find).*(table|relation|object)",errorMsg) )
				return true;
			else
				return false;
		}
			
		function textDDLString(length) {
			
			if ( isDefined("stDatabase.varcharMaxLength") 
				and isDefined("stDatabase.longvarcharType") 
				and length gt stDatabase.varcharMaxLength ) {
				
				if ( isDefined("stDatabase.specifyLongVarcharMaxLength") and stDatabase.specifyLongVarcharMaxLength ) {
					return stDatabase.longvarcharType & "(" & length & ")";
				} else {
					return stDatabase.longvarcharType;
				}		
				
			} else if ( isDefined("stDatabase.varcharType") )	{
				
				return stDatabase.varcharType & "(" & length & ")";			
			
			} else {
			
				return "varchar(" & length & ")";
			
			}	
			
		}
	</cfscript>
	
	<cfif find("portal",stApp.securityZones)>

		<!--- create user database tables for portal security zone if required --->

		<cfset bCreateUserTables=false>
	
		<cftry>
		
			<cfquery name="qTableExists" datasource="#stApp.codb#">
				SELECT * FROM spUsers WHERE username = 'noSuchUser'
			</cfquery>
		
		<cfcatch type="Database">
	
			<cfif cfcatch.sqlstate eq "S0002" or dbTableNotFound(cfcatch.detail)> <!--- ODBC Error base table does not exist --->
			
				<cfset bCreateUserTables=true>
				
			<cfelse>
			
				<cfrethrow>
			
			</cfif>
		
		</cfcatch>
		</cftry>
		
		<cfif not bCreateUserTables>
			
			<cfif not listFindNoCase(qTableExists.columnList,"registered")>
		
				<cfquery name="qAlterUsers" datasource="#stApp.codb#">
					ALTER TABLE spUsers ADD registered #tsDDLString#
				</cfquery>
				
				<cfquery name="qUpdateUsers" datasource="#stApp.codb#">
					UPDATE spUsers SET registered = spCreated
				</cfquery>
				
			</cfif>
			
			<cfif not listFindNoCase(qTableExists.columnList,"suspended")>
		
				<cfquery name="qAlterUsers" datasource="#stApp.codb#">
					ALTER TABLE spUsers ADD suspended #tsDDLString#
				</cfquery>
				
			</cfif>

			<cfif not listFindNoCase(qTableExists.columnList,"expires")>
		
				<cfquery name="qAlterUsers" datasource="#stApp.codb#">
					ALTER TABLE spUsers ADD expires #tsDDLString#
				</cfquery>
				
			</cfif>
			
			<cfquery name="qUsersGroups" datasource="#stApp.codb#">
				SELECT * FROM spUsersGroups WHERE username = 'noSuchUser'
			</cfquery>
			
			<cfif not listFindNoCase(qUsersGroups.columnList,"expires")>
		
				<cfquery name="qAlterUsers" datasource="#stApp.codb#">
					ALTER TABLE spUsersGroups ADD expires #tsDDLString#
				</cfquery>
				
			</cfif>
		
		</cfif>
		
		<cfif bCreateUserTables>
				
			<cftransaction>
			
				<!--- 
				note: spUsers table created with columns required for a Speck content type, 
				'cos we might make it one later. Then it could be extended per application.
				--->
		 		<cfquery name="qCreateTable" datasource=#stApp.codb#>
					CREATE TABLE spUsers (
						spId CHAR(35) NOT NULL,
						spRevision #integerDDLString# NOT NULL,
						spLabel #textDDLString(50)#,
						spCreated #tsDDLString# NOT NULL,
						spCreatedby #textDDLString(20)#,
						spUpdated #tsDDLString#,
						spUpdatedby #textDDLString(20)#,
						spKeywords #textDDLString(maxIndexKeyLength)#,
						spArchived #tsDDLString#,
						spLevel #integerDDLString#,
						lastLogon #tsDDLString#,
						lastActive #tsDDLString#,
						registered #tsDDLString#,
						suspended #tsDDLString#,
						expires #tsDDLString#,
						username #textDDLString(50)# NOT NULL,
						fullname #textDDLString(100)# NOT NULL,
						password #textDDLString(100)# NOT NULL,
						email #textDDLString(100)#,
						phone #textDDLString(100)#,
						notes #textDDLString(4000)#,
						PRIMARY KEY (username)
					)
				</cfquery>
				
				<cfquery name="qAddIndex" datasource=#stApp.codb#>
					CREATE INDEX spUsers_email
					ON spUsers (email)
				</cfquery>		
				
				<cfquery name="qAddIndex" datasource=#stApp.codb#>
					CREATE INDEX spUsers_lastlogon
					ON spUsers (lastLogon)
				</cfquery>
				
		 		<cfquery name="qCreateTable" datasource=#stApp.codb#>
					CREATE TABLE spGroups (
						groupname #textDDLString(50)# NOT NULL,
						description #textDDLString(100)#,
						PRIMARY KEY (groupname)
					)
				</cfquery>
				
		 		<cfquery name="qCreateTable" datasource=#stApp.codb#>
					CREATE TABLE spUsersGroups (				
						username #textDDLString(50)# NOT NULL,
						groupname #textDDLString(50)# NOT NULL,
						expires #tsDDLString#,
						PRIMARY KEY (username,groupname)
					)
				</cfquery>				
				
		 		<cfquery name="qCreateTable" datasource=#stApp.codb#>
					CREATE TABLE spRoles (
						rolename #textDDLString(50)# NOT NULL,
						description #textDDLString(100)#,
						PRIMARY KEY (rolename)
					)
				</cfquery>			
				
		 		<cfquery name="qCreateTable" datasource=#stApp.codb#>
					CREATE TABLE spRolesAccessors (				
						rolename #textDDLString(50)# NOT NULL,
						accessor #textDDLString(50)# NOT NULL,
						PRIMARY KEY (rolename,accessor)
					)
				</cfquery>
				
				
				<!--- add default roles --->
		 		<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spRoles (rolename, description) 
					VALUES ('spSuper', 'Super user role. Has access to manage all content and everything else too.')
				</cfquery>				
				
		 		<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spRoles (rolename, description) 
					VALUES ('spEdit', 'Role required to edit content.')
				</cfquery>			
				
				 <cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spRoles (rolename, description) 
					VALUES ('spLive', 'Role required to put content live.')
				</cfquery>
				
				 <cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spRoles (rolename, description) 
					VALUES ('spKeywords', 'Role required to manage navigation keywords.')
				</cfquery>
				
				 <cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spRoles (rolename, description) 
					VALUES ('spUsers', 'Role required to manage users (spSuper is required to manage groups and roles).')
				</cfquery>
				
				
				<!--- add default groups --->
		 		<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spGroups (groupname, description) 
					VALUES ('admins', 'Administrators / super users group.')
				</cfquery>
				<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spRolesAccessors (rolename,accessor) 
					VALUES ('spSuper','admins')
				</cfquery>
				
		 		<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spGroups (groupname, description) 
					VALUES ('managers', 'Site managers group.')
				</cfquery>
				<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spRolesAccessors (rolename,accessor) 
					VALUES ('spEdit','managers')
				</cfquery>
				<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spRolesAccessors (rolename,accessor) 
					VALUES ('spLive','managers')
				</cfquery>
				<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spRolesAccessors (rolename,accessor) 
					VALUES ('spUsers','managers')
				</cfquery>
				<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spRolesAccessors (rolename,accessor) 
					VALUES ('spKeywords','managers')
				</cfquery>
				
		 		<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spGroups (groupname, description) 
					VALUES ('editors', 'Content editors group.')
				</cfquery>
				<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spRolesAccessors (rolename,accessor) 
					VALUES ('spEdit','editors')
				</cfquery>
				<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spRolesAccessors (rolename,accessor) 
					VALUES ('spLive','editors')
				</cfquery>
				<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spRolesAccessors (rolename,accessor) 
					VALUES ('spKeywords','editors')
				</cfquery>
				
				<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spGroups (groupname, description) 
					VALUES ('users', 'Web site users.')
				</cfquery>
	
	
				<!--- add a super user --->
				
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
				
				<cfset generatedPassword = makePassword()>
				
		 		<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spUsers (spId, spRevision, spCreated, spCreatedBy, registered, username, fullname, password) 
					VALUES ('#createUuid()#', 1, #createOdbcDatetime(now())#, 'spSystem', #createOdbcDatetime(now())#, 'admin', 'Admin User', '#generatedPassword#')
				</cfquery>
				
		 		<cfquery name="qInsert" datasource=#stApp.codb#>
					INSERT INTO spUsersGroups (username, groupname) 
					VALUES ('admin', 'admins')
				</cfquery>
				
				<!--- set form variables so spApp will automatically log the user on --->
				<cfset form.spLogonUser = "admin">
				<cfset form.spLogonPassword = "#generatedPassword#">
			
			</cftransaction>
			
	 		<cfoutput>
			<script type="text/javascript">
				<!--
				//<![CDATA[		
				alert("User database tables created. You will be logged in as user 'admin'.\n\nNOTE: Auto-generated password for admin user is '#generatedPassword#'.\n\nTAKE NOTE OF YOUR PASSWORD OR CHANGE IT IMMEDIATELY.");
				//]]>
				//-->
			</script>
			</cfoutput>
			
			<!--- if the default security zone deoesn't exist, let's be nice and create it --->
			<cflog type="information" 
				file="#attributes.name#" 
				application="no"
				text="CF_SPPORTAL: User database tables created. Auto-generated admin password is '#generatedPassword#'.">

		</cfif>
	
		<!--- create new newsetter subscribers table? --->
		<cftry>
			
			<cfquery name="qCheckExists" datasource="#stApp.codb#">
				SELECT * FROM spNewsletterSubscribers
				WHERE email = 'noSuchEmail'
			</cfquery>
			
		<cfcatch type="database">
		
			<cfif cfcatch.sqlstate eq "S0002" or dbTableNotFound(cfcatch.detail)>
			
				<!--- note: this is really, really simple and doesn't allow for multiple newsletters on the one application --->
				<cfquery name="qCreateTable" datasource="#stApp.codb#">
					CREATE TABLE spNewsletterSubscribers (
						fullname #textDDLString(100)#,
						email #textDDLString(100)# NOT NULL,
						PRIMARY KEY (email)
					)
				</cfquery>
				
				<!--- create indexes (note: this might look like overkill, but by putting both columns into both indexes, the dbms can return all the data from the index, without having to access the table itself) --->
				<cftry>
				
					<cfquery name="qAddIndex" datasource="#stApp.codb#">
						CREATE INDEX spNewsletterSubscribers_email
						ON spNewsletterSubscribers (email, fullname)
					</cfquery>
					
					<cfquery name="qAddIndex" datasource="#stApp.codb#">
						CREATE INDEX spNewsletterSubscribers_fullname
						ON spNewsletterSubscribers (fullname, email)
					</cfquery>
					
				<cfcatch type="database">
				
					<!--- do nothing, index name is too long or db does not allow composite indexes - either way, it's a rubbish dbms so who cares --->
				
				</cfcatch>
				</cftry>
				
			<cfelse>
			
				<cfrethrow>
			
			</cfif>
			
			<!--- attempt to insert users into newsletter subscribers table (this should work fine with Postgres, MySQL, Orable and SQL Server, not sure beyond that) --->
			<cftry>
			
				<cfquery name="qInsertNewsletterSubscribers" datasource="#stApp.codb#">
					INSERT INTO spNewsletterSubscribers (fullname, email) 
					SELECT fullname, email FROM spUsers WHERE email IS NOT NULL AND newsletter = 1 AND registered IS NOT NULL AND suspended IS NULL
				</cfquery>

			<cfcatch type="database">
				
				<!--- the first insert might have failed due to a primary key constraint violation (the email column of the spUsers table is not unique - most of the code enforces uniqueness, but there's no guarantee) --->
				<cftry>
				
					<cfquery name="qInsertNewsletterSubscribers" datasource="#stApp.codb#">
						INSERT INTO spNewsletterSubscribers (email) 
						SELECT DISTINCT(email) FROM spUsers WHERE email IS NOT NULL AND newsletter = 1 AND registered IS NOT NULL AND suspended IS NULL
					</cfquery>
					
				<cfcatch type="database">
				
					<!--- do nothing, insert into select doesn't seem to work on this dbms --->
				
				</cfcatch>
				</cftry>
			
			</cfcatch>
			</cftry>
			
		</cfcatch>
		</cftry>
		
	</cfif>

	<!--- load speck application --->
	<cf_spApp attributeCollection="#attributes#">
	
	<!--- set the password encryption for the portal security zone (this is a hack to allow a single portal security zone support different encryption settings per application) --->
	<cfif find("portal",stApp.securityZones)>
	
		<cflock scope="application" timeout="3" type="exclusive">
		<cfset application.speck.securityZones.portal.users.options.encryption = stPortal.passwordEncryption>
		</cflock>
		
	</cfif>
	
	<cfif not len(trim(stPortal.domain))>
	
		<!--- derive domain name from host name - note: this code is here, after spApp, because we use the getDomainFromHost() name function from spFunctions --->
		<cfset stPortal.domain = request.speck.getDomainFromHostName()>
	
	</cfif>
	
	<cfif request.speck.qKeywords.recordCount eq 0>
	
		<!--- insert the default keyword --->
		<cfscript>
			stNewKeyword = structNew();
			stNewkeyword.keyword = "home";
			stNewKeyword.name = "Home";
			stNewKeyword.title = stPortal.name;
			stNewKeyword.href = "#stApp.appWebRoot#/";
			stNewKeyword.spMenu = 1;
			stNewKeyword.spSitemap = 1;
		</cfscript>
		<cf_spContentPut
			stContent = #stNewkeyword#
			type="spKeywords"
			user="spSystem">
		
	</cfif>
	
	<!--- save portal configuration in application scope --->
	<cflock scope="application" type="exclusive" timeout="5">
	<cfset application.speck.portal = duplicate(stPortal)>
	</cflock>
	
	<!--- if super user refreshed app using toolbar option, notify user that application has been refreshed and return to referrer --->
	<cfif isDefined("url.refreshapp")>
	
		<cfif len(cgi.http_referer)>
			<cfset location = cgi.http_referer>
		<cfelse>
			<cfset location = "#request.speck.appWebRoot#/">
		</cfif>
	
		<cfoutput>
		<script type="text/javascript">
			<!--
			//<![CDATA[		
			if ( confirm("Application '#attributes.name#' has been refreshed\n\nReturn to previous page?") )
				window.location.replace("#location#");
			//]]>
			//-->
		</script>
		</cfoutput>
		<cfabort>
		
	</cfif>		
	
<cfelse>

	<!--- always call spApp, passing all attributes --->
	<cf_spApp attributeCollection="#attributes#">
	
</cfif>

<!--- copy application.speck.portal into request scope for every request --->
<cflock scope="application" type="readonly" timeout="5">
<cfset request.speck.portal = duplicate(application.speck.portal)>
</cflock>

<!--- cache control header (not sure about this, need to do a bit of reading ;-) --->
<cfheader name="Cache-Control" value="private, no-cache, must-revalidate">

<!--- 
debugging code, something is removing session keys and I don't know what.
update: I found it, a logout script wasn't deleting the speck key from session scope (speck updated to deal with this)
			I might use this code again though, that trace idea was pretty useful.
--->
<!--- <cflock scope="session" type="exclusive" timeout="3">
<cfscript>
	if ( not structKeyExists(session,"trace") ) {
		session.trace = arrayNew(1);
	}
	requestedUrl = request.speck.getCleanRequestedPath();
	queryString = request.speck.getCleanQueryString();
	if ( len(queryString) ) {
		requestedUrl = requestedUrl & "?" & queryString;
	}
	arrayPrepend(session.trace,requestedUrl);
	if ( arrayLen(session.trace) gt 50 ) {
		arrayDeleteAt(session.trace,arrayLen(session.trace));
	}
</cfscript>
</cflock>
<cfset keyMissingMessage = "">
<cfif not structKeyExists(request,"speck")>
	<cfset keyMissingMessage = "key 'speck' not found in request">
<cfelseif not structKeyExists(request.speck,"session")>
	<cfset keyMissingMessage = "key 'session' not found in request.speck">
<cfelseif not structKeyExists(request.speck.session,"securityZone")>
	<cfset keyMissingMessage = "key 'securityZone' not found in request.speck.session">
</cfif>
<cfif len(keyMissingMessage)>

	<cfmail to="***********" from="***************" subject="CF_SPPORTAL: #keyMissingMessage#" type="html">Speck Session:<cfdump var="#session.speck#"><br/>Session Trace:<cfdump var="#session.trace#"></cfmail>

	<cfset void = structDelete(session,"speck")>
	<cfset void = structDelete(session,"trace")>
		
</cfif> --->

<cfif request.speck.session.securityZone eq "portal">

	<cfif isDefined("form.spLogonUser") and isDefined("form.spLogonPassword")>
	
		<!--- check if logon is blocked due too many recent authentication failures --->
		<!--- 
		Some possible TODOs: 
		* configuration options for thresholds, at the moment it's hard-coded as 5 failures within 5 minutes
		* ability to set whitelist IPs or immediately reset failure count to 0 after completing a captcha
		* separately check for failed logons from IPs and failed logons for particular users and have different thresholds for each?
		--->
		<cfset recentLogonFailureCount = 0>
		
		<cftry>
			
			<cfquery name="qRecentLogonFailures" datasource="#request.speck.codb#">
				SELECT COUNT(*) AS total
				FROM spLogonFailures
				WHERE ts > <cfqueryparam cfsqltype="cf_sql_timestamp" value="#dateAdd("n",-5,now())#"> 
					AND username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(request.speck.session.user)#"> 
					AND ip_address = <cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.REMOTE_ADDR#">
			</cfquery>
			
			<cfset recentLogonFailureCount = qRecentLogonFailures.total>
			
		<cfcatch type="database">
		
			<!--- let the code to log the logon failures create the table, rethrow any non table not found errors --->
			
			<cfif not request.speck.dbTableNotFound(cfcatch.detail)>	
			
				<cfrethrow>
				
			</cfif>
			
		</cfcatch>			
		</cftry>
		
		<cfif recentLogonFailureCount gte 5>
		
			<!--- too many recent authentication failures --->
			<cfset session.speck.auth = "none">
			<cfset request.speck.session.auth = "none">
			<cfset request.speck.failedLogon = true>
			<cfset request.speck.failedLogonMessage = "Too many recent authentication failures, your account has temporarily been locked. Try again in 5 minutes.">
			
			<cflog type="warning" 
				file="#request.speck.appName#" 
				application="no"
				text="CF_SPPORTAL: Too many recent authentication failures. Logon denied to user '#request.speck.session.user#' from IP '#cgi.REMOTE_ADDR#'.">	
	
		<cfelseif request.speck.session.auth neq "logon">
		
			<!--- log authentication failures --->
			<cftry>
				
				<cfquery name="qInsertLogonFailure" datasource="#request.speck.codb#">
					INSERT INTO spLogonFailures (
						username, 
						ip_address, 
						ts
					) VALUES (
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(request.speck.session.user)#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.REMOTE_ADDR#">,
						<cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">
					)
				</cfquery>
				
				<!--- clean up the logon failures table --->
				<cfquery name="qDeleteLogonFailures" datasource="#request.speck.codb#">
					DELETE FROM spLogonFailures 
					WHERE ts < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#dateAdd("d",-1,now())#"> 
				</cfquery>
			
			<cfcatch type="database">
			
				<cfif cfcatch.sqlstate eq "S0002" or request.speck.dbTableNotFound(cfcatch.detail)>
				
					<!--- note: no primary key (Speck doesn't know how to create serial/auto-increment columns for all dbmss and we can't guarantee username, ip and time stamp to be unique) --->
					<cfquery name="qCreateTable" datasource="#request.speck.codb#">
						CREATE TABLE spLogonFailures (
							username #request.speck.textDDLString(100)#,
							ip_address #request.speck.textDDLString(100)#,
							ts #request.speck.database.tsDDLString# NOT NULL
						)
					</cfquery>
					
					<!--- just add one index, this table could get hammered --->
					<cfquery name="qAddIndex" datasource="#request.speck.codb#">
						CREATE INDEX spLogonFailures_ts
						ON spLogonFailures (ts)
					</cfquery>
	
				<cfelse>
				
					<cfrethrow>
				
				</cfif>
	
			</cfcatch>
			</cftry>
		
		<cfelse>

			<!--- authentication successful - check that user has completed registration and account has not expired or been suspended --->
			<cfquery name="qCheckUser" datasource="#request.speck.codb#">
				SELECT registered, suspended, expires
				FROM spUsers 
				WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(request.speck.session.user)#">
			</cfquery>
			
			<cfif not isDate(qCheckUser.registered) and structIsempty(request.speck.session.groups)>
			
				<!--- registration hasn't been completed --->
				<cfset session.speck.auth = "none">
				<cfset request.speck.session.auth = "none">
				<cfset request.speck.failedLogon = true>
				<cfset request.speck.failedLogonMessage = "Registration has not been completed.">
				
				<cflog type="warning" 
					file="#request.speck.appName#" 
					application="no"
					text="CF_SPPORTAL: User '#request.speck.session.user#' has not completed registration. Setting auth level to 'none' and failedLogon flag to true.">
			
			<cfelseif isDate(qCheckUser.suspended)>
			
				<!--- user has been suspended --->
				<cfset session.speck.auth = "none">
				<cfset request.speck.session.auth = "none">
				<cfset request.speck.failedLogon = true>
				<cfset request.speck.failedLogonMessage = "Your account has been suspended.">
				
				<cflog type="warning" 
					file="#request.speck.appName#" 
					application="no"
					text="CF_SPPORTAL: User '#request.speck.session.user#' has been suspended. Setting auth level to 'none' and failedLogon flag to true.">
					
			<cfelseif isDate(qCheckUser.expires) and now() gt qCheckUser.expires>
			
				<!--- account has expired --->
				<cfset session.speck.auth = "none">
				<cfset request.speck.session.auth = "none">
				<cfset request.speck.failedLogon = true>
				<cfset request.speck.failedLogonMessage = "Your account has expired.">
				
				<cflog type="warning" 
					file="#request.speck.appName#" 
					application="no"
					text="CF_SPPORTAL: User account '#request.speck.session.user#' has expired. Setting auth level to 'none' and failedLogon flag to true.">
			
			</cfif>

			<cfif request.speck.session.auth eq "logon">
			
				<!--- user remains logged on after various checks, updated last logon and last active timestamps --->
		
				<cftry>
					
					<cfquery name="qUpdateLastLogon" datasource="#request.speck.codb#">
						UPDATE spUsers 
						SET lastLogon = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#createODBCDateTime(now())#"> 
						WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(request.speck.session.user)#">
					</cfquery>
				
				<cfcatch>
				
					<cfquery name="qTableCheck" datasource="#request.speck.codb#">
						SELECT * FROM spUsers WHERE spId = 'noSuchId'
					</cfquery>
					
					<cfif not listFindNoCase(qTableCheck.columnList, "lastLogon")>
			
						<cfquery name="qAlterUsers" datasource="#request.speck.codb#">
							ALTER TABLE spUsers ADD lastLogon #request.speck.database.tsDDLString#
						</cfquery>
						
						<cfquery name="qAddIndex" datasource="#request.speck.codb#">
							CREATE INDEX spUsers_lastLogon
							ON spUsers (lastLogon)
						</cfquery>
	
						
					<cfelse>
					
						<cfrethrow>
						
					</cfif>
											
				</cfcatch>
				</cftry>
				
				<!--- track user activity --->
				<cfif request.speck.portal.trackUserActivity>
				
					<!--- note: only update the db every 90 seconds --->
					<cfif not structKeyExists(request.speck.session,"lastActive") or 
						( structKeyExists(request.speck.session,"lastActive") and dateDiff("s",request.speck.session.lastActive,now()) gt 90 )>
					
						<cftry>
						
							<cfquery name="qUpdateLastActive" datasource="#request.speck.codb#">
								UPDATE spUsers 
								SET lastActive = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#createODBCDateTime(now())#">
								WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(request.speck.session.user)#">
							</cfquery>
							
						<cfcatch>
						
							<cfquery name="qTableCheck" datasource="#request.speck.codb#">
								SELECT * FROM spUsers WHERE spId = 'noSuchId'
							</cfquery>
							
							<cfif not listFindNoCase(qTableCheck.columnList, "lastActive")>
					
								<!--- note: frequently updated column, do not index! --->
								<cfquery name="qAlterUsers" datasource="#request.speck.codb#">
									ALTER TABLE spUsers ADD lastActive #request.speck.database.tsDDLString#
								</cfquery>
								
							<cfelse>
							
								<cfrethrow>
								
							</cfif>
									
						</cfcatch>
						</cftry>
						
						<cflock scope="session" type="exclusive" timeout="3">
						<cfif structKeyExists(session,"speck") and isStruct(session.speck) and not structIsEmpty(session.speck)>
							<cfset session.speck.lastActive = now()>
						</cfif>
						</cflock>
						
					</cfif>
				
				</cfif>						
				
			</cfif> <!--- end code to update last logon and last active --->
			
		</cfif> <!--- check if logon succeeded --->
			
	</cfif> <!--- check if logon form posted  --->

</cfif> <!--- check for portal security zone --->

<!--- Search Engine Safe URL stuff - taken wholesale from SESConverter tag by the people at fusium.com --->
<!--- NOTE: I have tried to contact the copyright owners to ask for permission to include this, but never got any reply, I'm assuming there's no problem --->
<cfscript>
currentPath = cgi.script_name & replace(cgi.path_info,cgi.script_name,"");
dummyExtension = request.speck.sesSuffix;
emptyString = "null"; 

/* only do stuff if currentPath has len, otherwise it breaks the RemoveChars() function */
if (Len(currentPath)) {

	/* replace any ?,&,= characters that are in the url for some reason */
	cleanpathinfo=REReplace(currentPath, "\&|\=", "/" ,"ALL");

	/* get everything after the first occurence of ".XXX/",
	   where XXX is .cfm, or whatever you use for your templates 
	   In other words, get the query string */	
	cleanpathinfo=RemoveChars(cleanpathinfo,1,Find("/",cleanpathinfo,Find(".",cleanpathinfo,1)));

	/* If it's a SES url, do all the crunching.  If not, skip it */
	if (Len(cleanpathinfo) AND cleanpathinfo NEQ CGI.Script_Name) {
		
		// Remove fake file extension, pass empty value to skip this  
		if (Len(dummyextension)) {
			if (Right(cleanpathinfo,Len(dummyextension)) IS dummyextension) {
				cleanpathinfo = Left(cleanpathinfo,Len(cleanpathinfo)-Len(dummyextension));
			}
		}
		//cleanpathinfo = reReplaceNoCase(cleanpathinfo,"\.htm(l)?$","");

		// add a null value if there is a trailing slash
		if (Right(cleanpathinfo,1) IS '/') {
			cleanpathinfo = cleanpathinfo & emptyString;
		}
		
		//add null values between adjacent slashes
		cleanpathinfo = Replace(cleanpathinfo,"//","/" & emptyString & "/","all");

		// get a copy of anything in the url scope
		originalURL = Duplicate(url);

	 	SlashLen = ListLen(cleanpathinfo,"/");
		for (i=1; i LTE SlashLen; i=i+2) {
			/* get this item from the list into the local var i */
			urlname = ListGetAt(cleanpathinfo, i, '/');
			if (i LT SlashLen) {
				urlvalue = ListGetAt(cleanpathinfo, i+1, '/');
				urlvalue = replacenocase(urlvalue,"slash_","/","all");
				if (urlvalue IS emptyString) { 
					urlvalue = "";
				}
				StructInsert(url, urlname, urlvalue, true); 
			}
		}

		// return stuff that was in the url scope originally
		StructAppend(url,originalURL,true);
	}
}
</cfscript>

<!--- check for a keyword in input parameters (note automatic replacement of dash with dot in input) --->
<cfif structKeyExists(url,"spKey")>

	<cfset variables.spKey = replace(url.spKey,chr(45),".","all")>
	
<cfelseif structKeyExists(form,"spKey")>

	<cfset variables.spKey = replace(form.spKey,chr(45),".","all")>
	
<cfelseif structKeyExists(url,"spPath")>

	<!--- code to handle new rewrite engine url format - rewrite engine passes the path as spPath querystring param --->

	<!--- some notes...
	* First part of the path should match a keyword and it may be followed by an id and some other info.
	* If nothing in the path matches a keyword, the keyword is set to "noSuchKeyword" so spPage will produce a 404 response. 
	* The first part of the path which doesn't match a keyword will be set as the value of url.spId, on the 
	  assumption that it either is an spId or something that can be used to uniquely identify a content item. 
	  Templates can choose to ignore this value if it is not a real UUID. The getDisplayMethodUrl() function
	  will generate URLs that conform to this, but there is no requirement that templates and content types 
	  follow this convention.
	* If the path ends in the sesSuffix (usually .html), the final element in the path is assumed to represent an identifier for a content item.  
	* The entire path, as passed along by mod_rewrite, will always be available as url.spPath to all 
	  templates. Templates can use this value to determine what action is to be taken. 
	--->
	
	<cfscript>
		path = url.spPath;
		if ( left(path,1) eq "/" ) { path = replace(path,"/","","one"); }
		if ( right(path,1) eq "/" ) { path = left(path,len(path)-1); }
		if ( len(request.speck.sesSuffix) and reFind("\#request.speck.sesSuffix#$",path) ) {
			// when rewrite engine is enabled, the sesSuffix is only appended when viewing a content item, so we know the last item in the path is an identifier of some sort
			path = reReplaceNoCase(path,"\#request.speck.sesSuffix#$","");
			url.spId = listLast(path,"/");
			path = listDeleteAt(path,listLen(path,"/"),"/");
		} else {
			// assume that any trailing .htm or .html suffix is a dummy suffix
			// possible TODO: just remove any suffixes from url.spPath??
			path = reReplaceNoCase(path,"\.htm(l)?$","");
		}  
	</cfscript>
	
	<!--- look for a keyword in the path --->
	<cfloop condition="#listLen(path,"/")# gt 0">
	
		<cfquery name="qKeyword" dbtype="query">
			SELECT * FROM request.speck.qKeywords
			WHERE keyword = '#replace(path,"/",".","all")#'
		</cfquery>
		
		<cfif qKeyword.recordCount>
		
			<cfset variables.spKey = replace(path,"/",".","all")>
					
			<cfbreak>
			
		<cfelse>
		
			<cfset url.spId = listLast(path,"/")>
			<cfset path = listDeleteAt(path,listLen(path,"/"),"/")>
		
		</cfif>
	
	</cfloop>
	
	<cfif not structKeyExists(variables,"spKey")>
	
		<cfset variables.spKey = "noSuchKeyword">
	
	</cfif>
	
	<cfset url.spKey = variables.spKey>

<cfelse>

	<!--- use the default keyword --->
	<cfset variables.spKey = "home">
	
</cfif>

<!--- 
get keyword info into request scope 
note: the spPage tag is responsible for checking if a keyword/page was found
--->
<cfquery name="qKeyword" dbtype="query">
	SELECT * 
	FROM request.speck.qKeywords
	WHERE 
		<cfif isNumeric(variables.spKey)>
			keyId = #variables.spKey#
		<cfelse>
			keyword = '#variables.spKey#'
		</cfif> 
</cfquery>

<!--- now set up the page structure for the current request --->
<cfscript>
request.speck.page = structNew();
request.speck.page.keyword = qKeyword.keyword;
request.speck.page.qKeyword = duplicate(qKeyword);

if ( len(request.speck.page.qKeyword.title) ) {
	request.speck.page.title = request.speck.page.qKeyword.title;	
} else {
	request.speck.page.title = request.speck.page.qKeyword.name;	
}
request.speck.page.description = request.speck.page.qKeyword.description;
request.speck.page.keywords = request.speck.page.qKeyword.keywords;
if ( len(request.speck.page.qKeyword.template) ) {
	request.speck.page.template = request.speck.page.qKeyword.template;
} else {
	request.speck.page.template = request.speck.portal.template;	
}
if ( len(request.speck.page.qKeyword.layout) ) {
	request.speck.page.layout = request.speck.page.qKeyword.layout;
} else {
	request.speck.page.layout = request.speck.portal.layout;	
}
request.speck.page.cacheKeyword = replace(request.speck.page.keyword,".","_","all");
// copy vars in request.speck.page to request.speck.portal for backwards compatibility
for ( key in request.speck.page ) {
	request.speck.portal[key] = request.speck.page[key];	
}
// copy the friendly name to request.speck.page after the backwards compatibility code to avoid clashing with the portal/site name
request.speck.page.name = request.speck.page.qKeyword.name;
</cfscript>

<!--- build an array of breadcrumbs and set the keywordSeparator to be used when building ses urls --->
<cfscript>
	breadcrumbsSesSuffix = request.speck.sesSuffix;
	if ( request.speck.portal.rewriteEngine ) {
		breadcrumbsBasePath = "#request.speck.appWebRoot#/#request.speck.portal.rewritePrefix#";
		if ( len(request.speck.portal.rewritePrefix) and right(request.speck.portal.rewritePrefix,1) eq "-" ) {
			request.speck.portal.keywordSeparator = "-";
		} else {
			request.speck.portal.keywordSeparator = "/";
			breadcrumbsSesSuffix = ""; // we never add the sesSuffix when looking at a site section as opposed to a content item
		}
	} else {
		breadcrumbsBasePath = "#cgi.script_name#/spKey/";
		request.speck.portal.keywordSeparator = ".";
	}
	
	// create the breadcrumbs array as an ArrayList object because we'll need to create two references to it (for backwards compatibility purposes)
	request.speck.page.breadcrumbs = createObject("java","java.util.ArrayList").init();
	request.speck.portal.breadcrumbs = request.speck.page.breadcrumbs;
	
	function appendBreadcrumb(href,caption) {
		var title = caption;
		if ( arrayLen(arguments) gt 2 ) { title = arguments[3]; }
		stBreadcrumb = structNew();
		stBreadcrumb.caption = caption;
		stBreadcrumb.title = title;
		stBreadcrumb.href = href;
		arrayAppend(request.speck.portal.breadcrumbs,stBreadcrumb);
	}
			
	request.speck.portal.appendBreadcrumb = appendBreadcrumb;
</cfscript>

<cfif request.speck.portal.qKeyword.recordCount>

	<cfif listFirst(request.speck.portal.keyword,".") neq "home">
	
		<!--- always add a link to the homepage --->
	
		<cfquery name="qKeyword" dbtype="query">
			SELECT * FROM request.speck.qKeywords
			WHERE keyword = 'home'
		</cfquery>
		
		<cfscript>
			thisCaption = qKeyword.name;
			thisKeyword = "home";
			if ( len(qKeyword.tooltip) )
				thisTitle = qKeyword.tooltip;
			else if ( len(qKeyword.title) )
				thisTitle = qKeyword.title;
			else
				thisTitle = qKeyword.name;
			if ( len(qKeyword.href) )
				thisHref = qKeyword.href;
			else 
				thisHref = "#breadcrumbsBasePath##thisKeyword##breadcrumbsSesSuffix#";

			appendBreadcrumb(thisHref,thisCaption,thisTitle);
		</cfscript>
		
	</cfif>
	
	<cfset parent = "">
	<cfset keywordLength = listLen(request.speck.portal.keyword,".")>
	<cfloop from="1" to="#keywordLength#" index="i">
		
		<cfscript>
			item = listGetAt(request.speck.portal.keyword,i,".");
			if ( len(parent) )
				keyword = parent & "." & item;
			else
				keyword = item;
		</cfscript>
		
		<cfquery name="qKeyword" dbtype="query">
			SELECT * FROM request.speck.qKeywords
			WHERE keyword = '#keyword#'
		</cfquery>
		
		<cfscript>
			thisCaption = qKeyword.name;
			thisKeyword = replace(keyword,".",request.speck.portal.keywordSeparator,"all");
			if ( len(qKeyword.tooltip) )
				thisTitle = qKeyword.tooltip;
			else if ( len(qKeyword.title) )
				thisTitle = qKeyword.title;
			else
				thisTitle = qKeyword.name;
			if ( len(qKeyword.href) )
				thisHref = qKeyword.href;
			else
				thisHref = "#breadcrumbsBasePath##thisKeyword##breadcrumbsSesSuffix#";

			appendBreadcrumb(thisHref,thisCaption,thisTitle);
			
			parent = keyword;
		</cfscript>
		
	</cfloop>

</cfif>

<!--- add a function to generate a url for the current keyword (or any keyword provided as an argument), we often need this within templates --->
<cfscript>
	function getKeywordUrl() {
		var keyword = request.speck.page.keyword;
		var keywordUrl = "";
		if ( arrayLen(arguments) ) {
			keyword = arguments[1];	
		}
		if ( request.speck.portal.rewriteEngine ) {
			keywordUrl = "/" & request.speck.portal.rewritePrefix;
		} else {
			keywordUrl = cgi.script_name & "/spKey/";
		}
		keywordUrl = keywordUrl & replace(request.speck.page.keyword,".",request.speck.portal.keywordSeparator,"all");
		if ( not request.speck.portal.rewriteEngine ) {
			keywordUrl = keywordUrl & request.speck.sesSuffix;
		}
		return keywordUrl;
	}
	request.speck.portal.getKeywordUrl = getKeywordUrl;
</cfscript>

