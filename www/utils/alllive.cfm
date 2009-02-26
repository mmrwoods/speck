<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Put all content Live</title>
</head>

<body>

<cfloop collection=#request.speck.types# item="type">

	<cfoutput><br>#type#</cfoutput>
	
	<cfif type neq "file">
		<cfquery name="qContent" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
			SELECT spId,spRevision FROM #type#
		</cfquery>
		
		<cfloop query="qContent">
		
			<cf_spPromote
				id = #spId#
				type = #type#
				revision = #spRevision#
				newLevel = "live"
				editor = "robin"
				changeId = "">
				
			<cfoutput><br>...#spId#</cfoutput>
			<cfflush>
		
		</cfloop>
	</cfif>
</cfloop>


</body>
</html>
