<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com),
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spType
	name="ImageContainer"
	description="Image Container">
	
	<cf_spProperty
		name="images"
		caption="Images"
		type="Picker"
		contentType="Image"
		required="yes"
		maxSelect="#attributes.context.getConfigString("types","image_container","images_max_select",25)#"
		dependent="#attributes.context.getConfigString("types","image_container","images_dependent","no")#"
		showSort="yes">
	
	<cf_spHandler method="display">
		
		<cfparam name="attributes.displayColumns" default="1">
		<cfparam name="attributes.showCaption" default="yes">
		
		<cf_spContent
			type="Image"
			method="thumbnail"
			id="#content.images#"
			enableAdminLinks="no"
			showCaption="#attributes.showCaption#"
			columns="#attributes.displayColumns#"
			orderByIds="yes">
	
	</cf_spHandler>

</cf_spType>

