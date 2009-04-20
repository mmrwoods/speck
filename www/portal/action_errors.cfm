<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfif isDefined("actionErrors") and arrayLen(actionErrors)>

	<cfoutput>
	<div id="errorExplanation" class="errorExplanation">
	<p>
	Sorry, the action could not be completed due to the following issues...
	</p>
	<ul>
	</cfoutput>
	
	<cfloop from="1" to="#arrayLen(actionErrors)#" index="i">
	
		<cfoutput><li>#actionErrors[i]#</li></cfoutput>
	
	</cfloop>
	
	<cfoutput>
	</ul>
	</div>
	</cfoutput>

</cfif>