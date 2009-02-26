<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfset bPortal = ( listFindNoCase(getBaseTagList(),"CF_SPPORTAL") or isDefined("request.speck.portal") )>

<cf_spType
	name="spKeywords"
	caption="Keyword"
	description="Application Keywords"
	revisioned="no"
	labelRequired="no">
	
	<cf_spProperty
		name="keyword"
		caption="Keyword"
		type="Keyword"
		required="yes"
		unique="yes"
		displaySize="70"
		maxlength="250"
		hint="The keyword is used in the URL to identify the site section. A hierarchy of sections is represented using dots in the keyword. Once a section has been created, you cannot edit the keyword."
		index="yes">
	
	<cf_spProperty
		name="name"
		caption="Friendly&nbsp;Name"
		type="Html"
		required="no"
		displaySize="70"
		maxlength="250"
		hint="The name used in navigation menus. You should keep names short, so they fit into the space allowed for menus.">

	<cf_spProperty
		name="title"
		caption="Title"
		type="Html"
		required="no"
		displaySize="70"
		maxlength="250"
		hint="The title of the section, which you can see in the title of a browser window. The title is also used by search engines when listing search results.">

	<cf_spProperty
		name="description"
		caption="Description"
		type="Html"
		required="no"
		displaySize="70,2"
		maxlength="500"
		hint="A short description of the content available in this section, primarily for use by search engines when indexing and listing search results. Leave this blank to have the system generate a description from the title and site name.">
		
	<cf_spProperty
		name="keywords"
		caption="Keywords"
		type="Html"
		required="no"
		displaySize="70,2"
		maxlength="500"
		hint="A list of keywords which can be used by search engines when indexing a section. Leave this blank to have the system generate keywords using the title and site name.">
			
	<cfif bPortal>
			
		<cf_spProperty
			name="template"
			caption="Template"
			type="KeywordTemplate"
			required="no"
			hint="The template used to generate content in a section. This determines both the type of content that can be added to a section, for example articles or events, and how it will be displayed.">
			
		<cf_spProperty
			name="layout"
			caption="Layout"
			type="KeywordLayout"
			required="no"
			hint="The layout is used to place content, navigation menus and other items on the page. Most sites only require one layout. If there is more than one option here, you might be able to select between, for example, a two column and a three column layout.">		

	</cfif>
					
	<cf_spProperty
		name="roles"
		caption="Admin&nbsp;Roles"
		type="KeywordRoles"
		required="no"
		displaySize="#attributes.context.getConfigString("types","spkeywords","roles_display_size",3)#"
		hint="Grants access to manage some content items in a section based on role membership. This does not affect users who already have access to add and modify content on the site in general (i.e. users with spEdit or spLive role)."
		roles="spSuper">
	
	<cfif bPortal>
	
		<!--- 
		Note that this access control groups property is not *currently* used by the 
		cf_spContentGet to restrict access to content based on group membership. It 
		is only available as a convenience to developers who are using Speck keywords
		to identify web site locations. This list of groups may then be used to 
		control access to content in a location. cf_spPage uses this list of groups as
		an access control list to determine which users should be allowed to view the 
		content generated from a content template in a location. It does not provide 
		any access control to content generated from a layout in a location.
		--->
		<cf_spProperty
			name="groups"
			caption="Access&nbsp;Groups"
			type="KeywordGroups"
			required="no"
			displaySize="#attributes.context.getConfigString("types","spkeywords","groups_display_size",3)#"
			hint="Limits access to a section based on group membership. If no groups have been selected, the section is publicly accessible."
			roles="spSuper,spUsers">
			
		<cf_spProperty
			name="spMenu"
			caption="Show&nbsp;in&nbsp;menu"
			type="Boolean"
			defaultValue="1"
			index="yes">
			
		<cf_spProperty
			name="spSitemap"
			caption="Show&nbsp;in&nbsp;sitemap"
			type="Boolean"
			defaultValue="1"
			index="yes">
			
		<cf_spProperty
			name="tooltip"
			caption="Menu&nbsp;Tooltip"
			type="Html"
			required="no"
			displaySize="70"
			maxlength="250"
			roles="spSuper">
			
		<cf_spProperty
			name="href"
			caption="Links&nbsp;To"
			type="Text"
			required="no"
			displaySize="70"
			maxlength="250"
			hint="Forces the link in the navigation menu and sitemap to go to a particular URL."
			roles="spSuper">
			
	</cfif>
		
	<!---
	Numeric id for row in spKeywords table, may be used to obtain a Speck keyword 
	from a numeric identifier before calling cf_spContentGet, for example, to allow 
	a keyword id to be passed in a URL rather than the full Speck keyword.
	--->
	<cf_spProperty
		name="keyId"
		caption="Numeric Keyword Identifier"
		type="Number"
		required="no"
		displaySize="0"
		index="yes">	
	
	<!---
	Sort order id, to allow arbitrary sorting of keywords. As this property is hidden
	from the admin forms in SpeckCMS, we'll include it for all Speck apps, regardless 
	of whether they are wrapped inside the portal framework. It's just easier to do this, 
	'cos then we can write a generic query to copy the keywords into application scope 
	in cf_spApp. No, not the most elegant solution in the world, but I've gone beyond 
	caring at this stage tbh, I need something up and running asap.
	--->
	<cf_spProperty
		name="sortId"
		caption="Sort Order Identifier"
		type="Number"
		required="no"
		displaySize="0"
		index="yes">	
	
	
	<cf_spHandler method="display">
	
		<cfoutput>#content.keyword#</cfoutput>
		
	</cf_spHandler>
	
	
	<cf_spHandler method="contentPut">
	
		<cfoutput>
		<script type="text/javascript">
			if ( window.onload ) 
				otherOnLoad_spKeywords = window.onload;
			else 
				otherOnLoad_spKeywords = new Function;
			window.onload = function() {
								window.close();
								otherOnLoad_spKeywords();
							};
		</script>
		</cfoutput>
		
		<!--- always force keyword to lower case --->
		<cfset content.keyword = lCase(content.keyword)>
		
		<!--- if no friendly name specified, set value to same as keyword --->
		<cfif not len(content.name)>
		
			<cfset content.name = request.speck.capitalize(listLast(content.keyword,"."))>
		
		</cfif>
		
		<!--- make label value the same as friendly name --->
		<cfset content.spLabel = left(content.name,250)>
		
		<!--- remove new line characters from description property value --->
		<cfset content.description = reReplace(content.description,"[[:space:]]+",chr(32),"all")>
		
		<!--- remove new line characters from keywords property value --->
		<cfset content.keywords = reReplace(content.keywords,"[[:space:]]+",chr(32),"all")>
		
		<!--- if no title specified, set to friendly name value --->
		<cfif not len(content.title)>
			<cfset content.title = content.name>
		</cfif>
		
		<cfif bPortal>
		
			<cfif not isNumeric(content.spMenu)>
				<cfset content.spMenu = 1>
			</cfif>
			
			<cfif not isNumeric(content.spSitemap)>
				<cfset content.spSitemap = 1>
			</cfif>
		
			<!--- if no tooltip specified, set to title value --->
			<cfif content.spMenu and not len(content.tooltip)>
				<cfset content.tooltip = content.title>
			</cfif>
			
		</cfif>
				
		<!--- get existing row if exists, we need this to check if the keyword has changed --->
		<cfquery name="qExisting" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			SELECT * FROM spKeywords WHERE spId = '#content.spId#'
		</cfquery>
		
		<cftransaction>

			<!--- if new content item, get keyId --->
			<cfif not isNumeric(content.keyId)>
			
				<!--- get next available id from database --->
				<cfquery name="qKeyId" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
					SELECT MAX(keyId) AS maxId FROM spKeywords
				</cfquery>
				
				<cfif isNumeric(qKeyId.maxId) and qKeyId.maxId gt 0>
					<cfset content.keyId = qKeyId.maxId + 1>
				<cfelse>
					<cfset content.keyId = 1>
				</cfif>
			
			</cfif>
			
			<!--- sort if this is a new keyword --->
			<!--- <cfif not qExisting.recordCount or qExisting.keyword neq content.keyword> --->
			<cfif not isNumeric(content.sortId)>
			
				<cfif listLen(content.keyword,".") eq 1>
				
					<!--- orphan keyword --->
					<cfquery name="qSortId" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
						SELECT MAX(sortId) AS maxId FROM spKeywords
					</cfquery>
					
					<cfif isNumeric(qSortId.maxId) and qSortId.maxId gt 0>
						<cfset content.sortId = qSortId.maxId + 1>
					<cfelse>
						<cfset content.sortId = 1>
					</cfif>				
			
				<cfelse>
				
					<!--- keyword is someone's chiseller, this is a bit trickier --->
					<cfset parent = listDeleteAt(content.keyword,listLen(content.keyword,"."),".")>
					
					<!--- if child has siblings, put child after last sibling, otherwise put after parent --->
					<cfquery name="qLastSibling" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
						SELECT MAX(sortId) AS maxId FROM spKeywords
						WHERE keyword LIKE '#parent#.%'
							AND keyword <> '#qExisting.keyword#'
					</cfquery>
					
					<cfif isNumeric(qLastSibling.maxId) and qLastSibling.maxId gt 0>
						
						<cfset content.sortId = qLastSibling.maxId + 1>
					
					<cfelse>
			
						<cfquery name="qParent" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
							SELECT sortId FROM spKeywords
							WHERE keyword = '#parent#'
						</cfquery>
						
						<cfset content.sortId = qParent.sortId + 1>	
					
					</cfif>
					
					<!--- now shift other keywords down --->
					<cfquery name="qUpdateSortOrder" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
						UPDATE spKeywords
						SET sortId = sortId + 1
						WHERE sortId >= #content.sortId#
					</cfquery>
				
				</cfif>
			
			</cfif>
		
			<!--- 
			Need to update the application.speck.qKeywords query and 
			application.speck.keywords structure when content is put.
			Seeing as this contentPut method is called prior to actually 
			updating the database, we'll need to check if we are adding 
			a new keyword or updating an existing and update the 
			application.speck.qKeywords query using query functions.
			BTW, this highlights the need for an afterPut type of event.
			Updating the application.speck.keywords structure is simple 
			because we just need to set the key value to the roles list.
			--->
			<cfif qExisting.recordCount>
			
				<!--- find row in existing query --->
				<cfloop query="request.speck.qKeywords">
					
					<cfif spId eq content.spId>
						
						<cfset rowNumber = currentRow>
						
					</cfif>
					
				</cfloop>
			
			<cfelse>
				
				<!--- add a new row --->
				<cfset void = queryAddRow(request.speck.qKeywords)>
				<cfset rowNumber = request.speck.qKeywords.recordCount>
			
			</cfif>
		
			<!--- set all cells in this row to values from content structure --->
			<cfloop list="#request.speck.qKeywords.columnList#" index="i">
				
				<cftry>
				
					<cfset void = querySetCell(request.speck.qKeywords,i,evaluate("content.#i#"),rowNumber)>
					
				<cfcatch>
					<!--- 
					do nothing, this should only happen if there is a column in the db 
					table that no longer has a relevant property in this content type 
					--->
				</cfcatch>
				</cftry>
			
			</cfloop>

		</cftransaction>

		<!--- THIS SORTING FSCKS UP IN CF5, SEEMINGLY BECAUSE THE NEWLY ADDED ROW DID 
		NOT COME FROM A CFQUERY RESULTSET - FFS, I'VE HAD IT WITH CF (WELL, 5 ANYWAY) 
		AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHHHHHHHHHHHHHHHHHHHHHH!!!!!!!!!!! --->
		
		<!--- additional note: almost bald, but problem worked around with hack in keywords.cfm admin page
		AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHHHHHHHHHHHHHHHHHHHHHH!!!!!!!!!!! (ah, I feel a bit better now) --->
		
		<!--- make sure query is correctly sorted --->
		<cfquery name="request.speck.qKeywords" dbtype="query">
			SELECT * FROM request.speck.qKeywords ORDER BY sortId, keyword
		</cfquery>
			
		<!--- update application scope --->
		<cflock scope="application" timeout="3" type="exclusive">
		<cfset application.speck.qKeywords = duplicate(request.speck.qKeywords)>
		<cfset application.speck.keywords[content.keyword] = content.roles>
		</cflock>
		
	</cf_spHandler>
	
	
	<cf_spHandler method="delete">

		<!--- abort delete if keyword has descendents --->
		
		<!--- 
		MOVED TO ADMIN.CFM
		<cfquery name="qDescendents" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			SELECT keyword
			FROM spKeywords
			WHERE keyword LIKE '#content.keyword#.%'
			ORDER BY sortId, keyword
		</cfquery>
		
		<cfif qDescendents.recordCount gt 0>
		
			<cfset lDescendents = valueList(qDescendents.keyword)>
			
			<cfoutput>
			<script>
			window.onload = function() {
				alert("Keyword '#content.keyword#' cannot be deleted because is has descendents.\n\nPlease delete the descendent keywords listed below first:\n\n#listChangeDelims(lDescendents,"\n")#");
				window.opener.closeWindow(window);
			}
			</script>
			</cfoutput>
			
			<cfabort>
			
		</cfif> --->
		
		<!--- update keywords stuff in application scope when deleting --->	
				
		<!--- update the sort order for all the keywords after the current keyword --->
		<cfquery name="qUpdateKeywords" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			UPDATE spKeywords
			SET sortId = sortId - 1
			WHERE sortId > #content.sortId#
		</cfquery>
		
		<!--- get all keywords apart from the one we're about to delete --->	
		<cfquery name="qKeywords" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			SELECT * FROM spKeywords 
			WHERE keyword <> '#content.keyword#'
			ORDER BY sortId, keyword
		</cfquery>
		
		<cfscript>
			stKeywords = structNew();
			for(i=1; i le qKeywords.recordCount; i = i + 1)
				structInsert(stKeywords, qKeywords.keyword[i], qKeywords.roles[i]);
		</cfscript>			
	
		<cflock scope="application" timeout="3" type="exclusive">
		<cfset application.speck.qKeywords = duplicate(qKeywords)>
		<cfset application.speck.keywords = duplicate(stKeywords)>
		</cflock>
	
	</cf_spHandler>
	
		
</cf_spType>

