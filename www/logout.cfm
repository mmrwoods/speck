<cfsetting enablecfoutputonly="yes">

<cfset void = structDelete(session,"speck")>

<cflocation url="#cgi.http_referer#" addtoken="no">
