<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- render admin links --->

<cfscript>	
	// get label and keywords strings that are safe to pass as string arguments to JavaScript functions...
	jsSafeLabel = urlEncodedFormat(jsStringFormat(caller.caller.content.spLabel));
	jsSafeKeywords = urlEncodedFormat(jsStringFormat(caller.caller.content.spKeywords));
	jsSafeCaption = urlEncodedFormat(jsStringFormat(caller.caller.caller.caption));
	jsSafeCacheList = urlEncodedFormat(caller.caller.caller.lCacheNames);
	
	// content highlighting onmouseover/onmouseout
	highlightOn = "parentNode.parentNode.className = 'spContentAdmin spClearfix spContentHighlight';";
	highlightOff = "parentNode.parentNode.className = 'spContentAdmin spClearfix';";
	highlightWarning = "parentNode.parentNode.className = 'spContentAdmin spClearfix spContentWarning';";
	
	// stStrings references request.speck.spContent.strings, just makes the code a bit easier to read and maintain
	stStrings = request.speck.spContent.strings;
	
	caption = caller.caller.caller.caption;
</cfscript>

<cfif caller.caller.caller.bShowEditAdmin>

	<cfoutput><span class="spAdminLinks"></cfoutput>

	<cfoutput><a onmouseover="#highlightOn#" 
		onmouseout="#highlightOff#" 
		href="javascript:launch_edit('#caller.caller.attributes.type#','#caller.caller.content.spId#', '#jsSafeKeywords#', '#jsSafeCacheList#', '#jsSafeCaption#');" 
		title="#stStrings.edit# #caption#"
		class="spAdminLink spEdit">#stStrings.edit#</a>&nbsp;
	<a onmouseover="#highlightWarning#" 
		onmouseout="#highlightOff#" 
		href="javascript:launch_delete('#caller.caller.attributes.type#','#caller.caller.content.spId#', '#jsSafeLabel#', '#jsSafeKeywords#', '#jsSafeCacheList#', '#jsSafeCaption#');"
		title="#stStrings.delete# #caption#"
		class="spAdminLink spAdminWarning spDelete">#stStrings.delete#</a></cfoutput>
		
	<cfoutput></span></cfoutput>
	
