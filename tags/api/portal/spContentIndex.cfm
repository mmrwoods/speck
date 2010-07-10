<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- 
Add content to the content index, which can be used to build a search facility.

This tag no longer needs to be called manually within contentPut, promote and delete 
methods for content types. Use the spIndex tag to define the content index as part 
of a type definition. If you need to do some funky things, for example, conditionally 
index only content items with a certain label, you can call this tag from the 
contentPut and promote methods. There is no need to manually delete items from the 
content index table within promote and delete methods - spPromote and spDelete will
always take care of this automatically.
--->

<!--- Validate attributes --->
<cfloop list="id,type,keyword,title,description,body,date" index="attribute">

	<cfif not structKeyExists(attributes,attribute)>
	
		<cf_spError error="ATTR_REQ" lParams="#attribute#">	<!--- Missing attribute --->
		
	</cfif>

</cfloop>

<cfif not structKeyExists(request.speck.types,attributes.type)>

	<cf_spError error="ATTR_INV" lParams="#attributes.type#,type"> <!--- Invalid attribute --->

</cfif>

<cfif not request.speck.isUUID(attributes.id)>

	<cf_spError error="ATTR_INV" lParams="#attributes.id#,id"> <!--- Invalid attribute --->

</cfif>

<cfif not structKeyExists(request.speck.types,attributes.type)>

	<cf_spError error="ATTR_INV" lParams="#attributes.type#,type"> <!--- Invalid attribute --->

</cfif>

<cfif listLen(attributes.keyword) gt 1>

	<!--- set attributes.keyword to the first suitable keyword listed in attributes.keywords (we only store one keyword per content item in the index) --->
	
	<!--- start off by just using the first keyword and override this if required --->
	<cfset lKeywords = attributes.keyword>
	<cfset attributes.keyword = listFirst(lKeywords)>
	
	<cfif isDefined("request.speck.portal")>
	
		<cfset stType = request.speck.types[attributes.type]>
		<cfif structKeyExists(stType,"keywordTemplates") and len(stType.keywordTemplates)>
				
			<cfquery name="qValidKeywords" dbtype="query">
				SELECT keyword 
				FROM request.speck.qKeywords 
				WHERE template IN (#listQualify(stType.keywordTemplates,"'")#)
			</cfquery>
			
			<cfset lValidKeywords = valueList(qValidKeywords.keyword)>
			
			<cfif len(lValidKeywords) and not listFind(lValidKeywords,attributes.keyword)>
			
				<!--- first keyword in keywords list doesn't seem to be suitable, so loop over the list until we find one that is --->
				<cfloop list="#listRest(lKeywords)#" index="keyword">
					
					<cfif listFind(lValidKeywords,keyword)>
					
						<cfset attributes.keyword = keyword>
						<cfbreak>
					
					</cfif>
					
				</cfloop>
				
			</cfif>
			
		</cfif>
		
	</cfif> 

</cfif>

<!--- 
CF's date parsing functions seem horribly inconsistent...
isDate(timestamp string) = true
lsIsDate(timestamp string) = true
parseDateTime(timestamp string) works fine
lsParseDateTime(timestamp string) throws an exception! 
--->
<!--- TODO: make me a function, stick me into spFunctions and use me wherever date strings are parsed --->
<cfif left(attributes.date,1) eq "{">

	<!--- CF/ODBC/JDBC timestamp or date string --->
	<cfset ts = parseDateTime(attributes.date)>
	
<cfelseif reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}",attributes.date)>

	<!--- iso date or date time string, parse without time zone... --->
	<cfif len(attributes.date) gt 19>
		<cfset attributes.date = left(attributes.date,19)>
	</cfif>
	
	<cfset ts = parseDateTime(replaceList(attributes.date,"T,t"," , "))>>
	
<cfelseif lsIsDate(attributes.date)>

	<cfset ts = lsParseDateTime(attributes.date)>

<cfelseif isDate(attributes.date)>

	<cfset ts = parseDateTime(attributes.date)>

<cfelse>

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

<!--- check if we need to insert or update (CF prior to version 8 does not have a simple way of obtaining the number of rows affected by an update)  --->
<cfquery name="qCheckExists"datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
	SELECT <!--- id ---> * FROM spContentIndex WHERE id = '#uCase(attributes.id)#'
</cfquery>

<cfif listFindNoCase(qCheckExists.columnList,"label")>

	<!--- get label for content item --->
	<cfquery name="qLabel"datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		SELECT spLabel FROM #attributes.type# WHERE spId = '#uCase(attributes.id)#' AND spArchived IS NULL AND spLevel = 3
	</cfquery>
	
	<cfset bIndexHasLabel = true>
	
<cfelse>

	<cfset bIndexHasLabel = false>
	
</cfif>

<cfif qCheckExists.recordCount>

	<!--- update content index --->
	<cfquery name="qUpdate" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		UPDATE spContentIndex
		SET contentType = '#lCase(attributes.type)#',
			keyword = <cfif len(attributes.keyword)>'#left(lCase(attributes.keyword),250)#'<cfelse>NULL</cfif>,
			<cfif bIndexHasLabel>
				label = <cfif len(qLabel.spLabel)>'#qLabel.spLabel#'<cfelse>NULL</cfif>,
			</cfif>
			title = '#left(attributes.title,250)#',
			description = '#left(attributes.description,500)#',
			body = <cfqueryparam value="#left(attributes.body,64000)#" cfsqltype="CF_SQL_LONGVARCHAR" maxlength="64000">,
			ts = #createODBCDateTime(ts)#
		WHERE id = '#uCase(attributes.id)#'
	</cfquery>	

<cfelse>

	<!--- insert into content index --->
	<cfquery name="qInsert" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		INSERT INTO spContentIndex (
			contentType,
			id,
			keyword,
			<cfif bIndexHasLabel>label,</cfif>
			title,
			description,
			body,
			ts
		) VALUES (
			'#lCase(attributes.type)#',
			'#uCase(attributes.id)#',
			<cfif len(attributes.keyword)>'#left(lCase(attributes.keyword),250)#'<cfelse>NULL</cfif>,
			<cfif bIndexHasLabel>
				<cfif len(qLabel.spLabel)>'#qLabel.spLabel#'<cfelse>NULL</cfif>,
			</cfif>
			'#left(attributes.title,250)#',
			'#left(attributes.description,500)#',
			<cfqueryparam value="#left(attributes.body,64000)#" cfsqltype="CF_SQL_LONGVARCHAR" maxlength="64000">,
			#createODBCDateTime(ts)#
		)
	</cfquery>

</cfif>

<!--- always do a clean up of the content index in case some deleted content has been left in the index unintentionally --->
<cfquery name="qDelete" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
	DELETE FROM spContentIndex 
	WHERE contentType = '#lCase(attributes.type)#' 
		AND id NOT IN (
			SELECT DISTINCT(spId) 
			FROM #attributes.type#
			WHERE spLevel = 3 AND spArchived IS NULL
		)
</cfquery>

