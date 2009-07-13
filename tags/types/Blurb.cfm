<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spType
	name="Blurb"
	caption="Text">

 	<cf_spProperty
		name="blurb"
		caption="Text"
		type="Html"
		required="yes"
		displaySize="75,20"
		fckHeight="400"
		maxlength="32000"
		richEdit="yes"
		safeText="#attributes.context.getConfigString("types","blurb","blurb_safe_text","yes")#">
		
		
	<cf_spHandler method="display">
	
		<cfparam name="attributes.forceParagraphs" default="false" type="boolean">
	
		<cfif attributes.forceParagraphs>
		
			<cfoutput>#request.speck.forceParagraphs(content.blurb)#</cfoutput>
		
		<cfelse>
		
			<cfoutput>#content.blurb#</cfoutput>
		
		</cfif>

	</cf_spHandler>
	
	
	<cf_spHandler method="refresh">
		
		<!--- 
		This special method is called while the application is being refreshed.
		It's a little like a class constructor in OO languages, but it's called 
		"refresh" to avoid stretching that analogy too far. There is no content
		structure available to this method (there is no content object/item), 
		and the request.speck structure is also unavailable as the application 
		is being refreshed. There is a context structure though, which provides 
		information about the environment within which the method is being 
		executed. It contains most of the data that ends up in request.speck.
		--->
		
		<!--- Update Blurbs to be compatible with new verison of cf_spPage --->
		<cfquery name="qUpdateBlurbs" datasource="#context.codb#">
			UPDATE Blurb
			SET spLabel = 'page_content',
				spLabelIndex = 'PAGE_CONTENT'
			WHERE spLabel IS NOT NULL
				AND spLabel <> 'page_content'
				AND spLabel IN (SELECT keyword FROM spKeywords)
				AND spLabel = spKeywords
		</cfquery>
		
	</cf_spHandler>
	
		
</cf_spType>


