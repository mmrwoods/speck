<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!---
Description:

	Insert record(s) into spHistory to record promotion of a revision of content to a promotion level.

Usage:

	<cf_spPromote
		id = "uuid"
		type = "string"
		revision = integer
		newLevel = "edit|review|live"
		editor = "string"
		changeId = "string or uuid">
	
Attributes:	
	
	id(uuid, required):					Content id.
	type(string, required):				Content item type.
	revision(number, required):			Content revision.
	newLevel(string, required):			Level to promote content revision to.  If promotion enabled and promoting
										edit revision to live, an intermediate review promotion will be created.
	editor(string, optional):			Defaults to request.speck.session.user.
	changeId(uuid or string, optional):	Required if change control enabled.
--->

<cfif not request.speck.enableRevisions>

	<cf_spError error="PR_NO_REVISIONS">	<!--- Cannot promote application content when revisioning disabled for application --->

</cfif>

<!--- Validate attributes --->
<cfloop list="id,type,revision,newLevel" index="attribute">

	<cfif not isdefined("attributes.#attribute#")>
	
		<cf_spError error="ATTR_REQ" lParams="#attribute#">	<!--- Missing attribute --->
		
	</cfif>

</cfloop>

<cfif listFindNoCase("edit,review,live", attributes.newLevel) eq 0>

	<cf_spError error="ATTR_INV" lParams="#attributes.newLevel#,newLevel">

</cfif>

<cfif attributes.newLevel neq "live" and not request.speck.enablePromotion>

	<cf_spError error="PR_LIVE_ONLY" >	<!--- Cannot promote application content to edit or review when promotion disabled for application --->

</cfif>

<cfparam name="attributes.editor" default=#request.speck.session.user#>

