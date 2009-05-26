<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- Validate attributes --->
<cfloop list="id,type" index="attribute">

	<cfif not isdefined("attributes.#attribute#")>
	
		<cf_spError error="ATTR_REQ" lParams="#attribute#">	<!--- Missing attribute --->
		
	</cfif>

</cfloop>


<!--- cannot delete content when revisioning is enabled --->
<cfif request.speck.enableRevisions and request.speck.types[attributes.type].revisioned>

	<cf_spError error="DEL_REVISIONS">

</cfif>


<!--- make sure content item exists before we try and delete it --->
<cfquery name="qDeletionCandidate" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
	SELECT * FROM #attributes.type#
	WHERE spId = '#attributes.id#'
		AND spRevision = (
			SELECT MAX(spRevision) 
			FROM #attributes.type#
			WHERE spId = '#attributes.id#'
		)
</cfquery>
		
<cfif qDeletionCandidate.recordCount eq 0>
		
	<cf_spError error="DEL_ITEM_NOT_EXIST" lParams="#attributes.type#,#attributes.id#">
			
<cfelse>

	<!--- get type info --->
	<cfmodule template=#request.speck.getTypeTemplate(attributes.type)# r_stType="stType">

	<!--- Run the type's delete handler --->
	<cfif structKeyExists(stType.methods, "delete")>
	
		<!--- call handler with promote method --->
		<cfmodule template=#stType.methods.delete#
			qContent=#qDeletionCandidate#
			type=#attributes.type#
			method="delete">
	
	</cfif>
	
	
	<!--- run delete property handler methods --->
	<cfloop from=1 to=#arrayLen(stType.props)# index="prop">
	
		<cfset stPD = stType.props[prop]>
		
		<cfif structKeyExists(stPD.methods, "delete")>
		
			<!--- property has a delete method, run the handler with this method --->
			<cfmodule template=#stPD.methods.delete#
				method="delete"
				stPD=#stPD#
				value=#qDeletionCandidate[stPD.name][1]#
				id=#attributes.id#
				type=#attributes.type#>
				
		</cfif>
		
	</cfloop>
		
	<!--- delete content from database --->
	<cfquery name="qDelete" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		DELETE FROM #attributes.type# WHERE spId = '#attributes.id#'
	</cfquery>
	
	<cfquery name="qDelete" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		DELETE FROM spKeywordsIndex WHERE id = '#attributes.id#'
	</cfquery>
	
	<cfquery name="qDelete" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		DELETE FROM spContentIndex WHERE id = '#attributes.id#'
	</cfquery>
	
	<!--- flush the cache --->
	<cfmodule template="/speck/api/content/spFlushCache.cfm"
		type=#attributes.type#
		id=#attributes.id#
		label=#qDeletionCandidate.spLabel#
		keywords=#qDeletionCandidate.spKeywords#>
	
</cfif>