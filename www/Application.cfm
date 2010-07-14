<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfif isDefined("url.app")>

	<cf_spApp name="#url.app#" refresh="No">
	<cfcookie name="spAppName" value="#request.speck.appName#">

<cfelseif isDefined("cookie.spAppName")>

	<cf_spApp name="#cookie.spAppName#" refresh="No">
	
<cfelse>

	<cfoutput><h1>Speck: Required parameter "app" missing from URL</h1></cfoutput>
	<cfabort>
	
</cfif>

<cfparam name="request.speck.language" default="en">

<cfif left(request.speck.cfVersion,1) gte 6>
	<cfset charset = "UTF-8">
<cfelse>
	<cfset charset = "ISO-8859-1">
</cfif>

<!--- set encoding and language of response --->
<!--- <cfcontent type="text/html; charset=#request.speck.charset#"> --->
<cfheader name="Content-type" value="text/html; charset=#charset#">
<cfheader name="Content-language" value="#request.speck.language#">

<!--- never cache --->
<cfheader name="Pragma" value="no-cache">
<cfheader name="Cache-Control" value="private, no-cache, must-revalidate">