<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfparam name="attributes.method" default="display">
<cfparam name="attributes.separator" default="">
<cfparam name="attributes.columns" default="1">
<cfparam name="request.speck.session.showAdminLinks" type="boolean" default="no">
<cfparam name="attributes.enableAdminLinks" default=#request.speck.session.showAdminLinks#>
<cfparam name="attributes.enableAddLink" default=#attributes.enableAdminLinks#>
<cfparam name="attributes.keywords" default="">
<cfparam name="attributes.id" default="">
<cfparam name="attributes.label" default="">
<cfparam name="attributes.bEdit" default="false">
<cfparam name="attributes.displayPerPage" default="0" type="numeric">
<cfparam name="attributes.maxRows" default="-1" type="numeric">
<cfparam name="attributes.startRow" default="1" type="numeric">
<cfparam name="attributes.qContent" default="">

<cfparam name="attributes.caption" default=""> <!--- use this to override the type caption for admin links etc. --->

<cfparam name="attributes.pagingMenu" default="top"> <!--- where to display the paging menu (top|bottom|both) --->
<cfparam name="attributes.pagingParam" default="spPage">
<cfparam name="attributes.pagingFormat" default="short"> <!--- long|short|search --->
<cfparam name="attributes.pagingCaption" default=""> <!--- if not empty string, output "x to y of n #attributes.pagingCaption#." - TODO: obtain add format string to strings file --->

<cfif attributes.method eq "spEdit">

	<cfset attributes.bEdit = "yes">

</cfif>

<!--- value by which to offset the maxRows attribute before passing to spContentGet and 
the startRow and endRow values returned from the paging module before passing to the handler--->
<cfset rowOffSet = attributes.startRow - 1>

<cfif attributes.maxRows gt 0>

	<cfset attributes.maxRows = attributes.maxRows + rowOffSet>

</cfif>


<!--- Get type info --->
<cfmodule template=#request.speck.getTypeTemplate(attributes.type)# r_stType="stType">


<cfif isQuery(attributes.qContent)>

	<!--- get content to edit, if passed qContent as an attribute, use this query --->
	<cfset content = attributes.qContent>

<cfelseif attributes.maxRows eq 0>

	<!--- create dummy query rather than call spContentGet --->
	<cfscript>
		lColumns = "spId,spRevision,spLabel,spCreated,spCreatedBy,spUpdated,spUpdatedby,spKeywords";
		
		for (propertyIndex = 1; propertyIndex le arrayLen(stType.props); propertyIndex = propertyIndex + 1)
			lColumns = listAppend(lColumns, stType.props[propertyIndex].name);
		
		content = queryNew(lColumns);
	</cfscript>	

<cfelse>

	<!--- Call contentGet, passing through attributes --->
	<cfmodule template="/speck/api/content/spContentGet.cfm" attributeCollection="#attributes#" r_qContent="content">
	
	<!--- if promotion on and user at edit level, check that this content can be edited by this user
		only run this check if we are editing existing content
	
		todo: wrap up this and other access control code into spPermissionCheck module
		
		 --->
	<cfif attributes.bEdit and request.speck.session.viewLevel eq "edit">
	
		<!--- promotion on and user at edit level, check that this user can edit this content... --->
		
		<!--- get latest non-live promotion from history
		
			when a content item is at one users edit level, no other users can create a new revision at edit level
			so there cannot be any newer edit or review level revisions in the history
		
		 --->
		<cfquery name="qCheckPermission" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			SELECT *
			FROM spHistory
			WHERE id = '#content.spId#'
				AND ts = (
					SELECT MAX(ts)
					FROM spHistory
					WHERE id = '#content.spId#'
						AND promoLevel <> 3
				)
			ORDER BY promoLevel DESC
		</cfquery>		

		<!--- if the content has not been promoted beyond edit level, user must be owner to edit --->
		<cfif qCheckPermission.promoLevel eq 1 and trim(qCheckPermission.editor) neq request.speck.session.user>
			
			<cf_spUserGet
				user=#trim(qCheckPermission.editor)#
				r_stUser="stEditor">
				
			<cfif isDefined("stEditor")>
			
				<cf_spError error="CONTENT_CHECKED_OUT" lParams="#stEditor.fullName#,#stEditor.email#">
				
			<cfelse>
			
				<cf_spError error="CONTENT_CHECKED_OUT" lParams="#trim(qCheckPermission.editor)#">
			
			</cfif>
			
		</cfif> 
			
	</cfif>
		
