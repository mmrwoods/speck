<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- output links for use in a site navigation menu --->

<!--- make sure that any request scope variables we reference are paramed --->
<cfparam name="request.speck.sesSuffix" default="">
<cfparam name="request.speck.maxKeywordLevels" default="2">

<cfparam name="attributes.separator" default="">

<cfparam name="attributes.layouts" default=""> <!--- if not empty string, only output links to locations using one of the listed layouts --->

<cfparam name="attributes.sitemap" default="false" type="boolean">

<cfif attributes.sitemap>

	<cfset attributes.allSubLevels = true>
	<cfset attributes.levels = request.speck.maxKeywordLevels>
	<cfset attributes.list = true>

<cfelse>

	<cfparam name="attributes.allSubLevels" default="false" type="boolean"> <!--- output links for sub-levels of all keywords, not just the curent keyword --->
	<cfparam name="attributes.levels" default="1" type="numeric"> <!--- no of levels/nodes to traverse --->
	<cfparam name="attributes.list" default="false" type="boolean"> <!--- output menu items as html list elements and use the class and highlightClass attributes as class attributes for the list item element --->

</cfif>

<cfparam name="attributes.class" default=""> <!--- class for the links --->
<cfparam name="attributes.listItemClass" default="#attributes.class#"> <!--- class for the list items --->
<cfparam name="attributes.selectedClass" default=""> <!--- class for highlighted links --->
<cfparam name="attributes.listItemSelectedClass" default="#attributes.selectedClass#"> <!--- class for highlighted list items --->
<cfparam name="attributes.privateClass" default=""> <!--- class for links to private sections --->
<cfparam name="attributes.listItemPrivateClass" default="#attributes.privateClass#"> <!--- class for private section list items --->
<cfparam name="attributes.allLevelsSelected" default="yes"> <!--- apply selected class to all levels rather than just the exact keyword match --->
<cfparam name="attributes.listId" default="">
<cfparam name="attributes.listClass" default="">
<cfparam name="attributes.levelSpecificSelectors" default="false" type="boolean"> <!--- if true, adds level number to values of id and class attributes --->
<cfparam name="attributes.generateListItemIds" default="false" type="boolean">
<cfparam name="attributes.listItemIdPrefix" default="li_">
<cfparam name="attributes.hideInAccessible" default="false" type="boolean">
<cfparam name="attributes.prefix" default=""> <!--- prefix each link caption with this string --->
<cfparam name="attributes.suffix" default=""> <!--- suffix each link caption with this string --->
<cfparam name="attributes.wrap" default="true" type="boolean"> <!--- if false replace spaces with &nbsp; in link captions --->
<cfparam name="attributes.case" default=""> <!--- set to UPPER, LOWER or CAPITALIZE/CAPITALISE to force case --->
<cfparam name="attributes.tabIndex" default=""> <!--- add tabIndex to links starting at attributes.tabIndex value (which must be a positive integer) --->
<cfparam name="attributes.r_menu" default=""> <!--- name of return variable in caller, if no return variable, output menu --->
<cfparam name="attributes.keyword" default="#request.speck.portal.keyword#"> <!--- this is the current keyword / site location we are at --->
<cfparam name="attributes.tooltip" default="false" type="boolean"> <!--- generate a tooltip (i.e. title attribute) for each link --->
<cfparam name="attributes.scriptName" default="#cgi.script_name#"> <!--- by default we use cgi.script_name when building each link, you can override this if you want to use mod_rewrite to remove the script name from the urls --->

<cfset menuSesSuffix = request.speck.sesSuffix>
<cfif isDefined("request.speck.portal.rewriteEngine") and request.speck.portal.rewriteEngine>
	<cfparam name="attributes.basePath" default="#request.speck.appWebRoot#/#request.speck.portal.rewritePrefix#">
	<cfif not len(request.speck.portal.rewritePrefix) or right(request.speck.portal.rewritePrefix,1) eq "/">
		<cfset menuSesSuffix = "">
	</cfif>
<cfelse>
	<cfparam name="attributes.basePath" default="#attributes.scriptName#/spKey/">
</cfif>

<cfif len(attributes.class) and not len(attributes.selectedClass)>
	
	<cfset attributes.selectedClass = attributes.class & " selected">
	
