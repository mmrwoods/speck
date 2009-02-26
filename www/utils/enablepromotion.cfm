<!--- remove all non-live entries from history and create a review level history --->

<cfquery name="qDeleteHistory" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
	DELETE FROM spHistory WHERE promoLevel <> 3
</cfquery>

<cfif request.speck.dbtype eq "mysql">

	<!--- mysql hack, cannot use INSERT INTO ... SELECT FROM where source table and destination table are same --->
	<cfquery name="qGetHistory" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		SELECT * FROM spHistory WHERE promoLevel = 3 ORDER BY contentType, id
	</cfquery>
	
	<cfloop query="qGetHistory">
	
		<cfquery name="qGetHistory" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			INSERT INTO spHistory (id, revision, promoLevel, editor, contentType, ts)
				VALUES ('#id#', #revision#, 2, '#editor#', '#contentType#', #createODBCDateTime(dateAdd("n",-1,ts))#)
		</cfquery>
		
	</cfloop>
	
	<cfexit>

</cfif>

<cfscript>
	switch ( request.speck.dbtype ) {
		case "access": {
			reviewDateSQL = "dateadd('n',-1,ts)";
			break;
		}
		case "sqlserver": {
			reviewDateSQL = "dateadd('n',-1,ts)";
			break;
		}
		case "mysql": {
			reviewDateSQL = "DATE_SUB(ts,INTERVAL 1 second)";
			break;
		}		
		default: // should work for oracle and postgres, not tested
			reviewDateSQL = "ts - INTERVAL '1' MINUTE";
	}
</cfscript>

<cftry>

<cfset sql = "
INSERT INTO spHistory (id, revision, promoLevel, editor, contentType, ts)
	SELECT id, revision, 2, editor, contentType, #reviewDateSQL#
	FROM spHistory
">

	<cfquery name="qMakeHistory" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		#preserveSingleQuotes(sql)#
	</cfquery>
	
<cfcatch type="Database">
	<cfoutput><h4>
	Database error occurred while running the query below<br>
	Try running the query using the DBMS command line tool or SQL Query tool.
	</h4>
	<pre>#trim(sql)#</pre>
	</cfoutput>
</cfcatch>
</cftry>