</cfif>

<cfscript>
// These variables are later in this tag and from the handler tag as well so set defaults outside any conditions
bShowEditAdmin = false;		
bShowEditPromoAdmin = false;
bShowReviewAdmin = false;
bShowAddAdmin = false;
</cfscript>

<cfif (attributes.enableAdminLinks or attributes.enableAddLink) and attributes.method neq "spEdit">
	
	<cfscript>
	
		// check admin access control to determine whether or not to show admin links (note: actual access control code is in admin.cfm)
		bSuper = request.speck.userHasPermission("spSuper");
		bEditAccess = ( bSuper or request.speck.userHasPermission("spEdit") );
		bLiveAccess = ( bSuper or request.speck.userHasPermission("spLive") );

		if ( not bEditAccess ) {
			// see if the user gets granted edit access from having one of the keyword roles
			bKeywordsAccess = false; // set to true if user has keyword role
			lKeywords = attributes.keywords;
			if ( not len(attributes.keywords) and len(content.spKeywords) ) {
				lKeywords = content.spKeywords;
			}
			for ( i=1; i le listLen(lKeywords); i = i + 1 ) {
				thisKeyword = listGetAt(lKeywords,i);
				if ( structKeyExists(request.speck.keywords,thisKeyword) 
						and len(trim(request.speck.keywords[thisKeyword]))
						and request.speck.userHasPermission(trim(request.speck.keywords[thisKeyword])) ) {
					// keyword exists, has edit roles and user has one of the roles
					bKeywordsAccess = true;
					break;
				}
			}
			bEditAccess = bKeywordsAccess;
		}
		
		if (attributes.enableAdminLinks) {
			// general admin links
			if (not request.speck.enableRevisions or not stType.revisioned) {
				bShowEditAdmin = bEditAccess;
			} else {
				if (request.speck.enablePromotion) {
					bShowEditPromoAdmin = (request.speck.session.viewLevel eq "edit" and bEditAccess);
					bShowReviewAdmin = (request.speck.session.viewLevel eq "review" and bLiveAccess);
				} else {
					bShowEditAdmin = bEditAccess;
				}
			}
		}
		
		if (attributes.enableAddLink) {
			// add content link		
			if (stType.revisioned and request.speck.enablePromotion)
				bShowAddAdmin = (request.speck.session.viewLevel eq "edit" and bEditAccess); // with revisioning and promotion enabled, only show add link at edit level
			else
				bShowAddAdmin = bEditAccess;
		}
	
		
		// get list of cacheNames in ancestor spCacheThis tags, used in resetCache JS function to 
		// force caches which this content is contained it to be reset. (note: this is used in 
		// combination with spWasCached to try and keep the cache up to date without user/developer 
		// intervention but developers need to be aware that the resetCache JS function will only 
		// reset caches which contain this call to spContent. spWasCached attempts to clear any 
		// caches that new live content could go into by matching any of id, label or keywords 
		// but if spContent[Get] is used without these attributes, spWasCached does not know which 
		// caches to clear. So, if you don't use id, label or keywords attributes in a spContent[Get]
		// call, and the call is within a cache block which may not be updated by the resetCache 
		// function when matching content is added or updated, make sure you use the cacheExpires 
		// attribute of cf_spCacheThis to ensure the cache gets flushed
		lCacheNames = "";
		if ( listFind(getBaseTagList(),"CF_SPCACHETHIS") ) {
			// spContent wrapped inside one or more spCacheThis tag
			for (i=1; i lte listValueCount(getBaseTagList(),"CF_SPCACHETHIS"); i=i+1) {
				// get cache name and append to lCacheNames
				baseTagData = getBaseTagData("CF_SPCACHETHIS",i);
				lCacheNames = listAppend(lCacheNames,baseTagData.attributes.cacheName);
			}
		}	
		
		// urls to refresh page and resetCache
		refreshURL = request.speck.getCleanRequestedPath();
		if ( find(".cfm/",refreshURL) ) { 
			// remove possible trailing slash in path before appending reset cache stuff
			refreshURL = REReplace(refreshURL,"/$","");
		}
		queryString = request.speck.getCleanQueryString();
		if ( len(queryString) ) {
			refreshURL = refreshURL & "?" & queryString;
			resetCacheURL = refreshURL & "&resetcache=1&cachelist=";
		} else {
			resetCacheURL = refreshURL & "?resetcache=1&cachelist=";
		}
		
		// get strings for use in admin links and JS functions
		
		// save to request scope because they are also required in spContentAdmin and they are the same for all spContent calls per request
		if ( not structKeyExists(request.speck,"spContent") ) 
			request.speck.spContent = structNew();
			
		if ( not structKeyExists(request.speck.spContent,"strings") ) {
	
			request.speck.spContent.strings = structNew();
			
			request.speck.spContent.strings.add = request.speck.buildString("A_CONTENT_ADD");
			request.speck.spContent.strings.edit = request.speck.buildString("A_CONTENT_EDIT");
			request.speck.spContent.strings.review = request.speck.buildString("A_CONTENT_REVIEW");
			request.speck.spContent.strings.delete = request.speck.buildString("A_CONTENT_DELETE");
				
			// different promote and demote strings depending on viewLevel and permissions when promotion is enabled
			if ( request.speck.session.viewLevel eq "edit" ) {
				if ( bLiveAccess ) {
					// users with live access promote directly to live site
					request.speck.spContent.strings.promote = request.speck.buildString("A_CONTENT_PUBLISH");
				} else {
					request.speck.spContent.strings.promote = request.speck.buildString("A_CONTENT_SUBMIT");
				}
				request.speck.spContent.strings.demote = request.speck.buildString("A_CONTENT_REVERT");
			} else {
				request.speck.spContent.strings.promote = request.speck.buildString("A_CONTENT_PUBLISH");
				request.speck.spContent.strings.demote = request.speck.buildString("A_CONTENT_REJECT");
			}
			
			// some extra strings used in handler tag if promotion is enabled (and if it isn't, set the rollback string 
			// back to the default one used with revisioning on and promotion off)
			if ( request.speck.enablePromotion ) {
				request.speck.spContent.strings.forRemoval = request.speck.buildString("A_CONTENT_FOR_REMOVAL");
			}
			
		}
		
		// type caption for use in admin links
		if ( len(attributes.caption) )
			caption = attributes.caption;
		else if ( structKeyExists(stType,"caption") )
			caption = stType.caption;
		else
			caption = stType.description;
	
	</cfscript>

	<cfif not structKeyExists(request.speck.spContent,"jsOutputComplete")>
	
		<cfoutput>
		<style type="text/css">@import "#request.speck.contentStylesheet#";</style>
		<script type="text/javascript">
			function launch_edit(type, id, keywords, cacheList, caption) {
				var win = window.open("/speck/admin/admin.cfm?action=edit&app=#request.speck.appname#&type=" + type + "&id=" + id + "&keywords=" + keywords + "&cacheList=" + cacheList + "&caption=" + caption, "edit" + id.replace(/-/g, "_"), "status=yes,menubar=no,scrollbars=yes,resizable=yes,width=600,height=600,screenX=150,screenY=50,left=150,top=50");
				win.focus();
			}
			function launch_add(type, keywords, label, cacheList, caption) {
				var win = window.open("/speck/admin/admin.cfm?action=add&app=#request.speck.appname#&type=" + type + "&keywords=" + keywords + "&label=" + label + "&cacheList=" + cacheList + "&caption=" + caption, "add" + type, "status=yes,menubar=no,scrollbars=yes,resizable=yes,width=600,height=600,screenX=150,screenY=50,left=150,top=50");
				win.focus();
			}
			function launch_promote(type, id, label, keywords, cacheList, caption) {
				if ( label.length > 0 ) { label = " '" + label + "'"; }
				if (window.confirm("#request.speck.spContent.strings.promote# " + caption + label + "?")) {
					var win = window.open("/speck/admin/admin.cfm?action=promote&app=#request.speck.appname#&type=" + type + "&id=" + id + "&label=" + label + "&keywords=" + keywords + "&cacheList=" + cacheList + "&caption=" + caption, "promote" + id.replace(/-/g, "_"), "menubar=no,scrollbars=no,resizable=yes,width=150,height=100");
				}
			}
			function launch_demote(type, id, label, keywords, cacheList, caption) {
				if ( label.length > 0 ) { label = " '" + label + "'"; }
				if (window.confirm("#request.speck.spContent.strings.demote# " + caption + label + "?")) {
					var win = window.open("/speck/admin/admin.cfm?action=demote&app=#request.speck.appname#&type=" + type + "&id=" + id + "&label=" + label + "&keywords=" + keywords + "&cacheList=" + cacheList + "&caption=" + caption, "rollback" + id.replace(/-/g, "_"), "menubar=no,scrollbars=no,resizable=yes,width=150,height=100");
				}
			}
			function launch_delete(type, id, label, keywords, cacheList, caption) {
				if ( label.length > 0 ) { label = " '" + label + "'"; }
				if (window.confirm("#request.speck.spContent.strings.delete# " + caption + label + "?")) {
					var win = window.open("/speck/admin/admin.cfm?action=delete&app=#request.speck.appname#&type=" + type + "&id=" + id + "&label=" + label + "&keywords=" + keywords + "&cacheList=" + cacheList + "&caption=" + caption, "delete" + id.replace(/-/g, "_"), "menubar=no,scrollbars=no,resizable=yes,width=150,height=100");
				}
			}
			function refresh() {
				window.location.replace("#refreshURL#");
			}
			function resetCache() {
				if ( arguments.length > 0 )
					window.location.replace("#resetCacheURL#" + arguments[0]);
				else
					window.location.replace("#resetCacheURL#");
			}
			function closeWindow(w) {
				w.close();
			}
		</script>
		</cfoutput>
		
		<cfset request.speck.spContent.jsOutputComplete = true>
	
	</cfif>

	<cfif ( trim(attributes.id & attributes.label) eq "" or content.recordCount eq 0 ) and bShowAddAdmin>
	
		<cfoutput><a class="spAdminLink spAdd" href="javascript:launch_add('#attributes.type#', '#listSort(attributes.keywords,"textNoCase")#', '#urlEncodedFormat(jsStringFormat(attributes.label))#', '#urlEncodedFormat(lCacheNames)#', '#caption#')">#request.speck.buildString("A_CONTENT_ADD")# #caption#</a><br /></cfoutput>
	
	</cfif>
	
