<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- 
Add content to the content index, which can be used to build a search facility.

At the moment, this tag is part of the portal framework and the content index
table is created by the cf_spPortal tag. In addition, developers have to manually
manage the index using contentPut, promote and delete event handlers for their 
content types. Once I'm happy with the general solution, I'll add content indexing 
to the core of Speck and have the indexes for each content type managed automatically 
once defined (probably with some additional cf_spType attributes).
--->

<!--- Validate attributes --->
<cfloop list="id,type,keyword,title,description,body,date" index="attribute">

	<cfif not isdefined("attributes.#attribute#")>
	
		<cf_spError error="ATTR_REQ" lParams="#attribute#">	<!--- Missing attribute --->
		
	</cfif>

</cfloop>

<cfif not request.speck.isUUID(attributes.id)>

	<cf_spError error="ATTR_INV" lParams="#attributes.id#,id"> <!--- Invalid attribute --->

</cfif>

<cfif not structKeyExists(request.speck.types,attributes.type)>

	<cf_spError error="ATTR_INV" lParams="#attributes.type#,type"> <!--- Invalid attribute --->

</cfif>

<cfif not isDate(attributes.date)>

	<cf_spError error="ATTR_INV" lParams="#attributes.date#,date"> <!--- Invalid attribute --->

</cfif>

<!--- remove html from attributes --->
<cfset attributes.title = reReplace(attributes.title,"<[^>]*>","","all")>
<cfset attributes.description = reReplace(attributes.description,"<[^>]*>","","all")>
<cfset attributes.body = reReplace(attributes.body,"<[^>]*>","","all")>

<cfloop list="title,description,body" index="attribute">

	<cfif not len(attributes[attribute])>
	
		<!--- we've nothing to add to the index, delete any existing item and exit --->

		<cfquery name="qDelete"datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			DELETE FROM spContentIndex WHERE id = '#uCase(attributes.id)#'
		</cfquery>
			
		<cfexit method="exittag">
		
	</cfif>

</cfloop>

<!--- can't check if any rows are affected by query in CF, so try insert, if fails, update --->
<cftry>

	<cfquery name="qInsert" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
	
		INSERT INTO spContentIndex (
			contentType,
			id,
			keyword,
			title,
			description,
			body,
			ts
		) VALUES (
			'#lCase(attributes.type)#',
			'#uCase(attributes.id)#',
			<cfif len(attributes.keyword)>'#left(lCase(attributes.keyword),250)#'<cfelse>NULL</cfif>,
			'#left(attributes.title,250)#',
			'#left(attributes.description,500)#',
			<cfqueryparam value="#left(attributes.body,64000)#" cfsqltype="CF_SQL_LONGVARCHAR" maxlength="64000">,
			#createODBCDateTime(attributes.date)#
		)
	
	</cfquery>

<cfcatch>

	<cfquery name="qUpdate" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
	
		UPDATE spContentIndex
		SET contentType = '#lCase(attributes.type)#',
			keyword = <cfif len(attributes.keyword)>'#left(lCase(attributes.keyword),250)#'<cfelse>NULL</cfif>,
			title = '#left(attributes.title,250)#',
			description = '#left(attributes.description,500)#',
			body = <cfqueryparam value="#left(attributes.body,64000)#" cfsqltype="CF_SQL_LONGVARCHAR" maxlength="64000">,
			ts = #createODBCDateTime(attributes.date)#
		WHERE id = '#uCase(attributes.id)#'
	
	</cfquery>

</cfcatch>
</cftry>