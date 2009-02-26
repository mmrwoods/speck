<cfsetting enablecfoutputonly="No">

<!--- FCKeditor hack - the default resource browser connector supplied with FCKeditor 2.0 is wide open to abuse --->

<cfif listLast(cgi.script_name,"/") eq "connector.cfm">

	<cfabort showerror="Access denied">

</cfif>