<cfsetting enablecfoutputonly="Yes">

<cfset request.is_xhr = (cgi.HTTP_X_REQUESTED_WITH eq "XMLHttpRequest" or structKeyExists(url,"xhr_test"))>

<cfsetting showdebugoutput="#(not request.is_xhr)#">

<cfset nl = chr(13) & chr(10)>

<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cftry>
	
	<cfparam name="url.action" type="string" default="">
	<cfparam name="url.type" type="string" default="">
	<cfparam name="url.keywords" type="string" default="">
	<cfparam name="url.label" type="string" default="">
	<cfparam name="url.caption" type="string" default="">
	<cfparam name="url.cacheList" type="string" default="">
	
	<cfif isdefined("url.id")>
	
		<cfset id = url.id>
		
	<cfelseif isdefined("form.spId")>
	
		<cfset id = form.spId>
		
	<cfelse>
	
		<cfset id = "">
	
	</cfif>
	
	<cfif not REFind("^[A-Za-z]{1}[A-Za-z0-9_]+$", url.type)>
		
		<cfthrow message="Invalid type: '#url.type#'">
		
	</cfif>
	
	<cfif listfind("add,edit,delete,promote,demote,history", url.action) eq 0>
	
		<cfthrow message="Action '#url.action#' must be one of add, edit, delete, promote, demote or history">
		
	</cfif>
	
	<cfif action eq "edit" and trim(id) eq "">
	
		<cfthrow message="Cannot find content item to edit">
		
	</cfif>
	
	<cfif url.keywords neq "" and REFind("([[:alpha:].]+[, ]+)*", url.keywords) neq 1>
	
		<cfthrow message="Keywords '#url.keywords#' must be in format key1,key2,...">
	
	</cfif>
	
	<!--- get localised action string... --->
	<cfset actionString = request.speck.buildString("A_ADMIN_ACTION_" & UCase(url.action))>
	
	<!--- get type information --->
	<cfmodule template=#request.speck.getTypeTemplate(url.type)# r_stType="stType">
	
	<cfscript>
		if ( len(trim(url.caption)) )
			caption = url.caption;
		else if ( structKeyExists(stType,"caption") )
			caption = stType.caption;
		else
			caption = stType.description;
			
		if ( isDefined("request.speck.capitalize") ) {
			heading = request.speck.capitalize(actionString & " " & caption);
		} else {
			heading = actionString & " " & caption;
		}
	</cfscript>
	
	<!--- check access control and grant temporary spEdit or spLive as required --->
	<!--- note: this is untested with promotion enabled and probably won't work without further tweaking --->
	
	<cfscript>
		bSuper = request.speck.userHasPermission("spSuper");
		bEditAccess = ( bSuper or request.speck.userHasPermission("spEdit") );
		bLiveAccess = ( bSuper or request.speck.userHasPermission("spLive") );
	</cfscript>
	
	<cfif not bEditAccess>
	
		<!--- user doesn't have site wide edit access, let's see if they get granted edit access from having one of the keyword roles --->
	
		<cfif url.type eq "spKeywords">
		
			<!--- when adding or modify a keyword content item, we need to check whether the user can add within a parent or has one of the roles for the keyword --->
			<cfif url.action eq "add">
			
				<!--- allow access to form when adding - the validateValue method of the Keyword property will prevent users adding a keyword unless they have the correct permission --->
				<cfset bEditAccess = true>
				
			<cfelseif len(id)>
			
				<!--- to modify a keyword, the keyword must exists, it must have a list of roles to which admin access has been grated and the user has to have one of those roles --->
				<cfquery name="qKeyword" dbtype="query">
					SELECT * FROM request.speck.qKeywords WHERE spId = '#id#'
				</cfquery>
					
				<cfif qKeyword.recordCount and len(trim(qKeyword.roles)) and request.speck.userHasPermission(trim(qKeyword.roles))>
				
					<cfset bEditAccess = true>
					
				</cfif>
							
			</cfif>
			
		<cfelse>
		
			<cfset bEditAccess = request.speck.userHasKeywordsPermission(url.keywords)>
			
		</cfif>
	
	</cfif>
	
	<cfscript>
		if ( bEditAccess and not request.speck.enablePromotion ) {
			// both spEdit and spLive are required to edit content with promotioning disabled (content is immediately promoted to live when edited)
			bLiveAccess = true;
		}
		if (bEditAccess) {
			request.speck.session.roles['spEdit'] = "";
		}
		if ( bLiveAccess ) {
			request.speck.session.roles['spLive'] = "";
		}
		bPromoteAccess = ( ( request.speck.session.viewLevel eq "edit" and bEditAccess ) or bLiveAccess );
	</cfscript>
	
	<cfif not request.is_xhr and listFindNoCase("delete,demote,promote",url.action)>

		<cfoutput>
		<html>
		<head>
		<title>#heading#</title>
		<link rel="stylesheet" href="#request.speck.adminStylesheet#" type="text/css">
		</head>
		<body bgcolor="##C0C0C0">
		<h4 align="center">#heading#...</h2>
		</body>
		</html>
		</cfoutput>

	</cfif>
	
	<cfif url.action eq "delete">
		
		<cf_spContentGet type="#url.type#" id="#url.id#" keywords="#url.keywords#" r_qContent="qDeletionCandidate">
		
		<cfif not qDeletionCandidate.recordCount>
		
			<!--- <cf_spError error="A_ADMIN_ACCESS_DENIED" lParams="#actionString#,#url.type#"> --->
			
			<cfthrow message="Cannot delete item with type '#url.type#', id '#url.id#' and keywords '#url.keywords#'. Item cannot be found!">
		
			<cfexit>
			
		</cfif>
					
		<cfif request.speck.enableRevisions and request.speck.types[url.type].revisioned>
		
			<!--- revisions enabled, so promote revision 0 to mark content item as "deleted" --->
			<cfparam name="changeId" default="">
			
			<cfif request.speck.session.viewLevel eq "edit">
				
				<cfif bLiveAccess>
				
					<cfset newLevel = "live">
				
				<cfelse>
				
					<cfset newLevel = "review">
					
				</cfif>
			
			<cfelse>
			
				<cfset newLevel = "live">
			
			</cfif>
			
			<cfif ( newLevel eq "review" and not bPromoteAccess ) or ( newLevel eq "live" and not bLiveAccess )>
		
				<cf_spError error="A_ADMIN_ACCESS_DENIED" lParams="#actionString#,#url.type#">
			
				<cfexit>
				
			</cfif>	
			
			<cf_spPromote
				id = #id#
				type = #url.type#
				revision = 0
				newLevel = #newLevel#
				editor = #request.speck.session.user#
				changeId = #changeId#>
				
			<cfif not request.is_xhr>
			
				<cfoutput>
				<script>
					if (window.opener.closeWindow) {
						window.onload = function(){window.opener.refresh();window.opener.closeWindow(window);}
					} else {
						window.close();	
					}
				</script>
				</cfoutput>
				
			</cfif>
			
			<cfexit>
			
		</cfif>
		
		<!--- live access required to delete content from the live site --->
		<cfif not bLiveAccess>
	
			<cf_spError error="A_ADMIN_ACCESS_DENIED" lParams="#actionString#,#url.type#">
		
			<cfexit>
			
		</cfif>
		
		<!--- 
		Get more info about the content item we're going to delete and make sure it's safe to delete. 
		Note: this code is here rather than in delete methods of spKeywords type and Picker property 
		for two reasons:
		* The spDelete tag fires delete event handlers for the content type and property types 
		  separately, i.e. they are not witihin a single transaction. This is a general issue with 
		  Speck that needs to be addressed at some point.
		* At the moment there is no clean, generic way of sending a error message back to the user 
		  if the delete fails without throwing an exception. The hard-coded javascript below is a 
		  messy hack that'll do the job for the moment. All actions except for edit should be taken 
		  out of this script and moved to something called via an ajax request. 
		--->
		
		<!--- <cfquery name="qDeletionCandidate" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			SELECT * FROM #url.type#
			WHERE spId = '#url.id#'
				AND spRevision = (
					SELECT MAX(spRevision) 
					FROM #url.type#
					WHERE spId = '#url.id#'
				)
		</cfquery> --->
		
		<cfif qDeletionCandidate.recordCount>
	
			<cfif url.type eq "spKeywords">		
				
				<!--- don't allow an application keyword to be deleted if it has descendents --->
				
				<cfquery name="qDescendents" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
					SELECT keyword
					FROM spKeywords
					WHERE keyword LIKE '#qDeletionCandidate.keyword#.%'
					ORDER BY sortId, keyword
				</cfquery>
				
				<cfif qDescendents.recordCount gt 0>
				
					<cfset lDescendents = valueList(qDescendents.keyword)>
					
					<cfset responseText = "Keyword '#qDeletionCandidate.keyword#' cannot be deleted because is has descendents.#nl##nl#Please delete the descendent keywords listed below first:#nl##nl# * #listChangeDelims(lDescendents,"#nl# * ")#">
					
					<cfif request.is_xhr>
					
						<cfheader statuscode="409" statustext="Conflict">
						<cfoutput>#responseText#</cfoutput>
						
					<cfelse>
					
						<cfoutput>
						<script>
						window.onload = function() {
							alert("#jsStringFormat(responseText)#");
							window.opener.closeWindow(window);
						}
						</script>
						</cfoutput>
						
					</cfif>
													
					<cfabort>
					
				</cfif>
				
			<cfelseif not isDefined("url.delete_dependents")>
			
				<!--- don't allow content types that have dependent picked content items be deleted --->
				<cfset lDependents = "">
				<cfset total = 0>
					
				<cfloop from="1" to="#arrayLen(stType.props)#" index="i">
				
					<cfset stPD = stType.props[i]>
					
					<cfif stPD.type eq "Picker" and structKeyExists(stPD,"dependent") and stPD.dependent and len(qDeletionCandidate[stPD.name][1])>
						
						<!--- look for any dependents --->
						<cf_spContentGet type="#stPD.contentType#" id="#qDeletionCandidate[stPD.name][1]#" properties="spId" r_qContent="qPicked">
						
						<cfif qPicked.recordCount>
						
							<cfif qPicked.recordCount gt 1>
								<cfset itemsCaption = qPicked.recordCount & " items">
							<cfelse>
								<cfset itemsCaption = qPicked.recordCount & "item">
							</cfif>
							<cfset lDependents = listAppend(lDependents,replace(stPD.caption,"&nbsp;"," ","all") & " (" & itemsCaption & ")")>
							<cfset total = total + qPicked.recordCount>
						
						</cfif>
					
					</cfif>
				
				</cfloop>
				
				<cfif len(lDependents)>
					
					<cfset responseText = "Deleting this content item will also delete the following dependents:#nl##nl# * #listChangeDelims(lDependents,"#nl# * ")##nl##nl#Are you sure you want to continue?">
					<cfset location = "#cgi.script_name#?#cgi.query_string#&delete_dependents=1">
					
					<cfif request.is_xhr>
					
						<cfheader statuscode="449" statustext="Confirmation Required">
						<cfheader name="location" value="#location#">
						<cfoutput>#responseText#</cfoutput>
						
					<cfelse>
					
						<cfoutput>
						<script>
						window.onload = function() {
							if ( confirm("#jsStringFormat(responseText)#") ) {
								window.location.href = "#location#";
							} else {
								window.opener.closeWindow(window);
							}
						}
						</script>
						</cfoutput>
					
					</cfif>
	
					<cfabort>
				
				</cfif>
			
			</cfif>
			
			<!--- delete the content item --->
			<cf_spDelete id="#id#" type="#url.type#">
			
		</cfif>
		
		<cfif not request.is_xhr>

			<!--- always force reset cache using resetCache function on opener --->
			<cfoutput>
			<script>
				if (window.opener.closeWindow) {
					window.onload = function(){window.opener.resetCache("#URLEncodedFormat(url.cacheList)#");window.opener.closeWindow(window);}
				} else {
					window.close();	
				}
			</script>
			</cfoutput>
		
		</cfif>
		
		<cfexit>
		
	<cfelseif url.action eq "demote">
			
		<cfif not bPromoteAccess>
			
			<cf_spError error="A_ADMIN_ACCESS_DENIED" lParams="#actionString#,#url.type#">
			<!--- <cfthrow message="Access to demote #url.type# denied"> --->
			
			<cfexit>
		
		</cfif>
		
		<cfif len(url.keywords)>
		
			<cf_spContentGet type="#url.type#" keywords="#url.keywords#" id="#url.id#" properties="spId" r_qContent="qKeywordsCheck">
			
			<cfif not qKeywordsCheck.recordCount>
			
				<cf_spError error="A_ADMIN_ACCESS_DENIED" lParams="#actionString#,#url.type#">
			
				<cfexit>
							
			</cfif>
			
		</cfif>
		
		<!--- get current revision at this level --->
		<cf_spRevisionGet
			id=#id#
			type=#url.type#
			level=#request.speck.session.viewLevel#
			r_revision="revision">	
			
		<!--- get previous revision (next revision in history promoted beyond edit level) --->
		<cfquery name="qPreviousRevision" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			SELECT revision, promoLevel, editor
			FROM spHistory
			WHERE id = '#id#' 
				AND ts = (
					SELECT MAX(ts)
					FROM spHistory
					WHERE id = '#id#'
						AND ts < (
							SELECT MAX(ts)
							FROM spHistory
							WHERE id = '#id#'
								AND revision = #revision#
						)
						AND revision <> #revision#
						AND promoLevel > 1
				)
			ORDER BY promoLevel DESC
		</cfquery>			

		<!--- set previous revision number and promo level variables --->
		<cfif qPreviousRevision.recordCount>
		
			<cfset previousRevision = qPreviousRevision.revision>
			<cfset previousPromoLevel = qPreviousRevision.promoLevel>
		
		<cfelse>
		
			<!--- if no previous revision, promote revision 0 through all levels (i.e. use brute force to mark as deleted in history) --->
			<cfset previousRevision = 0>
			<cfset previousPromoLevel = 3>
			
		</cfif>
		
		<cfparam name="changeId" default="">
		
		<!--- promote previous revision from level 1 to whatever the previous promo level for that revision was --->
		<cfloop from="1" to="#previousPromoLevel#" index="thisLevel">
		
			<!--- <cfoutput>promoting revision #previousRevision# to #replaceList(thisLevel,"1,2,3","edit,review,live")#<br></cfoutput> --->

 			<cf_spPromote
				id = #id#
				type = #url.type#
				revision = #previousRevision#
				newLevel = #replaceList(thisLevel,"1,2,3","edit,review,live")#
				editor = #request.speck.session.user#
				changeId = #changeId#>
		
		</cfloop>
		
		<cfif not request.is_xhr>
		
			<cfoutput><script>window.onload = function(){window.opener.refresh();window.opener.closeWindow(window);}</script></cfoutput>
		
		</cfif>
							
		<cfexit>
		
		
	<cfelseif url.action eq "promote">
		
		<cfif not bPromoteAccess>

			<cf_spError error="A_ADMIN_ACCESS_DENIED" lParams="#actionString#,#url.type#">
			<!--- <cfthrow message="Access to promote #url.type# denied"> --->
						
			<cfexit>
		
		</cfif>
		
		<cfif len(url.keywords)>
		
			<cf_spContentGet type="#url.type#" keywords="#url.keywords#" id="#url.id#" properties="spId" r_qContent="qKeywordsCheck">
			
			<cfif not qKeywordsCheck.recordCount>
			
				<cf_spError error="A_ADMIN_ACCESS_DENIED" lParams="#actionString#,#url.type#">
			
				<cfexit>
							
			</cfif>
			
		</cfif>
			
		<cfparam name="changeId" default="">
		
		<cf_spRevisionGet
			id=#id#
			type=#url.type#
			level=#request.speck.session.viewLevel#
			r_revision="revision">
			
		<cfif request.speck.session.viewLevel eq "edit">
			
			<cfif bLiveAccess>
			
				<cfset newLevel = "live">
			
			<cfelse>
			
				<cfset newLevel = "review">
				
			</cfif>
		
		<cfelseif request.speck.session.viewLevel eq "review">
		
			<cfset newLevel = "live">
		
		</cfif>
	
		<cf_spPromote
			id = #id#
			type = #url.type#
			revision = #revision#
			newLevel = #newLevel#
			editor = #request.speck.session.user#
			changeId = #changeId#>
			
		<cfif not request.is_xhr>
		
			<cfif newLevel eq "live">
					
				<!--- also force reset cache using resetCache function on opener --->
				<cfoutput><script>window.onload = function(){window.opener.resetCache("#URLEncodedFormat(url.cacheList)#");window.opener.closeWindow(window);}</script></cfoutput>
				
			<cfelse>
			
				<!--- reload opener --->
				<cfoutput><script>window.onload = function(){window.opener.refresh();window.opener.closeWindow(window);}</script></cfoutput>
			
			</cfif>
			
		</cfif>
			
		<cfexit>
		
	<cfelseif url.action eq "add">

		<cfif len(trim(id))>
			
			<!---  Convert form variables to qContent --->
			<cfscript>
			
				lColumns = "spId,spRevision,spLabel,spCreated,spCreatedBy,spUpdated,spUpdatedby,spKeywords";
				
				for (propertyIndex = 1; propertyIndex le arrayLen(stType.props); propertyIndex = propertyIndex + 1)
					lColumns = listAppend(lColumns, stType.props[propertyIndex].name);
				
				qContent = queryNew(lColumns);
				queryAddRow(qContent, 1);
				
				for (i=1; i lte listLen(form.fieldnames); i = i + 1) {
					propertyKey = listGetAt(form.fieldnames,i);
					if (listFindNoCase(lColumns, propertyKey) neq 0) {
						querySetCell(qContent, propertyKey, trim(evaluate("form.#propertyKey#")), 1);
					}
				}
				
				// if spLabel and/or spKeywords missing in form, use url values...
				if ( not listFindNoCase(form.fieldnames,"spLabel") )
					querySetCell(qContent, "spLabel", trim(url.label), 1);
				if ( not listFindNoCase(form.fieldnames,"spKeywords") )
					querySetCell(qContent, "spKeywords", trim(url.keywords), 1);					
	
			</cfscript>
			
		<cfelse>
		
			<!--- add new content item --->
			<cfset id = createUUID()>
			<cfset stNew = structNew()>
			<cfset stNew.spKeywords = url.keywords>
			<cfset stNew.spLabel = url.label>
			<cfset stNew.spId = id>
			
			<!---  Convert stNew to qContent --->
			<cfscript>
			
				lColumns = "spId,spRevision,spLabel,spCreated,spCreatedBy,spUpdated,spUpdatedBy,spKeywords";
				
				for (propertyIndex = 1; propertyIndex le arrayLen(stType.props); propertyIndex = propertyIndex + 1)
					lColumns = listAppend(lColumns, stType.props[propertyIndex].name);
				
				qContent = queryNew(lColumns);
				queryAddRow(qContent, 1);
		
				for (propertyKey in stNew) {
					if (listFindNoCase(lColumns, propertyKey) neq 0) {
						querySetCell(qContent, propertyKey, trim(stNew[propertyKey]), 1);
					}
				}
	
			</cfscript>
			
			<!--- ugly hack for keywords - I need to come up with some generic way of passing default values --->
			<cfif url.type eq "spKeywords" and cgi.request_method neq "post">
				
				<!--- get parent keyword and pre-populate query --->
				<cfquery name="qParent" dbtype="query">
				
					SELECT roles<cfif isDefined("request.speck.portal")>, groups, spMenu, spSitemap</cfif>
					FROM request.speck.qKeywords 
					<cfif isDefined("url.parent") and len(url.parent)>
						WHERE keyword = '#url.parent#'
					<cfelse>
						WHERE keyword = 'noSuchParentKeyword'
					</cfif>
					
				</cfquery>
				
				<cfscript>
					if ( qParent.recordCount ) {
						for (i=1; i lte listLen(qParent.columnList); i=i+1) {
							querySetCell(qContent, listGetAt(qParent.columnList,i), evaluate("qParent.#listGetAt(qParent.columnList,i)#"), 1);
						}
					}
					if ( isDefined("url.child") ) {
						childName = request.speck.capitalize(url.child,false);
						querySetCell(qContent, "name", childName, 1);
						querySetCell(qContent, "title", childName, 1);
						if ( isDefined("request.speck.portal") ) {
							querySetCell(qContent, "tooltip", childName, 1);
						}
					}
				</cfscript>

			</cfif>
		
		</cfif>
		
	</cfif>
		
	<cfoutput>
	<html>
	<head>
	<title>#heading#</title>
	<link rel="stylesheet" href="#request.speck.adminStylesheet#" type="text/css">
	<script src="/speck/javascripts/prototype.js" type="text/javascript"></script>
	<script src="/speck/javascripts/scriptaculous.js" type="text/javascript"></script>
	<script type="text/javascript">
		// keep session alive while user is in add/edit window
		new PeriodicalExecuter( function() {
		  new Ajax.Request("/speck/admin/session/keepalive.cfm?app=#request.speck.appName#", { method:'get' });
		}, 300 );	
		
		function resizeWindow() {
			var clientWidth = 0;
			var windowWidth = 600;
			var windowHeight = 600;
			if ( document.forms[0] && typeof document.forms[0].offsetWidth == 'number'  ) {
				if ( typeof window.innerWidth == 'number' ) {
					//Non-IE
					clientWidth = window.innerWidth;
				} else {
					if ( document.documentElement && document.documentElement.clientWidth ) {
						//IE 6+ in 'standards compliant mode'
						clientWidth = document.documentElement.clientWidth;
					} else {
						if ( document.body && document.body.clientWidth ) {
							//IE 4 / IE 5
							clientWidth = document.body.clientWidth;
						}
					}
				}
				// note: add 10 to required width because the value of the offsetWidth property 
				// for the form seems to just be the largest offsetWidth property in the collection 
				// of form elements and the form elements are inside a table
				var requiredWidth = document.forms[0].offsetLeft + document.forms[0].offsetWidth + 10;
				// if we managed to determine the client width and it's not enough, resize the window
				if ( clientWidth > 0 && requiredWidth > clientWidth ) {
					windowWidth = 600 + (requiredWidth - clientWidth);
				}
			}
			try {
				window.resizeTo(windowWidth, windowHeight);
			} catch(e) { 
				// do nothing 
			}
		}
	</script>
	</head>
	
	<!--- <body onLoad="resizeWindow();"> --->
	<body>
	</cfoutput>

	<cfif bEditAccess>
	
		<cfset speck = structNew()>
	
		<!--- save content for use in layout file --->
		<cfsavecontent variable="speck.layout">
	
			<cfif url.action eq "history">
			
				<!--- call history tag, doing this here so we can re-use edit access control code --->
				
				<cfmodule template="/speck/api/content/spContentHistory.cfm"
					id=#id#
					type=#url.type#
					displayPerPage="25">
					
			<cfelse>
			
				<!--- add/edit content item --->
				
				<cfif isDefined("qContent")>
					
					<!--- adding content, pass qContent to spContent --->
					
					<cf_spContent id="#id#" type="#url.type#" method="spEdit" enableAdminLinks="no" qContent="#qContent#">
					
				<cfelseif isDefined("url.revision")>
				
					<!--- loading an old revision, pass revision to spContent --->
				
					<cfif url.revision neq "tip">
			
						<cfset url.revision = int(val(url.revision))>
				
					</cfif>
				
					<cf_spContent id="#id#" type="#url.type#" method="spEdit" enableAdminLinks="no" revision="#url.revision#">
				
				<cfelse>
				
					<!--- edit --->
					
					<cf_spContent id="#id#" type="#url.type#" method="spEdit" enableAdminLinks="no">
					
				</cfif>
	
			</cfif>
			
		</cfsavecontent>
		
		<!--- include layout file if defined --->
		<cfif isDefined("request.speck.adminLayout") and len(request.speck.adminLayout)>
		
			<!--- todo: add try/catch and handle missingInclude exception with spError --->
			<cfif left(request.speck.adminLayout,1) eq "/">
			
				<!--- assume value is complete path to template --->
				<cfinclude template="#request.speck.adminLayout#">
				
			<cfelse>
			
				<!--- assume value matches a file in /webapps/speck/www/admin/layouts/ minus the .cfm extension --->
				<cfinclude template="layouts/#request.speck.adminLayout#.cfm">
			
			</cfif>
		
		<cfelse>
		
			<cfoutput>#speck.layout#</cfoutput>
		
		</cfif>
		
	<cfelse>
	
		<cf_spError error="A_ADMIN_ACCESS_DENIED" lParams="edit,#url.type#">
		<!--- <cfthrow message="Access to #request.speck.session.viewLevel# #url.type# denied"> --->
		
	</cfif>
			
	<cfoutput>
	<script type="text/javascript" src="/speck/javascripts/wz_tooltip.js"></script>
	</body>
	</html>
	</cfoutput>
	
