<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfinclude template="../Application.cfm">

<cfif not request.speck.userHasPermission("spSuper,spLive") and 
	not ( cgi.script_name eq "/speck/portal/index_content.cfm" and cgi.remote_addr eq "127.0.0.1" )>
	
	<cfheader statuscode="403" statustext="Access Denied">
	<!--- <cf_spError error="ACCESS_DENIED" throwException="no"> --->
	
	<cfoutput>
	<h1>#listFirst(request.speck.buildString("ERR_ACCESS_DENIED"),".")#</h1>
	#listRest(request.speck.buildString("ERR_ACCESS_DENIED"),".")#
	</cfoutput>
	<cfabort>
		
</cfif>

<cfscript>	
	// function to add form errors to the actionErrors array
	function actionError(str) {
		if ( not isDefined("actionErrors") ) 
			actionErrors = arrayNew(1); // note: do not declare actionErrors with var, we actually want this in local/variables scope
		arrayAppend(actionErrors,str);
	}	
	
	// always trim form input
	for (key in form) {
		form[key] = trim(form[key]);
	}
</cfscript>
	
<!--- copy application.speck.portal into request scope for every request (Application.cfm calls spApp, not spPortal) --->
<cflock scope="application" type="readonly" timeout="5">
<cfset request.speck.portal = duplicate(application.speck.portal)>
</cflock>
	
