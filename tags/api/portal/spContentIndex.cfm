<cfprocessingdirective pageencoding="utf-8">
<!--- 
WARNING: THIS FILE MUST BE SAVED UT8 ENCODED 
If it's not UTF8 encoded, the code to normalize accented characters will fail.
The characters on the next line have code points above 255 - if any of them 
appear fscked up, then this template has been saved as something other than 
UTF8 and needs to be converted back to UTF8.
ɸʊΘѰф
--->

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

<!--- normalize some html escaped accented characters in the body (the body is just an indexable blob that shoudn't be used when outputting results) --->
<cfset attributes.body = reReplace(attributes.body,"&([A-Za-z]{1})(grave|acute|circ|tilde|uml|ring|cedil);","\1","all")>

<!--- normalize accented characters in latin1 (ideally we'd just rely on the indexing engine to deal with this, but using postgres and tsearch is a pain in the tits for this, so it's just easier to do it here) --->
<!--- TODO: replace all the accented characters in the list with calls to chr() function to avoid any issues with the encoding of this file being changed) --->
<cfset attributes.body = replaceList(attributes.body,'À,Á,Â,Ã,Ä,Å,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ñ,Ò,Ó,Ô,Õ,Ö,Ù,Ú,Û,Ü,Ý,à,á,â,ã,ä,å,ç,è,é,ê,ë,ì,í,î,ï,ñ,ò,ó,ô,õ,ö,ù,ú,û,ü,ý,ÿ','A,A,A,A,A,A,C,E,E,E,E,I,I,I,I,N,O,O,O,O,O,U,U,U,U,Y,a,a,a,a,a,a,c,e,e,e,e,i,i,i,i,n,o,o,o,o,o,u,u,u,u,y,y')>

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