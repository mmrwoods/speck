<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfparam name="url.groupname" default="">

<!--- check that at least one other group will have spSuper role after this deletion --->
<cfquery name="qSuperGroups" datasource="#request.speck.codb#">
	SELECT accessor 
	FROM spRolesAccessors 
	WHERE rolename = 'spSuper'
		AND accessor <> '#url.groupname#'
</cfquery>

<cfif not qSuperGroups.recordCount>

	<!--- there will be no super groups after this update, barf! --->
	<cfset message = "Delete group '#url.groupname#' failed">
	<cfset detail = "Cannot delete the only remaining group with spSuper role.">
	<cfset refresh = "no">

<cfelse>

	<!--- delete from users/groups relationship table --->
	<cfquery name="qDelete" datasource="#request.speck.codb#">
		DELETE FROM spUsersGroups WHERE groupname = '#trim(url.groupname)#'
	</cfquery>
	
	<!--- delete from group/roles relationship table --->
	<cfquery name="qDelete" datasource="#request.speck.codb#">
		DELETE FROM spRolesAccessors WHERE accessor = '#trim(url.groupname)#'
	</cfquery>
	
	<!--- delete from groups table --->
	<cfquery name="qDelete" datasource="#request.speck.codb#">
		DELETE FROM spGroups WHERE groupname = '#trim(url.groupname)#'
	</cfquery>

	<cfset message = "Group '#url.groupname#' deleted">
	<cfset detail = "">
	<cfset refresh = "yes">

</cfif>

<cflocation url="action_response.cfm?app=#url.app#&message=#urlEncodedFormat(message)#&detail=#urlEncodedFormat(detail)#&location=#urlEncodedFormat(cgi.http_referer)#&refresh=#refresh#" addToken="no">