<cfcatch type="any">
	
	<cfif request.is_xhr>
	
		<!--- TODO: STRIP HTML --->
		<cfheader statuscode="500" statustext="#cfcatch.message#">
		<cfoutput>#cfcatch.detail#</cfoutput>
	
	<cfelse>
		
		<!--- workaround for CFMX cfcatch bug (cfcatch not always a structure) --->
		<cfscript>
			stError = structNew();
			stError.type = cfcatch.type;
			stError.message = cfcatch.message;
			stError.detail = cfcatch.detail;
			if ( isDefined("cfcatch.errorCode") )
				stError.errorCode = cfcatch.errorCode;
			if ( isDefined("cfcatch.tagContext") )
				stError.tagContext = duplicate(cfcatch.tagContext);
			if ( isDefined("cfcatch.extendedInfo") )
				stError.extendedInfo = cfcatch.extendedInfo;
		</cfscript>

		<cfdump var=#stError#>
		
		<cfif cfcatch.type eq "speckError">
	
			<!--- a little bit more user-friendly --->
			<cfoutput><script>alert("#jsStringFormat(replace(cfcatch.detail,". ",".#chr(13)##chr(10)#","all"))#");</script></cfoutput>
		
		</cfif>
		
	</cfif>
	
	<cfsilent>
		
		<!--- allow site wide error handler send notifications --->
		<cfrethrow>
		
	</cfsilent>	

</cfcatch>

</cftry>
