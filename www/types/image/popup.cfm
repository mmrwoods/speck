<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

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
	
	<cfparam name="request.speck.config.types.image.popup_stylesheet" default="#defaultStylesheet#">
	<cfparam name="request.speck.config.types.image.popup_showcaption" default="yes">
	
	<cf_spCacheThis cacheName = "image_popup_#replace(url.id, "-", "", "all")#">
	
		<cf_spContent
			id="#url.id#"
			type="Image"
			method="popup"
			stylesheet="#request.speck.config.types.image.popup_stylesheet#"
			showCaption="#request.speck.config.types.image.popup_showcaption#"
			enableAdminLinks="no">
		
	</cf_spCacheThis>

</cfif>