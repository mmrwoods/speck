<cfsetting enablecfoutputonly="Yes" requesttimeout="300"> <!--- if using CF5 - remove the requesttimeout attribute and pass it in the url --->

<cfloop query="request.speck.qKeywords">

	<cfoutput>update #keyword#, new sort id = #currentRow#<br></cfoutput>
	
	<cfquery name="qUpdateKeyword" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		UPDATE spKeywords
		SET sortId = #currentRow#
		WHERE keyword = '#keyword#'
	</cfquery>

</cfloop>

<!--- update request.speck.qKeywords and application.speck.qKeywords --->
<cfquery name="request.speck.qKeywords" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
	SELECT * FROM spKeywords ORDER BY sortId, keyword
</cfquery>
<cflock scope="application" timeout="5" type="exclusive">
<cfset application.speck.qKeywords = duplicate(request.speck.qKeywords)>
</cflock>