<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spPropertyHandler>
	
	
	<cf_spPropertyHandlerMethod method="renderFormField">
		
		<cfoutput>
		<script type="text/javascript">
			var changeTemplateWarning = true; // set to false once warning shown
			function showChangeTemplateWarning() {
				if ( changeTemplateWarning ) {
					alert('Note: Changing the template may result in\nsome existing content disappearing from view.\n\nIf this happens, you can restore the content\nby switching back to the original template.');
					changeTemplateWarning = false;
				}
			}
		</script>
		<select name="#stPD.name#"<cfif structKeyExists(url,"action") and url.action eq "edit"> onchange="showChangeTemplateWarning();"</cfif>>
		</cfoutput>
		
		<cfif not stPD.required>
		
			<!--- throw in an empty option/value --->
			<cfoutput><option value="">-- use default (<cfif isDefined("request.speck.portal.template") and len(request.speck.portal.template)>#request.speck.portal.template#<cfelse>text</cfif>) --</option></cfoutput>
		
		</cfif>
		
		<cfset fs = request.speck.fs>
		
		<cfdirectory directory="#request.speck.appInstallRoot##fs#templates" sort="name ASC" name="qTemplates" filter="*.cfm">
		
		<cfloop query="qTemplates">
		
			<cfset templateName = replaceNoCase(name,".cfm","")>
		
			<cfoutput>
			<option value="#templateName#"<cfif value eq templateName> selected</cfif>>#templateName#</option>
			</cfoutput>
		
		</cfloop>
			
		<cfoutput>
		</select>
		</cfoutput>
	
	</cf_spPropertyHandlerMethod>
	
	
</cf_spPropertyHandler>
