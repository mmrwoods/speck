<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!---
Description:

	Retrive revision number of a content item from a given promotion level or 'tip'.  Optionally qualify this with an effective date.
	
Usage:

	<cf_spRevisionGet
		id="UUID"
		type="string"
		level="edit|review|live|tip"
		date="date"
		r_revision="variable"
		r_editor="variable">
	
Attributes:	

	id(UUID, required):						Content items with these ids.
	type(string, required):					Type name.
	level(edit|review|live|tip, optional):	Promotion level or 'tip' to retrieve revision number for. Defaults appropriately according to application's
											enableRevisions setting.
	date(date, optional):					Used with the level attribute to retrieve the revision of content that was at a specified promotion level.
											or was the tip revision on this date.
	r_revision(variable, required):			Name of variable to return revision number in.
	r_editor(variable, optional):			Name of variable to return editor of edit revision in.
--->
 
<!--- Validate attributes --->
<cfloop list="id,type,r_revision" index="attribute">

	<cfif not isdefined("attributes.#attribute#")>
	
		<cf_spError error="ATTR_REQ" lParams="#attribute#">	<!--- Missing attribute --->
		
	</cfif>

</cfloop>

<cfscript>

	// Default according to application's enablePromotion setting
	if (request.speck.enableRevisions) {
		if (not isDefined("attributes.level"))
			//attributes.level = session.speck.viewLevel;
			attributes.level = request.speck.session.viewLevel;
	}
	else
		attributes.level = "tip";

</cfscript>

<cfparam name="attributes.date" default="">

<cfif attributes.date neq "" and not isDate(attributes.date)>

	<cf_spError error="ATTR_INV" lParams="#attributes.date#,date"> <!--- Invalid attribute --->

</cfif>

<cfset level = listContains("edit,review,live", attributes.level)>	<!--- Convert to number stored in spHistory.level or 4 for tip --->

<cfif level eq 0 and attributes.level neq "tip">

	<cf_spError error="CG_LEVEL_INV" lParams="#attributes.level#"> <!--- Invalid attribute --->

</cfif>

<!--- first get type info --->
<cfmodule template=#request.speck.getTypeTemplate(attributes.type)# r_stType="stType">

<!--- Construct revision SQL where clause --->
<cfscript>

	// set table alias keyword (Access requires the use of AS)
	ta = request.speck.database.tableAliasKeyword;

	// if type not revisioned set level to "tip"
	if ( not stType.revisioned )
		attributes.level = "tip";

	switch (trim(attributes.level)) {
		case "tip": {
			sql = 	"SELECT Max(tip.spRevision) as revision
					FROM #attributes.type# #ta# tip 
					WHERE tip.spId = '#attributes.id#'
					#iif(attributes.date neq "", DE("AND tip.spCreated <= ##" & attributes.date & "##"), DE(""))#
					";
			break;
	 	} 
		default: {
			if (level gt 1) {
				// Select most recent revision promoted to specified level that hasn't been removed* since promotion.  At review and live levels there
				// will always be a row in spHistory recording the promotion to or removal from that level.
				// * "Removal" is indicated in spHistory by promoting revision 0 of a content item.
				sql =	
				"SELECT	latestUnremovedPromotion.revision as revision
				FROM	spHistory #ta# latestUnremovedPromotion
				WHERE	latestUnremovedPromotion.id = '#attributes.id#' AND
						latestUnremovedPromotion.ts =
						(
							SELECT	max(latestPromotion.ts)
							FROM	spHistory #ta# latestPromotion
							WHERE	latestUnremovedPromotion.id = latestPromotion.id AND
									latestPromotion.promoLevel = #level#
									#iif(attributes.date neq "", DE("AND latestPromotion.ts <= ##" & attributes.date & "##"), DE(""))#
						)";
			} else {
				// At edit level the editor only sees edit level content being edited by themseleves, and other content comes from review level.  
				// Because of this we only retrieve edit level content being edited by the user (ts should always be greater than review level ts),
				// and include review level.
				sql =	
				"SELECT	latestUnremovedPromotion.revision as revision
				FROM	spHistory #ta# latestUnremovedPromotion
				WHERE	latestUnremovedPromotion.id = '#attributes.id#' AND
						latestUnremovedPromotion.ts =
						(
							SELECT	max(latestPromotion.ts)
							FROM	spHistory #ta# latestPromotion
							WHERE	latestUnremovedPromotion.id = latestPromotion.id AND
									(
										(
											latestPromotion.promoLevel = 1 AND latestPromotion.editor = '" & request.speck.session.user & "'
										) OR
										latestPromotion.promoLevel = 2
									)
									#iif(attributes.date neq "", DE("AND latestPromotion.ts <= ##" & attributes.date & "##"), DE(""))#
						)";	
			}
		}
	}
	
</cfscript>

<cfquery name="qRevision" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
	#preserveSingleQuotes(sql)#
</cfquery>

<cfscript>

	if (qRevision.recordCount neq 0 and isNumeric(qRevision.revision[1]))
		revision = qRevision.revision[1];
	else
		revision = 0;	// The "null" revision

</cfscript>

<!--- Return revision --->
<cfset "caller.#attributes.r_revision#" = revision>

<!--- If caller wanted to know editor, look that up --->

<cfif isDefined("attributes.r_editor") and attributes.level eq "edit">

	<cfquery name="qEditor" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		SELECT editor FROM spHistory WHERE id = '#attributes.id#' AND revision = #revision# AND promoLevel = 1 ORDER BY ts DESC
	</cfquery>

	<cfscript>
	
		if (qEditor.recordCount neq 0)
			editor = qEditor.editor[1];
		else
			editor = "";
			
	</cfscript>

	<!--- Return editor --->
	<cfset "caller.#attributes.r_editor#" = trim(editor)>

</cfif>
