<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!---
Description:

	Save one or more items of content.  This tag contains the bulk of the logic that makes the four modes of
	revisioning and promotion possible:
	
	1) No Revision or Promotion (application wide setting or per type setting)
	-	Once revision 1 is created new saves overwrite existing data, no promotion record is kept in spHistory.
	
	2) Revision only
	-	Every save creates a new revision and a promotion to live in spHistory, so you can still retrieve content
		at an effective date.
	
	3) Revision and Promotion
	-	If the existing revision has ever been promoted to review or live, a new revision is created and promoted to
		edit level.  If it has been promoted to edit then only the author or system can save over the existing data.
		This not only allows an editor to make multiple saves of a content item during editing without clogging up
		spHistory, but also makes sure that once a revision is reviewed or live it cannot be written over.
		
	4) Revision and Promotion and Change Control
	-	In addition to the Revision and Promotion procedure, content items can only be saved if a valid change id 
		or new change label is specified.  A valid change is one that is owned by the current user and is in an edit
		state.  There is also a special "system" change that can be used for automated/bulk migrations.
	
	The sequence of processing to achieve the above behaviour is as follows:
	
	-	Check application and type revision/promotion settings.	
	-	User needs spEdit (promotion enabled) or spLive (promotion disabled) permission.
	-	If change control enabled a valid change id must be provided.
	-	For each content item:
		-	Check to see if content item already exists.
		-	Check that content item can be updated:
			-	If revision enabled current revision must be tip (no branching allowed).
			-	If promotion enabled current revision must be
				-	live, or
				-	edit, with the current user or spSystem as the author.
		-	Generate UUID for new content items without UUIDs.
		-	Determine next revision number, if the content item already exists and:
			-	Revision disabled, or
			-	Promotion enabled and current revision never promoted to review or live
			
			the revision number stays the same, otherwise the revision number is increased by 1.
			
	-	Run the type's contentPut handler.
	-	For each property, run the property handler's contentPut action.
	-	If revision number the same update the current database record, otherwise insert a new
		record.
	-	If new revision number and revision enabled and
		-	Promotion disabled, promote the new revision to live.
		-	Promotion enabled, promote the new revision to edit.
		(The cf_promote tag will create a change, record the changeid and editor in spHistory and
		call property handler promote action)
	
Usage:

	<cf_spContentPut
		qContent=query
		stContent=structure
		type="string" 
		changeId="uuid or string"
		userid="string">
	
Attributes:	

	qContent(query, optional):			Either this or stContent required.  Query containing content items to update.  
										Following notes apply to query columns:
										spId:		Can be left blank for new content items.
										spRevision:	Update will fail if this isnt the tip revision.  Use value from contentGet
													or leave blank, in which case revision at current viewLevel will be used 
													for existing content items.
										spLabel:	Required.
										spKeywords:	Will be validated and sorted.  Invalid keywords ignored.
										spChangeId: Specify in separate changeId attribute for all content items.
										Other sp* fields are ignored by contentPut.
										
	stContent(structure, optional):		Either this or qContent required.  Structure containing keys for each property value of a single
										content item, notes for qContent apply to keys.
	type(string, required):				Name of content type of content items being saved.
	changeId(uuid or string, optional):	Required if change control enabled.  Three possible values:
										uuid:		Id of existing change object in edit state, owned by user.  The change is checked
													for state and ownership.
										"spSystem":	placeholder change for automated bulk updates etc.
										other:		Label of a new change to be created.
										
	user(string, optional):				Will default to current user. User must have spEdit permission, otherwise the tag throws an error.
										Can specify "spSystem" for automated tasks.

--->
 
<!--- Validate attributes --->
<cf_spDebug msg="Attributes" dmp=#attributes#>

<cfif not (isdefined("attributes.qContent") or isdefined("attributes.stContent"))>
	
		<cf_spError error="ATTR_REQ" lParams="qContent or stContent">	<!--- Missing attribute --->
		
</cfif>

<cfif isdefined("attributes.qContent") and isdefined("attributes.stContent")>
	
		<cf_spError error="ATTR_MUTEX" lParams="qContent,stContent">		<!--- Mutually exclusive attributes --->
		
</cfif>