<cfelseif caller.caller.caller.bShowEditPromoAdmin>

	<!--- check if removed --->
	<cfquery name="qCheckRemoved" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		SELECT revision, promoLevel
		FROM spHistory
		WHERE id = '#caller.caller.content.spId#' 
			AND ts = (
				SELECT MAX(ts)
				FROM spHistory
				WHERE id = '#caller.caller.content.spId#'
					AND promoLevel = 1
			)
		ORDER BY promoLevel DESC
	</cfquery>

	<cfif qCheckRemoved.recordCount and qCheckRemoved.revision eq 0>
	
		<!--- removed --->
		<cfoutput>
		<span class="spAdminLinks spWarning">
		<a onmouseover="#highlightWarning#" 
			onmouseout="#highlightOff#" 
			href="javascript:launch_promote('#caller.caller.attributes.type#','#caller.caller.content.spId#', '#jsSafeLabel#', '#jsSafeKeywords#', '#jsSafeCacheList#', '#jsSafeCaption#')" 
			title="#stStrings.promote# #caption# (#stStrings.forRemoval#)"
			class="spAdminLink spAdminWarning spPromote">#stStrings.promote#</a>
		<a onmouseover="#highlightWarning#" 
			onmouseout="#highlightOff#" 
			href="javascript:launch_demote('#caller.caller.attributes.type#','#caller.caller.content.spId#', '#jsSafeLabel#', '#jsSafeKeywords#', '#jsSafeCacheList#', '#jsSafeCaption#')" 
			title="#stStrings.demote# #caption# (#stStrings.forRemoval#)"
			class="spAdminLink spAdminWarning spDemote">#stStrings.demote#</a>
		</span>
		</cfoutput>
		
	<cfelse>
	
 		<!--- check if content is at edit level for some other user --->
		<cfquery name="qCheckEditPermission" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			SELECT *
			FROM spHistory
			WHERE id = '#caller.caller.content.spId#'
				AND ts = (
					SELECT MAX(ts)
					FROM spHistory
					WHERE id = '#caller.caller.content.spId#'
						AND promoLevel <> 3
				)
			ORDER BY promoLevel DESC
		</cfquery>

		<!--- if the content has not been promoted beyond edit level, user must be owner to edit --->
		<cfif qCheckEditPermission.promoLevel eq 1 and trim(qCheckEditPermission.editor) neq request.speck.session.user>
		
			<!--- keep an eye on this call to spUserGet, could be ditched to improve performance --->
			<cf_spUserGet
				user=#trim(qCheckEditPermission.editor)#
				r_stUser="stEditor">
				
			<cfscript>
				if ( isDefined("stEditor") and len(trim(stEditor.fullName)) ) {
					editorName = stEditor.fullname;
					editorEmail = stEditor.email;
				} else
					editorName = trim(qCheckEditPermission.editor);
					
				jsCannotModMsg = "This content item has been checked out for editing by #editorName#.\n\nYou cannot modify this content item until #editorName# has promoted his/her modifications to review level.";

				if ( isDefined("editorEmail") and len(editorEmail) )
					jsCannotModMsg = jsCannotModMsg & "\n\n#editorName# can be contacted at #editorEmail#";			
			</cfscript>
		
			<!--- show links with line through to indicate action is not available --->
			<cfoutput><span class="spAdminLinks"></cfoutput>
			<cfoutput><a style="text-decoration:line-through;" class="spAdminLink spEdit" onmouseover="#highlightOn#" onmouseout="#highlightOff#" href="javascript:alert('#jsCannotModMsg#')">#stStrings.edit#</a>&nbsp;</cfoutput>
			<cfoutput><a style="text-decoration:line-through;" class="spAdminLink spAdminWarning spDelete" onmouseover="#highlightWarning#" onmouseout="#highlightOff#" href="javascript:alert('#jsCannotModMsg#');">#stStrings.delete#</a></cfoutput>
			<cfoutput></span></cfoutput>
			
		<cfelse>
		
			<!--- check if current revision has been promoted... --->
			<cfquery name="qLatestPromotion" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
				SELECT promoLevel
				FROM spHistory
				WHERE id = '#caller.caller.content.spId#'
					AND ts = (
						SELECT MAX(ts)
						FROM spHistory
						WHERE id = '#caller.caller.content.spId#'
							AND revision = #caller.caller.content.spRevision#
					)
				ORDER BY promoLevel DESC
			</cfquery>
			
			<!--- <cfdump var=#qLatestPromotion#> --->
			<cfoutput><span class="spAdminLinks"></cfoutput>
			<cfoutput><a onmouseover="#highlightOn#" 
				onmouseout="#highlightOff#" 
				href="javascript:launch_edit('#caller.caller.attributes.type#','#caller.caller.content.spId#', '#jsSafeKeywords#', '#jsSafeCacheList#', '#jsSafeCaption#')"
				title="#stStrings.edit# #caption#"
				class="spAdminLink spEdit">#stStrings.edit#</a>&nbsp;</cfoutput>
			<cfif qLatestPromotion.promoLevel eq 1>
				<cfoutput>
				<a onmouseover="#highlightOn#" 
					onmouseout="#highlightOff#" 
					href="javascript:launch_promote('#caller.caller.attributes.type#','#caller.caller.content.spId#', '#jsSafeLabel#', '#jsSafeKeywords#', '#jsSafeCacheList#', '#jsSafeCaption#')" 
					title="#stStrings.promote# #caption#"
					class="spAdminLink spPromote">#stStrings.promote#</a>&nbsp;
				<a onmouseover="#highlightWarning#" 
					onmouseout="#highlightOff#" 
					href="javascript:launch_demote('#caller.caller.attributes.type#','#caller.caller.content.spId#', '#jsSafeLabel#', '#jsSafeKeywords#', '#jsSafeCacheList#', '#jsSafeCaption#')" 
					title="#stStrings.demote# #caption#"
					class="spAdminLink spAdminWarning spDemote">#stStrings.demote#</a>
				</cfoutput>
			<cfelse>
				<!--- don't allow a removal without a promotion first, users can still "demote" unpromoted revisions which effectively deletes them --->
				<cfoutput>
				<a onmouseover="#highlightWarning#" 
					onmouseout="#highlightOff#" 
					href="javascript:launch_delete('#caller.caller.attributes.type#','#caller.caller.content.spId#', '#jsSafeLabel#', '#jsSafeKeywords#', '#jsSafeCacheList#', '#jsSafeCaption#');" 
					title="#stStrings.delete# #caption#"
					class="spAdminLink spAdminWarning spDelete">#stStrings.delete#</a>
				</cfoutput>
			</cfif>
			<cfoutput></span></cfoutput>
			
		</cfif>
		
	</cfif>

