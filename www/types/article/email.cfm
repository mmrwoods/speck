<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfparam name="url.id" default="">
<cfparam name="url.noun" default="fiend">

<cfif request.speck.isUUID(url.id)>
	
	<cfscript>
		// see if we can find a stylesheet
		defaultStylesheet = "";
		fs = request.speck.fs;
		if ( structKeyExists(request.speck,"portal") and len(request.speck.portal.popupStylesheet) ) {
			defaultStylesheet = request.speck.portal.popupStylesheet;
		} else if ( fileExists(request.speck.appInstallRoot & fs & "www" & fs & "stylesheets" & fs & "popup.css") ) {
			defaultStylesheet = "/stylesheets/popup.css";
		} else if ( fileExists(request.speck.appInstallRoot & fs & "www" & fs & "styles" & fs & "popup.css") ) {
			defaultStylesheet = "/styles/popup.css";
		}
	</cfscript>
	
	<cfparam name="request.speck.config.types.article.email_stylesheet" default="#defaultStylesheet#">
	<cfparam name="request.speck.config.types.article.email_header" default="">
	<cfparam name="request.speck.config.types.article.email_footer" default="">
	
	
	<cf_spContent 
		type="Article" 
		method="email" 
		id="#url.id#" 
		enableAdminLinks="no" 
		stylesheet="#request.speck.config.types.article.email_stylesheet#"
		header="#request.speck.config.types.article.email_header#"
		footer="#request.speck.config.types.article.email_footer#"
		noun="#url.noun#">

</cfif>