<cfif request.speck.enableChangeControl and not isdefined("attributes.changeId")>

	<cf_spError error="ATTR_REQ" lParams="changeId">						<!--- Missing attribute --->

</cfif>

<!--- Check application and type revision/promotion settings --->
<cfmodule template=#request.speck.getTypeTemplate(attributes.type)# r_stType="stType">

<cfset bRevision = request.speck.enableRevisions and stType.revisioned>
<cfset bPromotion = request.speck.enablePromotion>
<cfset bChangeControl = request.speck.enableChangeControl>

<!--- Validate User --->
<cfparam name="attributes.user" default=#request.speck.session.user#>

<cfif attributes.user neq "spSystem">

	<cfif attributes.user neq request.speck.session.user>
	
		<cf_spUserGet user=#attributes.user# r_stUser="stUser">
	
	<cfelse>
	
		<cfset stUser = request.speck.session>
		
	</cfif>

	<cfif not structKeyExists(stUser.roles, "spSuper")>
	
		<!--- User needs spEdit (promotion enabled) or spLive (promotion disabled) permission --->
		
		<cfif bPromotion and (not structKeyExists(stUser.roles, "spEdit"))>
		
			<cf_spError error="CP_USER_NO_PERM" lParams="#attributes.user#,SPEDIT">
		
		<cfelseif (not bPromotion) and (not structKeyExists(stUser.roles, "spLive"))>
		
			<cf_spError error="CP_USER_NO_PERM" lParams="#attributes.user#,SPLIVE">
		
		</cfif>	
	
	</cfif>
	
</cfif>

<cfif bChangeControl>

	<!--- Validate changeId attribute --->
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
	
	</cfif>
	
	<cfif bChangeControlError>
	
		<cf_spError error="ATTR_INV" lParams="#attributes.changeId#,changeId">
	
	</cfif>

</cfif>

<!---  Convert stContent to qContent --->
<cfscript>

	lColumns = "spId,spRevision,spLabel,spCreated,spCreatedby,spUpdated,spUpdatedBy,spKeywords,spSequenceId";
	
	for (propertyIndex = 1; propertyIndex le arrayLen(stType.props); propertyIndex = propertyIndex + 1)
		lColumns = listAppend(lColumns, stType.props[propertyIndex].name);
	
	// If stContent passed, convert it to query
	
	if (isDefined("attributes.stContent")) {
	
		qContent = queryNew(lColumns);
		queryAddRow(qContent, 1);

		for (propertyKey in attributes.stContent) {
			if (listFindNoCase(lColumns, propertyKey) neq 0) {
				querySetCell(qContent, propertyKey, trim(attributes.stContent[propertyKey]), 1);
			}
		}
	
	} else {
	
		// Pad out columns for qContent
		qContent = attributes.qContent;
		
		while (lColumns neq "") {
		
			nextColumn = listFirst(lColumns); lColums = listRest(lColumns);
			if (not isDefined("qContent." & nextColumn))			
				queryAddColumn(qContent, nextColumn, arrayNew(1));
		
		}
	}

</cfscript>


<!--- For each content item --->

