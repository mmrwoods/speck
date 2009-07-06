<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfparam name="attributes.separator" default=" &gt; ">
<cfparam name="attributes.class" default=""> <!--- class for the links --->
<cfparam name="attributes.selectedClass" default=""> <!--- class for current keyword link --->
<cfparam name="attributes.prefix" default=""> <!--- prefix each link caption with this string --->
<cfparam name="attributes.suffix" default=""> <!--- suffix each link caption with this string --->
<cfparam name="attributes.truncate" default="false" type="boolean"> <!--- true|false or number of chars to truncate at --->
<cfif isNumeric(attributes.truncate)>
	<cfset truncateAt = attributes.truncate>
<cfelseif structKeyExists(attributes,"truncateAt")> <!--- old deprecated attribute --->
	<cfset truncateAt = attributes.truncateAt>
<cfelse>
	<cfset truncateAt = 30>
</cfif>
<cfparam name="attributes.wrap" default="true" type="boolean"> <!--- if false replace spaces with &nbsp; in link captions --->
<cfparam name="attributes.case" default=""> <!--- set to UPPER, LOWER or CAPITALIZE/CAPITALISE to force case --->
<cfparam name="attributes.tabIndex" default=""> <!--- add tabIndex to links starting at attributes.tabIndex value (which must be a positive integer) --->
<cfparam name="attributes.r_breadcrumbs" default=""> <!--- name of return variable in caller, if no return variable, output menu --->
<cfparam name="attributes.tooltip" default="true" type="boolean"> <!--- generate a tooltip (i.e. title attribute) for each link --->

<cfif isDefined("attributes.scriptName") and attributes.scriptName neq cgi.script_name>

	<cfthrow message="cf_spBreadcrumbs: scriptName attribute is no longer supported">

</cfif>

<cfif len(attributes.class) and not len(attributes.selectedClass)>
	
	<cfset attributes.selectedClass = attributes.class & " selected">
	
</cfif>

<cfscript>
	// new line sequence
	nl = chr(13) & chr(10);	
	
	// tabIndex counter, we'll increment this rather than attributes.tabIndex
	tabIndex = attributes.tabIndex;

	// set various strings here rather than run conditions for every breadcrumb item
	classHtml = "";
	selectedClassHtml = "";
	tabIndexHtml = "";
	
	// add class attribute to anchors
	if ( len(attributes.class) )
		classHtml = " class=""#attributes.class#""";
		
	if ( len(attributes.selectedClass) )
		selectedClassHtml = " class=""#attributes.selectedClass#""";
	else 
		selectedClassHtml = classHtml;
</cfscript>

<cfsavecontent variable="output">

	<cfset breadcrumbsLength = arrayLen(request.speck.portal.breadcrumbs)>
	<cfloop from="1" to="#breadcrumbsLength#" index="i">
	
		<cfset breadcrumb = request.speck.portal.breadcrumbs[i]>
		<cfset thisCaption = breadcrumb.caption>
		<cfset thisTitle = breadcrumb.title>
		<cfset thisHref = breadcrumb.href>
		
		<cfif attributes.tooltip and len(thisTitle)>
			<cfset titleHtml = " title=""#thisTitle#""">
		<cfelse>
			<cfset titleHtml = "">
		</cfif>

		<!--- tabindex? --->
		<cfif isNumeric(tabIndex)>
			<cfset tabIndexHtml = " tabindex=""#tabIndex#""">
			<cfset tabIndex = tabIndex + 1>
		</cfif>
	
		<!--- force case? --->
		<cfif len(attributes.case)>
			<cfswitch expression="#uCase(attributes.case)#">
				<cfcase value="LOWER">
					<cfset thisCaption = lCase(thisCaption)> 
				</cfcase>
				<cfcase value="UPPER">
					<cfset thisCaption = uCase(thisCaption)> 
				</cfcase>
				<cfcase value="CAPITALIZE,CAPITALISE">
					<cfset thisCaption = request.speck.capitalize(thisCaption)> 
				</cfcase>														
			</cfswitch>
		</cfif>
		
		<cfif attributes.truncate and len(thisCaption) gt truncateAt>
		
			<cfset thisCaption = left(thiscaption,truncateAt-3) & "...">

		</cfif>
		
		<!--- stop text wrapping? --->
		<cfif not attributes.wrap>
			<cfset thisCaption = replace(thisCaption,chr(32),"&nbsp;","all")>
		</cfif>
		
		<!--- caption prefix and suffix --->
		<cfset thisCaption = attributes.prefix & thisCaption & attributes.suffix>
		
		<!--- escape caption (maybe we should use xmlFormat here) --->
		<cfset thisCaption = replace(thisCaption,"& ","&amp; ","all")>
		
		<cfif i eq breadcrumbsLength>
		
			<cfoutput>
			<a#selectedClassHtml##tabIndexHtml##titleHtml# href="#thisHref#">#thisCaption#</a>
			</cfoutput>
			
		<cfelse>
	
			<cfoutput>
			<a#classHtml##tabIndexHtml##titleHtml# href="#thisHref#">#thisCaption#</a>
			#attributes.separator#
			</cfoutput>
		
		</cfif>
		
	</cfloop>
	
</cfsavecontent>

<!--- output the breadcrumbs --->
<cfif len(attributes.r_breadcrumbs)>
	
	<cfset "caller.#attributes.r_breadcrumbs#" = trim(output)>
	
<cfelse>

	<cfoutput>#output#</cfoutput>

</cfif>