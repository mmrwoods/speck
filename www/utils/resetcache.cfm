<cfif isdefined("url.reset")>
	<cfset application.cache=structNew()>
</cfif>

<cfoutput><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html>
<head>
	<title>ResetCache</title>
</head>

<body>
cache keys: #structKeyList(application.cache)#
</body>
</html>
</cfoutput>