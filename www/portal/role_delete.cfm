<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfparam name="url.rolename" default="">

<cfif listFindNoCase("spSuper,spLive,SpEdit,spKeywords",url.rolename)>

	<cfset message = "Delete role '#url.rolename#' failed">
	<cfset detail = "Cannot delete reserved Speck roles.">
	<cfset refresh = "no">

<cfelse>
	
	<!--- delete from group/roles relationship table --->
	<cfquery name="qDelete" datasource="#request.speck.codb#">
		DELETE FROM spRolesAccessors WHERE rolename = '#trim(url.rolename)#'
	</cfquery>
	
	<!--- delete from roles table --->
	<cfquery name="qDelete" datasource="#request.speck.codb#">
		DELETE FROM spRoles WHERE rolename = '#trim(url.rolename)#'
	</cfquery>

	<cfset message = "Role '#url.rolename#' deleted">
	<cfset detail = "">
	<cfset refresh = "yes">

</cfif>

<cflocation url="action_response.cfm?app=#url.app#&message=#urlEncodedFormat(message)#&detail=#urlEncodedFormat(detail)#&location=#urlEncodedFormat(cgi.http_referer)#&refresh=#refresh#" addToken="no">
