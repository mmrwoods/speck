<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spType
	name="DocumentContainer"
	description="Document Container">
	
 	<cf_spProperty
		name="documents"
		caption="Documents"
		type="Picker"
		contentType="Document"
		required="yes"
		dependent="#attributes.context.getConfigString("types","document_container","documents_dependent","no")#"
		maxSelect="#attributes.context.getConfigString("types","document_container","documents_max_select",25)#"
		showSort="yes"
		prepend="yes">
	
	<cf_spHandler method="display">
	
		<cfparam name="attributes.showIcon" type="boolean" default="true">
		
		<cfif len(content.documents)>
		
			<cfscript>
				if ( request.speck.session.showAdminLinks ) {
					where = "";
				} else {
					where = "pubdate <= '" & dateFormat(now(),"YYYY-MM-DD") & "'";
				}
			</cfscript>
			
			<cf_spContent
				type="Document" 
				id="#content.documents#" 
				enableAdminLinks="no"
				showIcon="#attributes.showIcon#"
				separator=""
				where="#where#"
				orderByIds="yes">
					
		</cfif>

	</cf_spHandler>
	
</cf_spType>
