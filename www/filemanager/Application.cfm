<cfinclude template="../Application.cfm">

<cfparam name="request.speck.portal.fileManager" default="false" type="boolean">
<cfparam name="request.speck.portal.fileManagerUsers" default="">
<cfparam name="request.speck.portal.fileManagerIps" default="">
<cfset request.speck.portal.fileManagerIps = reReplace(request.speck.portal.fileManagerIps,"[[:space:]]+","","all")>

<!--- To use the file manager, must have spSuper role AND be in the list of file manager users or be accessing from list of allowed ips --->
<!--- probable TODO: add a new spDeveloper role and require that role rather than spSuper --->

<cfif not request.speck.portal.fileManager
	or not request.speck.userHasPermission("spSuper")
	or not ( listFindNoCase(request.speck.portal.fileManagerUsers,request.speck.session.user) or listFindNoCase(request.speck.portal.fileManagerIps,cgi.REMOTE_ADDR) )>

        <cfif request.speck.session.auth eq "logon">

                <cfoutput><h1>Access Denied</h1></cfoutput>
                <cfabort>

        <cfelse>

                <cfset url.redirect_to = cgi.script_name & "?" & cgi.query_string>
                <cfinclude template="/speck/../www/login.cfm">
                <cfabort>

        </cfif>

</cfif>