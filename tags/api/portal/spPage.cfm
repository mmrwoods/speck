<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- builds a web page, rendering content passed as an attribute or generated using a template inside a layout --->

<cfparam name="attributes.content" default=""> <!--- use this attribute to render already generated content --->

<cfparam name="request.speck.language" default="en">

<cfif left(request.speck.cfVersion,1) gte 6>
	<cfset charset = "UTF-8">
<cfelse>
	<cfset charset = "ISO-8859-1">
</cfif>

<cfset nl = chr(13) & chr(10)>

<cfset speck = structNew()>
<cfset speck.layout = attributes.content>

<!--- call spToolbar before running any code that generates content - spToolbar switches admin links etc. on and off --->

<cfsavecontent variable="toolbar">
	
	<cf_spToolbar>

</cfsavecontent>

<cfif not len(speck.layout)>

	<!--- we need to generate the content --->
	
	<!--- allow template to be set using a tag attribute --->
	<cfparam name="attributes.template" default="#request.speck.portal.template#">
	
	<cfsavecontent variable="speck.layout">
	
		<!--- add html comment markers to assist parsing further along the yellow brick road --->
		<cfoutput>#nl#<!-- SPPAGE BEGIN #uCase(request.speck.portal.keyword)# -->#nl#</cfoutput>
	
	    <!--- check if user has access to this keyword --->
		<cfscript>
			bAccess = false; // set to true if user has access
			lAccessGroups = request.speck.portal.qKeyword.groups; // groups with access
			if ( lAccessGroups eq "" ) {
				bAccess = true; // no access restrictions
			} else if ( request.speck.userHasPermission("spSuper") ) {
				bAccess = true; // super user can do anything, aaaaahahahahaha, cough
			} else if ( request.speck.session.auth eq "logon" and isDefined("request.speck.session.groups") ) {
				lUserGroups = structKeyList(request.speck.session.groups);
				// loop over groups, if group found in users group list, set access to true
				while (lAccessGroups neq "" and not bAccess) {
					group = listFirst(lAccessGroups);
					lAccessGroups = listRest(lAccessGroups);
					if ( listFindNoCase(lUserGroups,group) )
						bAccess = true;
				}
			}
		</cfscript>
		
		<cfif not bAccess>
		
			<cfif request.speck.session.auth eq "logon">
				
				<cfheader statuscode="403" statustext="Forbidden">
				
				<cfquery name="qKeyword" dbtype="query" maxrows="1">
					SELECT * 
					FROM request.speck.qKeywords
				</cfquery>
				
				<cfscript>
				request.speck.portal.keyword = qKeyword.keyword;
				request.speck.portal.qKeyword = duplicate(qKeyword);
				request.speck.portal.qKeyword.title[1] = "Access Denied";
				
				request.speck.portal.title = "Access Denied";
				request.speck.portal.description = "";
				request.speck.portal.keywords = "";
				</cfscript>
	
				<cftry>
			
					<cfmodule template="/#request.speck.mapping#/../templates/errors/access_denied.cfm">
					
				<cfcatch type="missingInclude">
						
					<cfoutput>
					<div id="sppage_access_denied">
						<strong>Access Denied</strong><br />
						<p>Sorry, you do not have permission to view content on this page.</p>
					</div>
					</cfoutput>
				
				</cfcatch>
				</cftry>

			<cfelse>
			
				<cftry>
			
					<cfmodule template="/#request.speck.mapping#/../templates/errors/logon_required.cfm">
					
				<cfcatch type="missingInclude">
						
					<cf_spLogonForm>
				
				</cfcatch>
				</cftry>
			
			</cfif>
		
		<cfelseif not request.speck.portal.qKeyword.recordCount>
		
			<!--- keyword not found --->
			<cfheader statuscode="404" statustext="Not Found">
			
			<cfquery name="qKeyword" dbtype="query" maxrows="1">
				SELECT * 
				FROM request.speck.qKeywords
				WHERE keyword = 'noSuchKeyword'
			</cfquery>
			
			<cfscript>
			request.speck.portal.keyword = qKeyword.keyword;
			request.speck.portal.qKeyword = duplicate(qKeyword);
			request.speck.portal.qKeyword.title[1] = "Not Found";
			
			request.speck.portal.title = "Not Found";	
			request.speck.portal.description = "";
			request.speck.portal.keywords = "";
			</cfscript>

			<cftry>
		
				<cfmodule template="/#request.speck.mapping#/../templates/errors/not_found.cfm">
				
			<cfcatch type="missingInclude">
					
				<cfoutput>
				<div id="sppage_not_found">
					<strong>Page Not Found</strong><br />
					<p>Sorry, the page you were looking for cannot be found.</p>
				</div>
				</cfoutput>
			
			</cfcatch>
			</cftry>

		<cfelseif len(attributes.template)>
		
			<cfmodule template="/#request.speck.mapping#/../templates/#attributes.template#.cfm">
		
		<cfelse>
		
			<!--- use blurb type to generate content --->
			<cf_spCacheThis cacheName="blurb_#replace(request.speck.portal.keyword,".","_","all")#">
			
				<cf_spContent type="Blurb" label="#request.speck.portal.keyword#" keywords="#request.speck.portal.keyword#" forceParagraphs="yes">
		
			</cf_spCacheThis>
			
		</cfif>
		
		<cfoutput>#nl#<!-- SPPAGE END #uCase(request.speck.portal.keyword)# -->#nl#</cfoutput>
	
	</cfsavecontent>
	
