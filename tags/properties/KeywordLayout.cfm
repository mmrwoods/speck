<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spPropertyHandler>
	
	
	<cf_spPropertyHandlerMethod method="renderFormField">
	
		<cfset fs = request.speck.fs>
		
		<cfdirectory directory="#request.speck.appInstallRoot##fs#layouts" sort="name ASC" name="qLayouts" filter="*.cfm">
		
		<cfoutput>
		<select name="#stPD.name#"<cfif qLayouts.recordCount lte 1> disabled="yes"</cfif>>
		</cfoutput>
		
		<cfif not stPD.required>
		
			<!--- throw in an empty option/value --->
			<cfoutput><option value="">-- use default (<cfif isDefined("request.speck.portal.layout") and len(request.speck.portal.layout)>#request.speck.portal.layout#<cfelse>none</cfif>) --</option></cfoutput>
		
		</cfif>
		
		<cfloop query="qLayouts">
		
			<cfset layoutName = replaceNoCase(name,".cfm","")>
		
			<cfoutput>
			<option value="#layoutName#"<cfif value eq layoutName> selected</cfif>>#layoutName#</option>
			</cfoutput>
		
		</cfloop>
			
		<cfoutput>
		</select>
		</cfoutput>
	
	</cf_spPropertyHandlerMethod>
	
	
</cf_spPropertyHandler>