<cfloop query="qContent">

	<!--- Check to see if content item already exists --->
	<cfif not request.speck.isUUID(spId)>
	
		<cfset bNewContent = true>	
		<cfset void = querySetCell(qContent, "spId", createUUID(), qContent.CurrentRow)>
		<cfset void = querySetCell(qContent, "spRevision", 0, qContent.CurrentRow)>
		<cf_spDebug msg="spId '#spId#' is not a valid id, generated new UUID '#qContent.spId[qContent.currentRow]#' for new content item, set bNewContent true and spRevision to 0.">
	
	<cfelse>
	
		<!--- It's a uuid, but does the content item already exist? --->
		<cfquery name="qExistingContent" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			SELECT spId FROM #attributes.type# WHERE spId = '#spId#'
		</cfquery>
		
		<cfif qExistingContent.recordCount neq 0>
		
			<cf_spDebug msg="spId '#spId#' exists in database, setting bNewContent false.">
			<cfset bNewContent = false>
		
		<cfelse>
		
			<cf_spDebug msg="spId '#spId#' is not in database, setting bNewContent true and spRevision 0.">
			<cfset bNewContent = true>
			<!--- <cfset spRevision = 0> oops, this was meant to set the spRevsion value in the current row of the query to 0, now done below --->
			<cfset void = querySetCell(qContent, "spRevision", 0, qContent.CurrentRow)>
		
		</cfif>
	
	</cfif>
	
	<!--- Default spRevision to current view level if blank --->

	<cfif spRevision eq "">
	
		<cf_spRevisionGet
			id=#spId#
			type=#attributes.type#
			level=#request.speck.session.viewLevel#
			r_revision="revision">
		
		<cf_spDebug msg="revisionGet says revision at level '#request.speck.session.viewLevel#' is #revision#">
		<cfset void = querySetCell(qContent, "spRevision", revision, qContent.CurrentRow)>
	
	</cfif>
	
	
	<!--- always get tip revision - new revisions should be tip + 1, not spRevision + 1 --->
	<cf_spDebug msg="Checking tip revision">
	
	<cf_spRevisionGet
		id=#spId#
		type=#attributes.type#
		level="tip"
		r_revision="tipRevision">
	
	<cf_spDebug msg="spRevision = #spRevision# tipRevision = #tipRevision#">

	<!--- 
	Check that content item can be updated
		-	If revision enabled current revision must be tip (no branching allowed).
		-	If promotion enabled current revision must be
			-	live, or
			-	edit, with the current user or spSystem as the author.
	--->
	
	<cfif not bNewContent>
	
		<cfif bRevision>
		
			<!--- now always checking for tip revision (i.e. outside this conditional) because new content 
				needs to be added with a revision of tipRevision + 1 rather than spRevision + 1 to allow 
				for rollbacks and deletions
			<cf_spDebug msg="Checking tip revision">
			
			<cf_spRevisionGet
				id=#spId#
				type=#attributes.type#
				level="tip"
				r_revision="tipRevision">
			
			<cf_spDebug msg="spRevision = #spRevision# tipRevision = #tipRevision#">	 --->	
			
			<cfif spRevision neq tipRevision>
			
				<cf_spDebug msg="revisioning on, spRevision neq tipRevision, set bNewContent = true">
			
				<cfset bNewContent = true>
			
				<!--- <cf_spError error="CP_NOT_TIP" lParams="#stType.name#,#spLabel#,#spId#,#tipRevision#,#spRevision#"> --->
			
			</cfif>
		
		</cfif>
		
		<cfif bPromotion>

			<cf_spDebug msg="Checking live revision">
			
			<cf_spRevisionGet
				id=#spId#
				type=#attributes.type#
				level="live"
				r_revision="liveRevision">
				
			<cf_spDebug msg="Checking edit revision">
			
			<cf_spRevisionGet
				id=#spId#
				type=#attributes.type#
				level="edit"
				r_revision="editRevision"
				r_editor="editRevisionAuthor">
				
			<cfscript>
			
				bLevelOk = false;
				if (spRevision eq liveRevision)
					bLevelOk = true;
				else if ((spRevision eq editRevision) and ((attributes.user eq editRevisionAuthor) or (attributes.user eq "spSystem")))
					bLevelOk = true;
			
			</cfscript>

			<cfif not bLevelOk>
				
				<!--- if level is not ok, check if content has been promoted to review, if not, user must be the editor --->
				<cfquery name="qCheckLevel" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
					SELECT *
					FROM spHistory
					WHERE id = '#spId#'
						AND ts = (
							SELECT MAX(ts)
							FROM spHistory
							WHERE id = '#spId#'
								AND promoLevel <> 3
						)
					ORDER BY promoLevel DESC
				</cfquery>
				
				<!--- <cfif qCheckLevel.promoLevel eq 1 and ( attributes.user eq trim(qCheckLevel.editor) or attributes.user eq "spSystem" )>
				
					<cfset bLevelOk = true> --->
			
				<cfif qCheckLevel.promoLevel eq 2>
				
					<cfset bNewContent = true>
					
				<cfelse>
				
					<cf_spError error="CP_INV_LEVEL" lParams="#stType.name#,#spLabel#,#spId#,#spRevision#,#editRevision#,[#editRevisionAuthor#],#liveRevision#">
					
				</cfif>
			
			</cfif>
			
		</cfif>
		
	</cfif>
	
	<!---
	Determine next revision number, if the content item already exists and:
		-	Revision disabled, or
		-	Promotion enabled and current revision never promoted to review or live
	the revision number stays the same, otherwise the revision number is increased by 1.
	--->
	
	<!--- list of the ids of content items that incremented their revisions. --->
 	<cfset lNewRevisions = "">
	
	<cfif bRevision>
	
		<cfquery name="qPromotions" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			SELECT id 
			FROM spHistory 
			WHERE id = '#spId#'
				AND revision = #spRevision#
				AND promoLevel > 1
		</cfquery>

		<cfscript>
		
			bRevisionNeverReviewOrLive = (qPromotions.recordCount eq 0);
				 
			if (bNewContent or not (bPromotion and bRevisionNeverReviewOrLive)) {
				querySetCell(qContent, "spRevision", (tipRevision + 1), qContent.CurrentRow);
				lNewRevisions = listAppend(lNewRevisions, spId);
			}
		
		</cfscript>
	
	<cfelse>
	
		<cfif bNewContent>
		
			<!--- Even with revisioning turned off, it's still a new revision if it's a new content item --->
			<cfset void = querySetCell(qContent, "spRevision", (tipRevision + 1), qContent.CurrentRow)>
			<cfset lNewRevisions = listAppend(lNewRevisions, spId)>
			
		<cfelseif bPromotion and spRevision eq 0>
		
			<!--- revisioning off but promotion on, which means this type is not revisioned and spRevisionGet returned 
				a current revision of 0, so this type was never revisioned, so set revision to update to 1 --->
			<cfset void = querySetCell(qContent, "spRevision", 1, qContent.CurrentRow)>
		
		</cfif>
	
	</cfif>
	
	<cf_spDebug msg="Following content items will be saved as new revisions: #listQualify(lNewRevisions, "'")#">
	
	<!--- Set spCreated, spUpdated, spUpdatedBy --->
	
	<cfset putTime = createODBCDateTime(now())>
	
	<!--- set spCreated value for new revisions (even with revisioning off, when new content is added, it's a new revision) --->
	<cfif listFind(lNewRevisions, spId) and spRevision eq 1>
		
		<cf_spDebug msg="this is the first revision, set spCreated to now(), spCreatedBy to value of user attribute and get the next available sequence id">
		<!--- this is the first revision, set spCreated to now() and spCreatedBy to value of user attribute --->
		<cfset void = querySetCell(qContent, "spCreated", putTime, qContent.CurrentRow)>
		<cfset void = querySetCell(qContent, "spCreatedBy", attributes.user, qContent.CurrentRow)>
			
		<cftransaction>
		
			<cfquery name="qSequence" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
				SELECT sequenceId FROM spSequences WHERE contentType = '#uCase(attributes.type)#'
			</cfquery>
			
			<cfif not qSequence.recordCount>
			
				<cfthrow 
					message="No sequence found for type '#attributes.type#'" 
					detail="Cannot obtain the next available sequence id for type '#attributes.type#'. The following SQL query returned no rows:<br>SELECT sequenceId FROM spSequences WHERE contentType = '#uCase(attributes.type)#'">
			
			</cfif>
			
			<cfset sequenceId = qSequence.sequenceId + 1>
			
			<cfif qSequence.recordCount gt 1>
			
				<!--- an old bug in spType meant that it was possible to have more than one row if the table was dropped by a database administrator and then re-created by spType --->
				
				<cfquery name="qDeleteSequences" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
					DELETE FROM spSequences WHERE contentType = '#uCase(attributes.type)#'
				</cfquery> 
				
				<cfquery name="qInsertSequence" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
					INSERT INTO spSequences (contentType, sequenceId) VALUES ('#uCase(attributes.type)#',#sequenceId#)
				</cfquery>
								
			<cfelse>
				
				<cfquery name="qUpdateSequence" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
					UPDATE spSequences SET sequenceId = #sequenceId# WHERE contentType = '#uCase(attributes.type)#'
				</cfquery> 
				
			</cfif>
			
		</cftransaction>
		
		<cfset void = querySetCell(qContent, "spSequenceId", sequenceId, qContent.CurrentRow)>

	<cfelse>
		
		<cf_spDebug msg="new revision of an existing content item, get original created timestamp">
		<!--- new revision of an existing content item, get original created timestamp --->
		
		<cfquery name="qCreated" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password# maxRows="1">
			SELECT spCreated, spCreatedBy, spSequenceId 
			FROM #attributes.type#
			WHERE spId = '#spId#'
		</cfquery>
		
		<cfset void = querySetCell(qContent, "spCreated", createODBCDateTime(qCreated.spCreated), qContent.CurrentRow)>
		<cfset void = querySetCell(qContent, "spCreatedBy", qCreated.spCreatedBy, qContent.CurrentRow)>
		<cfset void = querySetCell(qContent, "spSequenceId", qCreated.spSequenceId, qContent.CurrentRow)>
	
	</cfif>
	
	<cfset void = querySetCell(qContent, "spUpdated", putTime, qContent.CurrentRow)>
	<cfset void = querySetCell(qContent, "spUpdatedBy", attributes.user, qContent.CurrentRow)>
	
</cfloop>

<!--- Run the type's contentPut handler --->
<cfif structKeyExists(stType.methods, "contentPut")>

	<cfmodule template=#stType.methods.contentPut#
		qContent=#qContent#
		type=#stType.name#
		method="contentPut"
		updateContent="yes">

</cfif>

<!--- For each property, run the property handler's contentPut action and build list of properties to save to database --->
<cfset lSaveToDatabase = "">
<cfset lDatabaseMaxLengths = "">
<cfset lDatabaseCharColumns = "">
<cfset lDatabaseDateTimeColumns = "">

<cfloop from=1 to=#arrayLen(stType.props)# index="prop">

	<cfset stPD = stType.props[prop]>
	
	<cfif stPD.saveToDatabase>
	
		<cfset lSaveToDatabase = listAppend(lSaveToDatabase, stPD.name)>
		
		<cfset lDatabaseMaxLengths = listAppend(lDatabaseMaxLengths, stPD.maxLength)>
	
	</cfif>
	
	<cfif listFindNoCase("TEXT", stPD.databaseColumnType)>
	
		<cfset lDatabaseCharColumns = listAppend(lDatabaseCharColumns, stPD.name)>
		
	<cfelseif listFindNoCase("DATETIME", stPD.databaseColumnType)>
	
		<cfset lDatabaseDateTimeColumns = listAppend(lDatabaseDateTimeColumns, stPD.name)>
	
	</cfif>
	
	<cfif structKeyExists(stPD.methods, "contentPut")>
	
		<!--- property has a contentPut method, run the handler with this method --->

		<cfloop from=1 to=#qContent.RecordCount# index="item">
			
			<!--- note: newRevision attribute added, same functionality could be achieved by referencing lRevisions 
				in caller scope from the contentPut property handler method which would probably also be more efficient --->
			<cfmodule template=#stPD.methods.contentPut#
				method="contentPut"
				stPD=#stPD#
				type=#stType.name#
				id=#qContent.spId[item]#
				revision=#qContent.spRevision[item]#
				newValue=#qContent[stPD.name][item]#
				newRevision=#yesNoFormat(listFind(lNewRevisions, qContent.spId[item]))#
				r_newValue="newValue">
				
			<cfset void = QuerySetCell(qContent, stPD.name, newValue, item)>
			
		</cfloop>
	
	</cfif>
	
</cfloop>
	
<!--- sql string --->
<cfset sql = "">

<cfloop from=1 to="#qContent.RecordCount#" index="item">

	<!---If revision number the same update the current database record, otherwise insert a new record --->
	
	<cfscript>
	
		// cfquery isn't auto-escaping single quotes when given an expression like '#qContent.spLabel[item]#' 
		// and preserveSingleQuotes() function only accepts a simple string value as an argument, so...
		
		thisLabel = replace(qContent.spLabel[item],"'","''","all");
		thisKeywords = replace(qContent.spKeywords[item],"'","''","all");
	
	</cfscript>
	
	<cfif listFind(lNewRevisions, qContent.spId[item]) eq 0>
	
		<!--- Existing record --->
		<cfquery name="qUpdate" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		
			UPDATE #stType.name# SET 
			
			<cfset counter = 0>
			<cfloop list=#lSaveToDatabase# index="propertyName">
			
				<cfset counter = counter + 1>
				<!--- get max length for property --->
				<cfset propertyMaxLength = listGetAt(lDatabaseMaxLengths,counter)> 
			
				<cfset propertyValue = qContent[propertyName][item]>
				
				<cfif listFindNoCase(lDatabaseCharColumns, propertyName)>
				
					#propertyName# = 
					<!--- use bind parameters to avoid any problems with large strings --->
					<cfif len(request.speck.database.varcharMaxLength) and propertyMaxLength gt request.speck.database.varcharMaxLength>
						<cfqueryparam null=#evaluate('trim(propertyValue) eq ""')# value="#propertyValue#" cfsqltype="#request.speck.database.longVarcharCFSQLType#" maxlength="#propertyMaxLength#">
					<cfelse>
						<cfqueryparam null=#evaluate('trim(propertyValue) eq ""')# value="#propertyValue#" cfsqltype="CF_SQL_VARCHAR" maxlength="#propertyMaxLength#">
					</cfif>
					,
					
				<cfelseif listFindNoCase(lDatabaseDateTimeColumns, propertyName)>
				
					#propertyName# = <cfif len(trim(propertyValue))>#createODBCDateTime(parseDateTime(propertyValue))#<cfelse>NULL</cfif>,
				
				<cfelse>
				
					#propertyName# = <cfif len(trim(propertyValue))>#propertyValue#<cfelse>NULL</cfif>,
				
				</cfif>
			
			</cfloop>
			
			<!--- spLabel = '#qContent.spLabel[item]#', --->
			<cfif len(trim(thisLabel))>
				spLabel = '#preserveSingleQuotes(thisLabel)#',
				spLabelIndex = '#uCase(preserveSingleQuotes(thisLabel))#',
			<cfelse>
				spLabel = NULL,
				spLabelIndex = NULL,
			</cfif>
			spUpdated = #qContent.spUpdated[item]#,
			spUpdatedBy = '#qContent.spUpdatedBy[item]#',
			<!--- spKeywords = '#listSort(qContent.spKeywords[item], "textnocase")#' --->
			spKeywords = <cfif len(trim(thisKeywords))>'#listSort(preserveSingleQuotes(thisKeywords), "textnocase")#'<cfelse>NULL</cfif>
			WHERE spId = '#qContent.spId[item]#' AND spRevision = #qContent.spRevision[item]#

		</cfquery>
		
	<cfelse>
	
		<!--- New record --->
		<cfquery name="qInsert" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		
			INSERT INTO #stType.name# (<cfif lSaveToDatabase neq "">#lSaveToDatabase#,</cfif>spLabel,spLabelIndex,spSequenceId,spCreated,spCreatedBy,spUpdated,spUpdatedBy,spKeywords,spId,spRevision,spLevel) 
			VALUES (
			
			<cfset counter = 0>
			<cfloop list=#lSaveToDatabase# index="propertyName">
			
				<cfset counter = counter + 1>
				<!--- get max length for property --->
				<cfset propertyMaxLength = listGetAt(lDatabaseMaxLengths,counter)>
			
				<cfset propertyValue = qContent[propertyName][item]>
				
				<cfif listFindNoCase(lDatabaseCharColumns, propertyName) neq 0>
						
						<!--- use bind parameters to avoid problems with large strings --->
						<cfif len(request.speck.database.varcharMaxLength) and propertyMaxLength gt request.speck.database.varcharMaxLength>
							<cfqueryparam null=#evaluate('trim(propertyValue) eq ""')# value="#propertyValue#" cfsqltype="#request.speck.database.longVarcharCFSQLType#" maxlength="#propertyMaxLength#">
						<cfelse>
							<cfqueryparam null=#evaluate('trim(propertyValue) eq ""')# value="#propertyValue#" cfsqltype="CF_SQL_VARCHAR" maxlength="#propertyMaxLength#">
						</cfif>
					,
					
				<cfelseif listFindNoCase(lDatabaseDateTimeColumns, propertyName)>
				
					<cfif len(trim(propertyValue))>#createODBCDateTime(parseDateTime(propertyValue))#<cfelse>NULL</cfif>,
					
				<cfelse>
				
					<cfif len(trim(propertyValue))>#propertyValue#<cfelse>NULL</cfif>,
				
				</cfif>
			
			</cfloop>
			
			<!--- '#qContent.spLabel[item]#', --->
			<cfif len(trim(thisLabel))>'#preserveSingleQuotes(thisLabel)#','#uCase(preserveSingleQuotes(thisLabel))#'<cfelse>NULL,NULL</cfif>,
			#qContent.spSequenceId[item]#,
			#qContent.spCreated[item]#,
			'#qContent.spCreatedBy[item]#',
			#qContent.spUpdated[item]#,
			'#qContent.spUpdatedBy[item]#',
			<!--- '#listSort(qContent.spKeywords[item], "textnocase")#', --->
			<cfif len(trim(thisKeywords))>'#listSort(preserveSingleQuotes(thisKeywords), "textnocase")#'<cfelse>NULL</cfif>,
			'#qContent.spId[item]#',
			#qContent.spRevision[item]#,
			<cfif bPromotion>1<cfelse>3</cfif>
			)

		</cfquery>
		
		<cfif bRevision>
		
			<!---
			If new revision number and revision enabled and
			-	Promotion disabled, promote the new revision to live.
			-	Promotion enabled, promote the new revision to edit.
			(The cf_promote tag will create a change, record the changeid and editor in spHistory and
			call property handler promote action)
			--->
		
			<cfscript>
				
				if (bPromotion) 
					newLevel = "edit";
				else
					newLevel = "live";

			</cfscript>
			
			<cfparam name="changeId" default="">
			
			<cf_spPromote
				id = #qContent.spId[item]#
				type = #attributes.type#
				revision = #qContent.spRevision[item]#
				newLevel = #newLevel#
				editor = #attributes.user#
				changeId = #changeId#>
				
			<!--- DELETE OLD REVISIONS OF THIS ITEM?? --->
			<cfif isDefined("request.speck.historySize") and isNumeric(request.speck.historySize)>
			
				<cfset request.speck.historySize = int(request.speck.historySize)>
			
				<cfif qContent.spRevision[item] gt request.speck.historySize>
					
					<!---
					TODO: update spDelete tag so it can be used with revisioning enabled and used to 
					delete a specific revision of a content item. Then call it from here so delete
					handlers for the content type or any of the property types will run as expected.					
					--->
					
					<!--- delete revisions earlier that the cut off revision --->
					<cfset revisionCutOff = ( qContent.spRevision[item] - request.speck.historySize ) + 1>
					
					<!--- 
					Note RE deleting old assets...
					Assets are versioned separately to the properties stored in the database, so a new revision 
					of a content item with an all new row in the database might refer to an asset added as part 
					of an earlier revision. We only delete the files added with the revisions we're deleting, that
					are not being used in later revisions that we're not deleting. Damn, this is complicated.
					--->
					
					<cfscript>
						// get a list of asset properties
						lAssetProps = "";
						for(i=1; i le arrayLen(stType.props); i = i + 1) {
							if ( stType.props[i].type eq "Asset" ) {
								lAssetProps = listAppend(lAssetProps,stType.props[i].name);
							}
						}
					</cfscript>
					
					<cfset idHash = request.speck.assetHash(qContent.spId[item])>
					
					<cfset fs = request.speck.fs>
					
					<cfif listLen(lAssetProps)>
					
						<cfloop list="#lAssetProps#" index="propName">
						
							<cfquery name="qDeletionCandidates" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
								SELECT spId, spRevision 
								FROM #stType.name# 
								WHERE spId = '#qContent.spId[item]#' 
									AND spRevision < #revisionCutOff#
									AND spRevision NOT IN ( 
										SELECT #propName# <!--- database col for asset prop stores revision at which asset was added --->
										FROM #stType.name# 
										WHERE spId = '#qContent.spId[item]#'
											AND spRevision >= #revisionCutOff#
									)
								ORDER BY spRevision ASC
							</cfquery>
							
							<cfloop query="qDeletionCandidates">
							
								<cfset secureAssetDir = request.speck.appInstallRoot & fs & "secureassets" & fs & idHash & fs & spId & "_" & spRevision & "_" & propName & fs>
								<cfif directoryExists(secureAssetDir)>
								
									<cftry>
									
										<!--- delete contents of directory and then directory itself --->
										<cfdirectory action="list" directory="#secureAssetDir#" sort="type desc" name="qFilesToDelete">
				
										<cfloop query="qFilesToDelete">
										
											<cfif type eq "file">
											
												<cffile action="delete" file="#secureAssetDir##name#">
											
											</cfif>
										
										</cfloop>
										
										<cfdirectory action="delete" directory="#secureAssetDir#">
									
									<cfcatch>
										
										<!--- TODO: log error, a permissions issue here should not stop the contentPut process from completing successfully --->
										<cfrethrow>
										
									</cfcatch>
									</cftry>
								
								</cfif>
							
							</cfloop>
						
						</cfloop>
					
					</cfif>
					
					<cfquery name="qDeleteOldRevisions" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
						DELETE FROM #stType.name# 
						WHERE spId = '#qContent.spId[item]#' 
							AND spRevision < #revisionCutOff#
					</cfquery>
					
					<cfquery name="qCleanOldRevisionsFromHistory" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
						DELETE FROM spHistory
						WHERE id = '#qContent.spId[item]#'
							AND revision < #revisionCutOff#
					</cfquery>
				
				</cfif>
			
			</cfif>	
			
		</cfif>
					
	</cfif>
	
	
	<cfif not bRevision>
	
		<!--- update the spKeywordsIndex table... --->
		<cfquery name="qDeleteKeywords" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			DELETE FROM spKeywordsIndex
			WHERE id = '#qContent.spId[item]#'
		</cfquery>
		<cfif len(thisKeywords)>
			<cfloop list="#thisKeywords#" index="keyword">
				<cfquery name="qInsertKeyword" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
					INSERT INTO spKeywordsIndex (contentType, keyword, id)
					VALUES ('#uCase(stType.name)#', '#uCase(trim(keyword))#', '#qContent.spId[item]#' )
				</cfquery>
			</cfloop>
		</cfif>
		
		<cfif structKeyExists(stType,"contentIndex")>
		
			<!--- update content index --->
			<cfscript>
				stContentIndex = structNew();
				if ( len(evaluate("#stType.contentIndex.date#")) ) {
					stContentIndex.date = evaluate("qContent.#stType.contentIndex.date#[item]");
				}
				if ( not structKeyExists(stContentIndex,"date") or not len(stContentIndex.date) ) {
					stContentIndex.date = spCreated;
				}
				stContentIndex.title = "";
				for (i=1; i le listLen(stType.contentIndex.title); i=i+1) {
					stContentIndex.title = stContentIndex.title & evaluate("qContent.#listGetAt(stType.contentIndex.title,i)#[item]") & " ";
				}
				stContentIndex.description = "";
				for (i=1; i le listLen(stType.contentIndex.description); i=i+1) {
					stContentIndex.description = stContentIndex.description & evaluate("qContent.#listGetAt(stType.contentIndex.description,i)#[item]") & " ";
				}
				stContentIndex.body = "";
				for (i=1; i le listLen(stType.contentIndex.body); i=i+1) {
					stContentIndex.body = stContentIndex.body & evaluate("qContent.#listGetAt(stType.contentIndex.body,i)#[item]") & " ";
				}						
			</cfscript>
			
			<cftry>
			
				<cf_spContentIndex 
					type="#attributes.type#"
					id="#qContent.spId[item]#"
					keyword="#qContent.spKeywords[item]#"
					attributeCollection="#stContentIndex#">
					
			<cfcatch type="SpeckError">
				<!--- do nothing, an expected error condition only means that this content item isn't suitable for indexing --->
				<!--- TODO: log message --->
			</cfcatch>
			</cftry>
			
		</cfif>
	
		<!--- flush caches --->
		<cfmodule template="/speck/api/content/spFlushCache.cfm"
			type=#attributes.type#
			id=#qContent.spId[item]#
			label=#qContent.spLabel[item]#
			keywords=#qContent.spKeywords[item]#>

	</cfif>
	
</cfloop>