</cfif>

<!--- what type of output? note: we'll need to revisit this to handle later xhtml versions --->
<cfscript>
	if ( request.speck.portal.docType eq "xhtml" ) {
	
		switch ( request.speck.portal.docSubType ) {
			case "transitional"	: {
				docType = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">';
				break;
			}
			case "frameset"	: {
				docType = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">';
				break;
			}
			default : {
				// default is always strict
				docType = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">';
			}						
		}
		htmlElement = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="#request.speck.language#" lang="#request.speck.language#">';
		bodyElement = '<body>';
		
	} else {
	
		switch ( request.speck.portal.docSubType ) {
			case "transitional"	: {
				docType = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">';
				break;
			}
			case "frameset"	: {
				docType = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN">';
				break;
			}
			default : {
				// default is always strict
				docType = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Strict//EN">';
			}						
		}
		htmlElement = '<html>';
		bodyElement = '<body bgcolor="ffffff" marginwidth="0" marginheight="0" topmargin="0" leftmargin="0">';
		
	}
</cfscript>

<cfparam name="request.speck.portal.breadCrumbPageTitles" default="no">
<cfif request.speck.portal.breadCrumbPageTitles and request.speck.portal.keyword neq "home">

	<!--- build the document title as a reversed breadcrumbs --->
	<cfset pageTitle = "">
	<cfset breadCrumbsLength = arrayLen(request.speck.portal.breadcrumbs)>
	<cfloop from="#breadCrumbsLength#" to="2" index="i" step="-1">
	
		<cfset breadcrumb = request.speck.portal.breadcrumbs[i]>
		
		<cfif i eq breadCrumbsLength>
			<cfset pageTitle = breadcrumb.title>
		<cfelse>
			<cfset pageTitle = pageTitle & request.speck.portal.titleSeparator & breadcrumb.caption>
		</cfif>
	
	</cfloop>
	
	<cfset pageTitle = pageTitle & request.speck.portal.titleSeparator & request.speck.portal.name>

<cfelseif request.speck.portal.keyword eq "home">

	<cfset pageTitle = request.speck.portal.title>

<cfelse>

	<cfset pageTitle = request.speck.portal.title & request.speck.portal.titleSeparator & request.speck.portal.name>
	
</cfif>

<cfif len(request.speck.portal.description)>
	
	<cfset description = request.speck.portal.description>
	
<cfelse>
	
	<cfset description = pageTitle>
	
</cfif>

<cfif len(request.speck.portal.keywords)>
	
	<cfset keywords = request.speck.portal.keywords>
	
<cfelse>
	
	<cfset keywords = reReplace(pageTitle,"[:;\.]+",",","all")>
	<cfset keywords = reReplace(keywords,"([[:space:]]+)?,([[:space:]]+)?",",","all")>
	<cfset keywords = reReplace(keywords,"(,)+",",","all")>
	<cfset keywords = replace(keywords,",",", ","all")>
	
</cfif>

<!--- ok, we've got everything we need to generate a response, roll it there Roisin --->

<!--- set encoding and language of response --->
<!--- <cfcontent type="text/html; charset=#charset#"> --->
<cfheader name="Content-type" value="text/html; charset=#charset#">
<cfheader name="Content-language" value="#request.speck.language#">

<!--- http content body --->
<cfoutput>
#docType#
#htmlElement#
<head>
<meta http-equiv="Content-type" content="text/html; charset=#charset#" />
<meta http-equiv="Content-language" content="#request.speck.language#" />
<title>#pageTitle#</title>
<meta name="generator" content="SpeckCMS" />
<meta name="description" content="#replace(description,"""","&quot;","all")#" />
<meta name="keywords" content="#replace(keywords,"""","&quot;","all")#" />
</cfoutput>

