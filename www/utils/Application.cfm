<cfinclude template="../Application.cfm">

<cfif request.speck.session.auth neq "logon" or not request.speck.userHasPermission("spSuper")>

	<cf_spError error="ACCESS_DENIED">
	
</cfif>