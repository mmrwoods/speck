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
		required="yes"
		maxSelect="25"
		dependent="#attributes.context.getConfigString("types","article_container","articles_dependent","no")#"
		showSort="yes">
		
	<cf_spHandler method="display">
	
		<cfparam name="attributes.titleElement" default="h3"> 
		<cfparam name="attributes.showThumbnail" default="no" type="boolean">
		<cfparam name="attributes.embedImage" default="no" type="boolean">
		<cfparam name="attributes.readMoreCaption" default="&raquo;&nbsp;read more">
		<cfparam name="attributes.separator" default="<span style='display:block;clear:both;height:0;font:0/0;'>&nbsp;</span>">
		<cfparam name="attributes.properties" default="title,summary,thumbnailImage,thumbnailImageDimensions">
		
		<cf_spContent 
				type="Article" 
				id="#content.articles#" 
				method="summary" 
				properties="#attributes.properties#"
				enableAdminLinks="no"
				showThumbnail="#attributes.showThumbnail#"
				readMoreCaption="#attributes.readMoreCaption#"
				embedImage="#attributes.embedImage#"
				separator="#attributes.separator#"
				titleElement="#attributes.titleElement#"
				orderByIds="yes">
	
	</cf_spHandler>
	
</cf_spType>

