<cfsetting enablecfoutputonly="true">

<!--- note: this script is subject to change - if you want to use it, copy it somewhere --->

<!--- TODO: update me to force a proper http error response when an error occurs (damn, I fscking hate coldfusion sometimes) --->
<!--- I've made a stab at this. (Stephen) --->
<cftry>

<cfif cgi.remote_addr neq "127.0.0.1" and not request.speck.userHasPermission("spSuper,spLive")>
	
	<cfheader statuscode="403" statustext="Access Denied">
	
	<cfoutput>
	<h1>Access Denied</h1>
	</cfoutput>
	<cfabort>
		
</cfif>

<cfparam name="request.speck.portal.verityLanguage" default="uni">

<cfif hour(now()) lte 6>
	<cfparam name="url.action" default="refresh">
<cfelse>
	<cfparam name="url.action" default="update">
</cfif>

<cftry>

	<cfset path = request.speck.appInstallRoot & request.speck.fs & "collections">
	
	<cfif not directoryExists(path)>

		<cftry>
			<cfdirectory action="CREATE" directory="#path#" mode="775">
		<cfcatch>
			<cf_spError error="DIR_NO_CREATE" lParams="#path#">
		</cfcatch>
		</cftry>

	</cfif>

	<cfcollection action="create" 
		path="#path#" 
		collection="#request.speck.appName#"
		language="#request.speck.portal.verityLanguage#">
		
<cfcatch><!--- do nothing ---></cfcatch>
</cftry>

<cfswitch expression="#request.speck.dbtype#">

	<cfcase value="oracle">
		
		<cfquery name="qContentIndex" datasource="#request.speck.codb#">
			SELECT x.groups, y.id, y.body, y.title, 
				y.contentType || ',' || TO_CHAR(y.ts, 'YYYY-MM-DD') || ',' || y.description AS custom1, 
				y.keyword || ',' || NVL(x.groups,'public') AS custom2
				<cfif listFirst(request.speck.cfVersion,",.") gte 7>
					, y.ts AS custom3
					, 'reserved for metadata' AS custom4
				</cfif>
			FROM spKeywords x, spContentIndex y
			WHERE x.keyword = y.keyword
		</cfquery>
		
	</cfcase>
	
	<cfcase value="postgresql">
		
		<cfquery name="qContentIndex" datasource="#request.speck.codb#">
			SELECT x.groups, y.id, y.body, y.title, 
				y.contentType || ',' || TO_CHAR(y.ts, 'YYYY-MM-DD') || ',' || y.description AS custom1, 
				y.keyword || ',' || COALESCE(x.groups,'public') AS custom2
				<cfif listFirst(request.speck.cfVersion,",.") gte 7>
					, y.ts AS custom3
					, 'reserved for metadata' AS custom4
				</cfif>
			FROM spKeywords x, spContentIndex y
			WHERE x.keyword = y.keyword
		</cfquery>
		
	</cfcase>
	
	<cfdefaultcase>
		
		<cfthrow message="Unknown database type." detail="The #request.speck.dbtype# datasource '#request.speck.codb#' is not supported by the content indexing script.">
		
	</cfdefaultcase>


</cfswitch>

<!--- index content --->

<cflock name="verity_#request.speck.appName#" type="exclusive" timeout="10" throwontimeout="true">

<cfif listFirst(request.speck.cfVersion,",.") gte 7>

	<cfindex collection="#request.speck.appName#"
		action="#url.action#"
		type="custom"
		query="qContentIndex"
		body="body"
		key="id"
		title="title"
		custom1="custom1"
		custom2="custom2"
		custom3="custom3"
		custom4="custom4"
		language="#request.speck.portal.verityLanguage#">
		
<cfelse>

	<cfindex collection="#request.speck.appName#"
		action="#url.action#"
		type="custom"
		query="qContentIndex"
		body="body"
		key="id"
		title="title"
		custom1="custom1"
		custom2="custom2"
		language="#request.speck.portal.verityLanguage#">
	
</cfif>
	
</cflock>


<cfcatch>
	<cfheader statuscode="500" statustext="Internal Server Error">
	<!--- Dump some diagnostic information --->
	<cfdump var=#cfcatch#>
	<cfabort>
</cfcatch>
</cftry>
