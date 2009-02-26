<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cftry>

	<cfparam name="url.type" type="string" default="">
	
	<cfif not isDefined("url.id")>
	
		<cfthrow message="No spId">
	
	</cfif>
	
	<cfif REFind("[^[:alpha:]]+", url.type) neq 0>
		
		<cfthrow message="Invalid type: '#url.type#'">
		
	</cfif>
	
	<cfoutput>
	<html>
	<head>
	<title>help</title>
	<link rel="stylesheet" href="#request.speck.adminStylesheet#" type="text/css">
	<script src="/speck/javascripts/prototype.js" type="text/javascript"></script>
	<script src="/speck/javascripts/scriptaculous.js" type="text/javascript"></script>
	</head>
	<body bgcolor="##C0C0C0" onload="document.title=window.name.replace('_',' ');">
	</cfoutput>
			
	<cf_spContent type="#url.type#" id="#url.id#" method="help" enableAdminLinks="no">

	<cfoutput>
	</body>
	</html>
	</cfoutput>
	
<cfcatch type="any">

	<cfdump var="#cfcatch#">
	
</cfcatch>

</cftry>
