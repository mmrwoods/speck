<cfsetting enablecfoutputonly="Yes" requesttimeout="300"> <!--- if using CF5 - remove the requesttimeout attribute and pass it in the url --->

<!--- nasty, nasty script, might have to break this up into smaller chunks --->

<cfquery name="qDeleteKeywordsIndex" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
	DELETE FROM spKeywordsIndex
</cfquery>

<cfloop list="#structKeyList(request.speck.types)#" index="thisType">

	<cfif structKeyExists(request.speck.types[thisType],"props")>

		<cf_spContentGet type="#thisType#" properties="spId,spKeywords" where="spKeywords IS NOT NULL" r_qcontent="qContent">
	
		<cfloop query="qContent">
			
			<cfloop list="#spKeywords#" index="keyword">
			
				<cfquery name="qInsertKeyword" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
					INSERT INTO spKeywordsIndex (contentType, keyword, id)
					VALUES ('#uCase(thisType)#', '#uCase(trim(keyword))#', '#spId#' )
				</cfquery>
				
			</cfloop>
		
		</cfloop>
		
	</cfif>

</cfloop>