</cfif>

<cfif content.recordCount neq 0>

	<!--- default endRow value for the call to the handler --->
	<cfset endRow = content.recordCount>
		
	<!--- as startRow attribute can be provided by user/developer, check that endRow gte startRow before bothering to call handler --->		
	<cfif endRow gte attributes.startRow>
	
		 <!--- page through output? --->
		<cfif attributes.displayPerPage gt 0>
		
			<cfset totalRows = endRow - rowOffSet>	
		
			<!--- call paging tag - passing attributes rather than referencing values in 
				caller scope within the tag, so the tag can be called elsewhere --->
			<cfmodule template="/speck/api/content/spContentPaging.cfm"
				totalRows=#totalRows#
				displayPerPage=#attributes.displayPerPage#
				paramName="#attributes.pagingParam#">
			
			<cfif len(stPaging.menu)>
			
				<cfoutput><div class="spContentPaging spContentPagingTop"></cfoutput>
				
				<cfif len(attributes.pagingCaption)>
					
					<!--- TODO: use a format string from the strings file to build this (e.g. %1 to %2 of %3 %4) --->
					<cfoutput><span class="spContentPagingCaption">#stPaging.startRow# to #stPaging.endRow# of #totalRows# #attributes.pagingCaption#</span></cfoutput>
						
				</cfif>
				
				<cfoutput><span class="spContentPagingMenu">#stPaging.menu#</span></div></cfoutput>
				
				<cfif bShowEditAdmin or bShowEditPromoAdmin or bShowReviewAdmin>
				
					<!--- hack to force the menu to clear before outputting any admin links - TODO: clean this up --->
					<cfoutput><span style="display:block;clear:both;height:0;font:0/0;">&nbsp;</span></cfoutput>
				
				</cfif>
			
				<cfset attributes.startRow = stPaging.startRow + rowOffSet>
								
				<cfset endRow = stPaging.endRow + rowOffSet>
			
			</cfif>
		
		</cfif>
	
		<cfmodule template=#request.speck.getHandlerTemplate(stType,attributes.method)#
			qContent=#content#
			separator=#attributes.separator#
			type=#attributes.type#
			method=#attributes.method#
			columns=#attributes.columns#
			attributeCollection=#attributes#
			endRow=#endRow#>
			
		<cfif ( isDefined("stPaging") and len(stPaging.menu) ) 
			and ( attributes.pagingMenu eq "bottom" or attributes.pagingMenu eq "both" )>
		
			<cfoutput><div class="spContentPaging spContentPagingBottom">#stPaging.menu#</div></cfoutput>
					
		</cfif>		
			
	</cfif>

</cfif>

