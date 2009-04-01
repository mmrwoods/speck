<cfprocessingdirective pageencoding="utf-8">

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

<cfscript>
	function normalizeHtml(html) {
		// normalize accented characters in latin1 (TODO: move to spFunctions and extend to normalize other characters, including some not in latin1 - see http://www.project-open.org/doc/intranet-search-pg/intranet-search-pg-create.sql for a good example)
		html = reReplace(html,"&([A-Za-z]{1})(grave|acute|circ|tilde|uml|ring|cedil);","\1","all");
		html = replaceList(html,'#chr(192)#,#chr(193)#,#chr(194)#,#chr(195)#,#chr(196)#,#chr(197)#,#chr(199)#,#chr(200)#,#chr(201)#,#chr(202)#,#chr(203)#,#chr(204)#,#chr(205)#,#chr(206)#,#chr(207)#,#chr(209)#,#chr(210)#,#chr(211)#,#chr(212)#,#chr(213)#,#chr(214)#,#chr(217)#,#chr(218)#,#chr(219)#,#chr(220)#,#chr(221)#,#chr(224)#,#chr(225)#,#chr(226)#,#chr(227)#,#chr(228)#,#chr(229)#,#chr(231)#,#chr(232)#,#chr(233)#,#chr(234)#,#chr(235)#,#chr(236)#,#chr(237)#,#chr(238)#,#chr(239)#,#chr(241)#,#chr(242)#,#chr(243)#,#chr(244)#,#chr(245)#,#chr(246)#,#chr(249)#,#chr(250)#,#chr(251)#,#chr(252)#,#chr(253)#,#chr(255)#','A,A,A,A,A,A,C,E,E,E,E,I,I,I,I,N,O,O,O,O,O,U,U,U,U,Y,a,a,a,a,a,a,c,e,e,e,e,i,i,i,i,n,o,o,o,o,o,u,u,u,u,y,y');
		return html;
	}
</cfscript>

<!--- normalize accented characters in the body - the body is just an indexable blob that shoudn't be used when outputting results --->
<cfset attributes.body = normalizeHtml(attributes.body)>

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

<!--- always do a clean up of the content index in case some deleted content has been left in the index unintentionally (note: this only works when revisioning is off at the moment) --->
<cfquery name="qDelete" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
	DELETE FROM spContentIndex WHERE contentType = '#lCase(attributes.type)#' AND id NOT IN (SELECT DISTINCT(spId) FROM #lCase(attributes.type)#)
</cfquery>

