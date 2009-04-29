<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spType
	name="ArticleContainer"
	description="Article Container">
	
 	<cf_spProperty
		name="articles"
		caption="Articles"
		type="Picker"
		contentType="Article"
		required="no"
		maxSelect="25"
		dependent="#attributes.context.getConfigString("types","article_container","articles_dependent","no")#"
		showSort="yes"
		prepend="yes">
		
	<cf_spHandler method="display">
	
		<cfif len(content.articles)>
	
			<!--- we don't want to pass the caller attributes to spContentGet, so call it separately --->
			<cf_spContentGet type="Article" id="#content.articles#" orderByIds="yes" r_qContent="qContent">
	
			<!--- render the query results using spContent --->
			<cf_spContent 
				type="Article" 
				qContent="#qContent#" 
				method="summary"
				enableAdminLinks="no"
				attributeCollection="#caller.attributes#">
				
		</cfif>		
	
	</cf_spHandler>
	
</cf_spType>

