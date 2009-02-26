<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfparam name="url.username" default="">

<!--- check that there will be at least one user with spSuper role following this deletion --->
<cfquery name="qSuperUsers" datasource="#request.speck.codb#">
	SELECT username 
	FROM spUsersGroups 
	WHERE groupname IN (
		SELECT accessor FROM spRolesAccessors WHERE rolename = 'spSuper'
	)
	AND username <> '#url.username#'
</cfquery>

<cfif not qSuperUsers.recordCount>

	<!--- there will be no super users after this update, barf! --->
	<cfset message = "Delete user '#url.username#' failed">
	<cfset detail = "Cannot delete the only remaining user with spSuper role.">
	<cfset refresh = "no">
	
<cfelse>

	<cfquery name="qUser" datasource="#request.speck.codb#">
		SELECT * FROM spUsers WHERE username = '#trim(url.username)#'
	</cfquery>
	
	<!--- delete from users/groups relationship table --->
	<cfquery name="qDelete" datasource="#request.speck.codb#">
		DELETE FROM spUsersGroups WHERE username = '#trim(url.username)#'
	</cfquery>
	
	<!--- delete from users table --->
	<!--- <cfquery name="qDelete" datasource="#request.speck.codb#">
		DELETE FROM spUsers WHERE username = '#trim(url.username)#'
	</cfquery> --->
	<cf_spDelete type="spUsers" id="#qUser.spId#">
	
	<cflog application="no" file="#request.speck.appName#" type="information" text="User '#qUser.username#', id '#qUser.spId#', deleted from spUsers and spUsersGroups tables.">
			 
	<cfset message = "User '#url.username#' deleted">
	<cfset detail = "">
	<cfset refresh = "yes">

</cfif>


<cflocation url="action_response.cfm?app=#url.app#&message=#urlEncodedFormat(message)#&detail=#urlEncodedFormat(detail)#&location=#urlEncodedFormat(cgi.http_referer)#&refresh=#refresh#" addToken="no">