<cfelseif caller.caller.caller.bShowReviewAdmin>

	<!--- check if removed --->			
	<cfquery name="qCheckRemoved" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		SELECT revision
		FROM spHistory
		WHERE id = '#caller.caller.content.spId#' 
			AND ts = (
				SELECT MAX(ts)
				FROM spHistory
				WHERE id = '#caller.caller.content.spId#'
					AND promoLevel = 2
			)
	</cfquery>

	<cfif qCheckRemoved.recordCount and qCheckRemoved.revision eq 0>
	
		<cfoutput>
		<span class="spAdminLinks spWarning">
		<a title="#stStrings.forRemoval#" 
			onmouseover="#highlightWarning#" 
			onmouseout="#highlightOff#" 
			href="javascript:launch_edit('#caller.caller.attributes.type#','#caller.caller.content.spId#', '#jsSafeKeywords#', '#jsSafeCacheList#', '#jsSafeCaption#')"
			title="#stStrings.review# #caption# (#stStrings.forRemoval#)"
			class="spAdminLink spAdminWarning spReview">#stStrings.review#</a>&nbsp;
		<a title="#stStrings.forRemoval#" 
			onmouseover="#highlightWarning#" 
			onmouseout="#highlightOff#" 
			href="javascript:launch_promote('#caller.caller.attributes.type#','#caller.caller.content.spId#', '#jsSafeLabel#', '#jsSafeKeywords#', '#jsSafeCacheList#', '#jsSafeCaption#')" 
			title="#stStrings.promote# #caption# (#stStrings.forRemoval#)"
			class="spAdminLink spAdminWarning spPromote">#stStrings.promote#</a>&nbsp;
		<a title="#stStrings.forRemoval#" 
			onmouseover="#highlightWarning#" 
			onmouseout="#highlightOff#" 
			href="javascript:launch_demote('#caller.caller.attributes.type#','#caller.caller.content.spId#', '#jsSafeLabel#', '#jsSafeKeywords#', '#jsSafeCacheList#', '#jsSafeCaption#')" 
			title="#stStrings.demote# #caption# (#stStrings.forRemoval#)"
			class="spAdminLink spAdminWarning spDemote">#stStrings.demote#</a>
		</span>
		</cfoutput>
		
	<cfelse>
	
		<!--- check if current revision has been promoted... --->
		<cfquery name="qLatestPromotion" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			SELECT promoLevel
			FROM spHistory
			WHERE id = '#caller.caller.content.spId#'
				AND ts = (
					SELECT MAX(ts)
					FROM spHistory
					WHERE id = '#caller.caller.content.spId#'
						AND revision = #caller.caller.content.spRevision#
				)
			ORDER BY promoLevel DESC
		</cfquery>
	
		<cfif qLatestPromotion.promoLevel eq 2>
			<cfoutput>
			<span class="spAdminLinks">
			<a onmouseover="#highlightOn#" 
				onmouseout="#highlightOff#" 
				href="javascript:launch_edit('#caller.caller.attributes.type#','#caller.caller.content.spId#', '#jsSafeKeywords#', '#jsSafeCacheList#', '#jsSafeCaption#')"
				title="#stStrings.review# #caption#"
				class="spAdminLink spReview">#stStrings.review#</a>&nbsp;
			<a onmouseover="#highlightOn#" 
				onmouseout="#highlightOff#" 
				href="javascript:launch_promote('#caller.caller.attributes.type#','#caller.caller.content.spId#', '#jsSafeLabel#', '#jsSafeKeywords#', '#jsSafeCacheList#', '#jsSafeCaption#')" 
				title="#stStrings.promote# #caption#"
				class="spAdminLink spPromote">#stStrings.promote#</a>&nbsp;
			<a onmouseover="#highlightWarning#"
				onmouseout="#highlightOff#" 
				href="javascript:launch_demote('#caller.caller.attributes.type#','#caller.caller.content.spId#', '#jsSafeLabel#', '#jsSafeKeywords#', '#jsSafeCacheList#', '#jsSafeCaption#')" 
				title="#stStrings.demote# #caption#"
				class="spAdminLink spAdminWarning spDemote">#stStrings.demote#</a>
			</span>
			</cfoutput>
		</cfif>
		
	</cfif>
	
</cfif>