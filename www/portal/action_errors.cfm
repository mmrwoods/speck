<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfif isDefined("actionErrors") and arrayLen(actionErrors)>

	<cfoutput>
	<p class="notsaved">
	Sorry, one or more errors was found in your form submission,
	please correct these errors and re-submit the form.
	</p>
	<ul class="notsaved">
	</cfoutput>
	
	<cfloop from="1" to="#arrayLen(actionErrors)#" index="i">
	
		<cfoutput><li>#actionErrors[i]#</li></cfoutput>
	
	</cfloop>
	
	<cfoutput>
	</ul>
	</span>
	</cfoutput>

</cfif>