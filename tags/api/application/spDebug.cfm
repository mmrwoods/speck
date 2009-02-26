<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfif not isDefined("attributes.context")>

	<cfif isDefined("request.speck")>
	
		<cfset attributes.context = request.speck>
	
	<cfelse>
	
		<cfexit method="EXITTAG">
	
	</cfif>

</cfif>

<cfparam name="attributes.context.debug" default="no">

<cfif attributes.context.debug>

	<!--- Begin error message with tag name --->
	
	<cfscript>

		lBaseTags = listRest(listRest(getBaseTagList()));
		
		//while (listFind(lBaseTags, "CF_SPERROR" neq 0))
		//	lBaseTags = listRest(lBaseTags);
	
		//if (lBaseTags neq "")
		//	tagName = listGetAt(lBaseTags, listContains(lBaseTags, "_")) & ": ";
		//else
		//	tagName = "";
		
		while ( listFirst(lBaseTags) eq "CF_SPERROR" )
			lBaseTags = listRest(lBaseTags);

		tagName = listFirst(lBaseTags);
	
	</cfscript>
	
	<cfif isDefined("attributes.msg")>
	
		<cfoutput><br><br><i>#tagName#<br>#attributes.msg#</i></cfoutput>
		<cfset tagName="">
		
	</cfif>
	
	<cfif isDefined("attributes.dmp")>
		
		<cfoutput><br><br>#tagName#</cfoutput>
		<cfdump var=#attributes.dmp#>
		
	</cfif>
	
	<cfoutput><br></cfoutput>

</cfif>