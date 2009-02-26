<!--- delete history and start again with only live content --->

<cfquery name="qDeleteHistory" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
	DELETE FROM spHistory
</cfquery>

<cfloop list="#structKeyList(request.speck.types)#" index="thisType">

	<cftry>
	
		<cfquery name="qMakeHistory" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		
			INSERT INTO spHistory (id, revision, promoLevel, editor, ts, contentType)
				SELECT spId, spRevision, 3, spUpdatedby, spUpdated, '#thisType#' AS contentType
				FROM #thisType#
		
		</cfquery>
		
	<cfcatch>
		<cfoutput>#cfcatch.message#<hr>#cfcatch.detail#</cfoutput>
	</cfcatch>
	</cftry>

</cfloop>