</cfif>

<cfif isDefined("attributes.parent")>

	<cfif len(attributes.parent)>
	
		<cfquery name="qKeywords" dbtype="query">
			SELECT * FROM request.speck.qKeywords WHERE keyword LIKE '#attributes.parent#.%'
		</cfquery>
		
	<cfelse>
	
		<!--- oops, we can't generate a submenu without a parent --->
		<cfif len(attributes.r_menu)>
			
			<cfset "caller.#attributes.r_menu#" = "">
			
		</cfif>
		
		<cfexit method="exittag">
		
	</cfif>

<cfelse>

	<cfset qKeywords = duplicate(request.speck.qKeywords)>

</cfif>

<cfscript>
	if ( isDefined("attributes.parent") ) {
		topLevel = listLen(attributes.parent,".") + 1;
	} else {
		topLevel = 1;
	}
		
	// new line sequence
	nl = chr(13) & chr(10);	
	
	// tabIndex counter, we'll increment this rather than attributes.tabIndex
	tabIndex = attributes.tabIndex;

	// set various strings here rather than run conditions for every menu item
	classHtml = "";
	selectedClassHtml = "";
	openListElement = "";
	openSelectedListElement = "";
	closeListElement = "";
	tabIndexHtml = "";
	
	if ( attributes.levelSpecificSelectors ) {
		cssSelectorSuffix = topLevel;
	} else {
		cssSelectorSuffix = "";	
	}
	
	// add class attribute to anchors (NOTE: we're always setting these to something now so some string replacements later on in the tag work, TODO: tidy this mess up)
	classHtml = " class=""#attributes.class##cssSelectorSuffix#""";
	selectedClassHtml = " class=""#attributes.selectedClass##cssSelectorSuffix#""";
				
	// if we're outputting list items, also add class attribute list items
	if ( attributes.list ) {
		openListElement = "<li class=""#attributes.listItemClass##cssSelectorSuffix#"">";
		openSelectedListElement = "<li class=""#attributes.listItemSelectedClass##cssSelectorSuffix#"">";
		closeListElement = "</li>" & chr(13) & chr(10);
	}
	
	bSuper = request.speck.userHasPermission("spSuper");
	if ( isDefined("request.speck.session.groups") ) {
		lUserGroups = structKeyList(request.speck.session.groups);
	} else {
		lUserGroups = "";
	}
</cfscript>

