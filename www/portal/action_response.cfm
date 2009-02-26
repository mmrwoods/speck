<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfinclude template="header.cfm">

<cfparam name="url.message" default="Action successful">
<cfparam name="url.detail" default="">
<cfparam name="url.location" default="">
<cfparam name="url.refresh" default="yes" type="boolean">

<cfif not len(url.location)>

	<cfthrow message="system response error : no location provided">
	
</cfif>

<cfoutput>
<div id="system_response">

	<h1>#message#</h1>
	
	<cfif len(detail)>
	
		<h2>#detail#</h2>
	
	</cfif>
	</cfoutput>
	
	<cfif url.refresh>
		
		<cfheader name="Refresh" value="2;url=#url.location#">
		<cfoutput>
		<p>Please wait...</p>
		<p>If the next page does not load automatically, <a href="#url.location#">click here</a></p>
		</cfoutput>
		
	<cfelse>
	
		<cfoutput>
		<p><a href="#url.location#">CONTINUE</a></p>
		</cfoutput>
	
	</cfif>
	
	<cfoutput>
</div>
</cfoutput>

<cfinclude template="footer.cfm">