<cfif request.speck.enableChangeControl>

	<!--- Validate changeId attribute --->
	
	<cfif not isdefined("attributes.changeId")>

		<cf_spError error="ATTR_REQ" lParams="changeId">	<!--- Missing attribute --->
	
	</cfif>
	
	<cfset bChangeControlError = false>
	<cfset changeId = attributes.changeId>
	
	<cfif request.speck.isUUID(changeId)>
	
		<!--- Look up and validate the change object --->
		<cf_spContentGet type="change" id=#attributes.changeId# r_qContent="qChangeObject">
		
		<cfif qChangeObject.recordCount neq 1>
		
			<cfset bChangeControlError = true>
		
		<cfelse>
		
			<!--- Change must be owned by user and in edit state --->
			<cfif not (qChangeObject.owner eq #attributes.user# and qChangeObject.state eq "edit")>
			
				<cfset bChangeControlError = true>
			
			</cfif>
		
		</cfif>
		
	<cfelseif changeId eq "spSystem">
	
		<!--- "spSystem" is temporary change used by automated tasks.  No corresponding change object created --->
		
	<cfelseif changeId eq "">
	
		<cfset bChangeControlError = true>
		
	<cfelse>
	
		<!--- Create the change object --->
		<cfset changeId = "newly created change id">
	
	</cfif>
	
	<cfif bChangeControlError>
	
		<cf_spError error="ATTR_INV" lParams="changeId,#attributes.changeId#">
	
	</cfif>

<cfelse>

	<cfset changeId = "">

</cfif>

<!--- Calculate range of promotions to insert --->
<cfset targetLevel = listFindNoCase("edit,review,live", attributes.newLevel)>

<cfif attributes.revision eq 0>

	<!--- deletions need to be the latest entries in the history table at all levels --->
	<cfset firstPromotion = listFindNoCase("edit,review,live", request.speck.session.viewLevel)>

<cfelseif request.speck.enablePromotion>

	<!--- set table alias keyword (Access requires the use of AS) --->
	<cfset ta = request.speck.database.tableAliasKeyword>

	<!--- What level is revision currently at, if any? --->
	<cfquery name="qGetLevel" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		SELECT	latestPromotionLevel.promoLevel as promoLevel, latestPromotionLevel.ts as ts
		FROM	spHistory #ta# latestPromotionLevel
		WHERE	latestPromotionLevel.id = '#attributes.id#' AND
				latestPromotionLevel.revision = #attributes.revision# AND
				latestPromotionLevel.ts =
				(
					SELECT	max(latestPromotion.ts)
					FROM	spHistory #ta# latestPromotion
					WHERE	latestPromotionLevel.id = latestPromotion.id AND
							latestPromotionLevel.revision = latestPromotion.revision
					<!--- GROUP BY latestPromotion.id --->
				)
		ORDER BY latestPromotionLevel.ts DESC, latestPromotionLevel.promoLevel DESC <!--- quick fix to allow rollback, re-visit to ensure only one row is ever returned --->
	</cfquery>
	
	<!--- <cfdump var=#qGetLevel#> --->
	
	<cfif qGetLevel.recordCount eq 0>
	
		<cfset currentLevel = 0>
	
	<cfelse>
	
		<cfset currentLevel = qGetLevel.promoLevel[1]>
		
		<!--- <cfoutput>currentLevel = #currentLevel#<br></cfoutput> --->
	
	</cfif>
	
	<!--- currentLevel now 0 (nowhere), 1 (edit) 2 (review) or 3 (live) --->
	
	<cfset firstPromotion = currentLevel + 1>
	
<cfelse>

	<!--- Go straight to live --->
	<cfset firstPromotion = 3>

</cfif>

<cfif request.speck.enableChangeControl>

	<cfset changeValue = "'" & changeId & "'">
	
<cfelse>

	<cfset changeValue = "NULL">
	
</cfif>

<!--- get type info --->
<cfmodule template=#request.speck.getTypeTemplate(attributes.type)# r_stType="stType">

<cfif firstPromotion gt targetLevel>
	
	<!--- quick fix to allow rollback (allows non-tip revisions which have 
		previously been promoted past the target level to promoted to the target level) --->
	<cfset firstPromotion = targetLevel>
	
</cfif>

<!--- we need to send the content query to the promote methods for the content type and property types --->
<cfquery name="qContent" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
	SELECT * FROM #attributes.type#
	WHERE spId = '#attributes.id#'
		AND spRevision = 
		<cfif attributes.revision eq 0>
			<!--- there is no revision 0 in the content table, so get the latest revision --->
 			( SELECT MAX(spRevision) FROM #attributes.type# WHERE spId = '#attributes.id#' )
		<cfelse>
			#attributes.revision#
		</cfif>
</cfquery>

<cfloop from=#firstPromotion# to=#targetLevel# index="level">
	
	<cftransaction isolation="serializable">
	
		<cfquery name="qInsertPromotion" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			INSERT INTO spHistory (id,revision,contentType,promoLevel,editor,changeId,ts)
			VALUES ('#attributes.id#', #attributes.revision#, '#attributes.type#', #level#, '#attributes.editor#', #changeValue#, #createODBCDateTime(now())#)
		</cfquery>
		
		<!--- archive existing revision at this level --->
		<cfquery name="qUpdateLevel" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			UPDATE #attributes.type# 
			SET spArchived = #createODBCDateTime(now())#
			WHERE spId = '#qContent.spId#'
				AND spLevel = #level#
				AND spArchived IS NULL
		</cfquery>
		
		<cfif attributes.revision neq 0>
			
			<!--- update the row in the content table for this revision - set the level to the current level and set the archived date to null --->
			<cfquery name="qUpdateLevel" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
				UPDATE #attributes.type# 
				SET spLevel = #level#, 
					spArchived = NULL
				WHERE spId = '#qContent.spId#' 
					AND spRevision = #attributes.revision#
			</cfquery>
			
		</cfif>

	</cftransaction>

</cfloop>

<!--- run promote handlers for the target level only (this is a big change and I'm not sure how this will affect things like the auto promote feature of the picker property) --->

<!--- Run the type's promote handler --->
<cfif structKeyExists(stType.methods, "promote")>

	<!--- call handler with promote method --->
	<cfmodule template=#stType.methods.promote#
		qContent=#qContent#
		type=#attributes.type#
		method="promote"
		revision=#attributes.revision#
		newLevel=#attributes.newLevel#>

</cfif>
	
<cfloop from=1 to=#arrayLen(stType.props)# index="prop">

	<cfset stPD = stType.props[prop]>
	
	<cfif structKeyExists(stPD.methods, "promote")>
	
		<!--- property has a promote method, run the handler with this method --->
		<cfmodule template=#stPD.methods.promote#
			method="promote"
			stPD=#stPD#
			value=#qContent[stPD.name][1]#
			id=#attributes.id#
			type=#attributes.type#
			revision=#attributes.revision#
			newLevel=#attributes.newLevel#>
			
	</cfif>
	
</cfloop>

<cfif attributes.newLevel eq "live">

	<!--- update the keywords index --->
	<cfquery name="qDeleteKeywords" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		DELETE FROM spKeywordsIndex
		WHERE id = '#attributes.id#'
	</cfquery>
	<cfif len(qContent.spKeywords)>
		<cfloop list="#qContent.spKeywords#" index="keyword">
			<cfquery name="qInsertKeyword" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
				INSERT INTO spKeywordsIndex (contentType, keyword, id)
				VALUES ('#uCase(stType.name)#', '#uCase(trim(keyword))#', '#attributes.id#' )
			</cfquery>
		</cfloop>
	</cfif>
	
	<cfif attributes.revision eq 0>
	
		<!--- delete from content index --->
		<cfquery name="qDelete" datasource="#request.speck.codb#">
			DELETE FROM spContentIndex WHERE id = '#attributes.id#'
		</cfquery>		
	
	<cfelseif structKeyExists(stType,"contentIndex")>
	
		<!--- update content index --->
		<cfscript>
			stContentIndex = structNew();
			if ( isDefined("qContent.#stType.contentIndex.date#") ) {
				stContentIndex.date = evaluate("qContent.#stType.contentIndex.date#");
			}
			if ( not structKeyExists(stContentIndex,"date") or not len(stContentIndex.date) ) {
				stContentIndex.date = spCreated;
			}
			stContentIndex.title = "";
			for (i=1; i le listLen(stType.contentIndex.title); i=i+1) {
				stContentIndex.title = stContentIndex.title & evaluate("qContent.#listGetAt(stType.contentIndex.title,i)#") & " ";
			}
			stContentIndex.description = "";
			for (i=1; i le listLen(stType.contentIndex.description); i=i+1) {
				stContentIndex.description = stContentIndex.description & evaluate("qContent.#listGetAt(stType.contentIndex.description,i)#") & " ";
			}
			stContentIndex.body = "";
			for (i=1; i le listLen(stType.contentIndex.body); i=i+1) {
				stContentIndex.body = stContentIndex.body & evaluate("qContent.#listGetAt(stType.contentIndex.body,i)#") & " ";
			}						
		</cfscript>
					
		<cftry>
			
			<cf_spContentIndex 
				type="#attributes.type#"
				id="#attributes.id#"
				keyword="#qContent.spKeywords#"
				attributeCollection="#stContentIndex#">
					
		<cfcatch type="SpeckError">
			<!--- do nothing, an expected error condition only means that this content item isn't suitable for indexing --->
			<!--- TODO: log message --->
		</cfcatch>
		</cftry>		
		
	</cfif>

	<!--- flush the cache if promoting to live --->
	<cfmodule template="/speck/api/content/spFlushCache.cfm"
		type=#attributes.type#
		id=#attributes.id#
		label=#qContent.spLabel#
		keywords=#qContent.spKeywords#>

</cfif>
