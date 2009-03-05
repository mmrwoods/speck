<cfsetting enablecfoutputonly="Yes">

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
		maxSelect="25"
		showSort="yes"
		showAdd="yes"
		showEdit="yes">
	
	<cf_spHandler method="display">
	
		<cfparam name="attributes.showIcon" type="boolean" default="true">
		
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

	</cf_spHandler>
	
</cf_spType>
