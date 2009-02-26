<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfinclude template="../Application.cfm">

<cfif request.speck.session.auth neq "logon" or not structKeyExists(request.speck.session, "roles") or structIsEmpty(request.speck.session.roles)>
	
	<cfheader statuscode="403" statustext="Access Denied">
	<!--- <cf_spError error="ACCESS_DENIED" throwException="no"> --->
	
	<cfoutput>
	<h1>#listFirst(request.speck.buildString("ERR_ACCESS_DENIED"),".")#</h1>
	#listRest(request.speck.buildString("ERR_ACCESS_DENIED"),".")#
	</cfoutput>
	<cfabort>
	
</cfif>
	
	