<cfsavecontent variable="menu">

	<cfloop query="qKeywords">
	
		<cfparam name="spSitemap" default="1">
	
		<cfif ( spMenu eq 1 or ( attributes.sitemap and spSitemap eq 1 ) ) and listLen(keyword,".") eq topLevel and ( not len(attributes.layouts) or listFindNoCase(attributes.layouts,layout) )>

		    <!--- check if user has access to this keyword --->
 			<cfscript>
				bAccess = true; // set to true if user has view access to keyword
				if ( attributes.hideInAccessible ) {
					bAccess = false;
					lAccessGroups = groups;
					if ( bSuper ) {
						bAccess = true; 
					} else if ( groups eq "" ) {
						bAccess = true;	
					} else {
						// loop over groups, if group found in users group list, set access to true
						while (lAccessGroups neq "" and not bAccess) {
							group = listFirst(lAccessGroups);
							lAccessGroups = listRest(lAccessGroups);
							if ( listFindNoCase(lUserGroups,group) )
								bAccess = true;
						}
					 }
				}
			</cfscript>
			
			<cfif bAccess>
			
				<cfset thisCaption = name>
				
				<cfset thisKeyword = replace(keyword,".",request.speck.portal.keywordSeparator,"all")>
				
				<!--- show a tooltip for the link? --->
				<cfif attributes.tooltip>
					<cfif len(tooltip)>
						<cfset titleHtml = " title=""#tooltip#""">
					<cfelseif len(title)>
						<cfset titleHtml = " title=""#title#""">
					<cfelse>
						<cfset titleHtml = " title=""#name#""">
					</cfif>
				<cfelse>
					<cfset titleHtml = "">
				</cfif>			
	
				<!--- override default href? --->
				<cfif len(href)>
					<cfset thisHref = href>
				<cfelse>
					<cfset thisHref = "#attributes.basePath##thisKeyword##menuSesSuffix#">
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
				
				<!--- stop text wrapping? --->
				<cfif not attributes.wrap>
					<cfset thisCaption = replace(thisCaption,chr(32),"&nbsp;","all")>
				</cfif>
				
				<!--- caption prefix and suffix --->
				<cfset thisCaption = attributes.prefix & thisCaption & attributes.suffix>
				
				<!--- escape caption (maybe we should use xmlFormat here) --->
				<cfset thisCaption = replace(thisCaption,"& ","&amp; ","all")>			
				
				<cfset bActiveKeyword = ( len(attributes.keyword) and keyword eq attributes.keyword )>		
				
				<cfset bSelected = ( bActiveKeyword or ( attributes.allLevelsSelected and findNoCase("." & keyword & ".", "." & attributes.keyword) ) )>
				
				<cfif bSelected>
				
					<cfset thisListItem = openSelectedListElement>
					<cfset thisAnchor = '<a#selectedClassHtml##tabIndexHtml##titleHtml# href="#thisHref#">#thisCaption#</a>'>
					
				<cfelse>
					
					<cfset thisListItem = openListElement>
					<cfset thisAnchor = '<a#classHtml##tabIndexHtml##titleHtml# href="#thisHref#">#thisCaption#</a>'>
				
				</cfif>
				
				<cfif attributes.generateListItemIds>
					<cfset thisListItem = replace(thisListItem,"<li","<li id=""#attributes.listItemIdPrefix##replace(keyword,".","_","all")#""")>
				</cfif>
				
				<cfif len(attributes.privateClass) and len(groups)>
					<cfset thisAnchor = replace(thisAnchor,'class="','class="#attributes.privateClass# ')>
				</cfif>
				
				<cfif len(attributes.listItemPrivateClass) and len(groups)>
					<cfset thisListItem = replace(thisListItem,'class="','class="#attributes.listItemPrivateClass# ')>
				</cfif>
				
				<cfoutput>#thisListItem##thisAnchor#</cfoutput>
	
				<cfif attributes.levels gt 1 and ( bActiveKeyword or findNoCase("." & keyword & ".", "." & attributes.keyword) or attributes.allSubLevels )>
					
					<!--- nested output - call myself with the mostly the same attributes --->
					<cfscript>
						a = duplicate(attributes);
						a.parent = keyword; // force the parent to the current keyword
						a.levels = a.levels - 1; // decrement the levels attribute, otherwise we'd go on forever
						a.r_menu = ""; // never return the menu as a variable
						if ( not attributes.levelSpecificSelectors ) {
							a.listId = ""; // ids are unique
							a.listClass = "";
						}
						if ( isNumeric(tabIndex) ) {
							a.tabIndex = tabIndex; // pass the tab index along to keep the sequence in proper order
						}
					</cfscript>
					
					<cf_spMenu attributeCollection=#a#>
					
				</cfif>
				
				<cfoutput>#closeListElement#</cfoutput>
				
			</cfif>
			
		</cfif>
	
	</cfloop>
	
</cfsavecontent>

<cfscript>
	// slap in the list element if necessary
	if ( attributes.list and len(menu) ) {
		listIdHtml = "";
		listClassHtml = "";
		if ( len(attributes.listId) ) {
			listIdHtml = " id=""#attributes.listId##cssSelectorSuffix#""";
		}
		if ( len(attributes.listClass) ) {
			listClassHtml = " class=""#attributes.listClass##cssSelectorSuffix#""";
		}
		menu = "<ul" & listIdHtml & listClassHtml & ">" & nl & menu & nl & "</ul>";
	}
	// add a separator between each item if necessary
	if ( attributes.levels eq 1 and len(attributes.separator) and not attributes.list ) {
		menu = replace(menu,"</a>","</a>#attributes.separator#","all");
	}
	menu = replace(menu," class=""""","","all"); // clean up any empty classes left behind
</cfscript>

<!--- output the menu --->
<cfif len(attributes.r_menu)>
	
	<cfset "caller.#attributes.r_menu#" = trim(menu)>
	
<cfelse>

	<cfoutput>#menu#</cfoutput>

</cfif>