<cfif len(request.speck.portal.stylesheet)>
	
	<cfoutput><link rel="stylesheet" type="text/css" href="#request.speck.portal.stylesheet#" />#nl#</cfoutput>
	
</cfif>

<cfif request.speck.portal.clearfix>
	
	<cfoutput><link rel="stylesheet" type="text/css" href="/speck/stylesheets/clearfix.css" />#nl#</cfoutput>
	
</cfif>

<cfif len(request.speck.portal.printStylesheet)>
	
	<cfoutput><link rel="stylesheet" type="text/css" media="print" href="#request.speck.portal.printStylesheet#" />#nl#</cfoutput>
	
</cfif>

<cfif request.speck.portal.favIcon>
	
	<cfoutput><link rel="shortcut icon" href="#request.speck.appWebRoot#/favicon.ico" type="image/x-icon" />#nl#</cfoutput>
	
</cfif>

<cfif len(request.speck.portal.importStyles)>
	
	<cfoutput><style type="text/css">#nl#<!-- #nl#/* <![CDATA[ */ #nl#</cfoutput>
	
	<cfloop list="#request.speck.portal.importStyles#" index="i">
	
		<cfoutput>@import url("#i#");#nl#</cfoutput>
	
	</cfloop>
	
	<cfoutput>/* ]]> */#nl#--> #nl#</style>#nl#</cfoutput>
	
</cfif>

<cfparam name="request.speck.portal.pngfix" default="false">
<cfif request.speck.portal.pngfix>

	<cfoutput>
	<!--[if lt IE 7.]>
	<script defer="defer" type="text/javascript" src="/speck/javascripts/pngfix.js"></script>
	<script type="text/javascript" language="javascript" src="/speck/javascripts/bgsleight.js"></script>
	<![endif]-->
	</cfoutput>

</cfif>

<cfparam name="request.speck.portal.prototype" default="false">
<cfparam name="request.speck.portal.scriptaculous" default="false">
<cfparam name="request.speck.portal.lightbox" default="false">

<cfscript>
	if ( request.speck.portal.lightbox ) {
		request.speck.portal.prototype = true;
		if ( not isBoolean(request.speck.portal.scriptaculous) ) {
			if ( not listFind(request.speck.portal.scriptaculous,"builder") ) {
				listPrepend(request.speck.portal.scriptaculous,"builder");
			}
			if ( not listFind(request.speck.portal.scriptaculous,"effects") ) {
				listPrepend(request.speck.portal.scriptaculous,"effects");
			}
		} else if ( not request.speck.portal.scriptaculous ) {
			request.speck.portal.scriptaculous = "effects,builder";
		}
	} else if ( not isBoolean(request.speck.portal.scriptaculous) or request.speck.portal.scriptaculous ) {
		request.speck.portal.prototype = true;
	}
</cfscript>

<cfif request.speck.portal.prototype>

	<cfoutput><script type="text/javascript" src="/speck/javascripts/prototype.js"></script>#nl#</cfoutput>
	
</cfif>

<cfif not isBoolean(request.speck.portal.scriptaculous)>
	
	<cfoutput><script type="text/javascript" src="/speck/javascripts/scriptaculous.js?load=#request.speck.portal.scriptaculous#"></script>#nl#</cfoutput>
	
<cfelseif request.speck.portal.scriptaculous>

	<cfoutput><script type="text/javascript" src="/speck/javascripts/scriptaculous.js"></script>#nl#</cfoutput>
	
</cfif>

<cfif request.speck.portal.lightbox>

	<cfoutput><script type="text/javascript" src="/speck/javascripts/lightbox.js"></script>#nl#</cfoutput>
	<cfoutput><link rel="stylesheet" href="/speck/stylesheets/lightbox.css" type="text/css" media="screen" />#nl#</cfoutput>

</cfif>

<cfoutput>
</head>
#bodyElement#
#toolbar#
</cfoutput>

<!--- allow layout to be set using a tag attribute --->
<cfparam name="attributes.layout" default="#request.speck.portal.layout#">

<cfif len(attributes.layout)>

	<cfinclude template="/#request.speck.mapping#/../layouts/#attributes.layout#.cfm">

<cfelse>

	<!--- just output the generated content --->
	<cfoutput>#speck.layout#</cfoutput>
	
</cfif>

<cfoutput>
</body>
</html>
</cfoutput>
