<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spPropertyHandler>

	<cf_spPropertyHandlerMethod method="validateAttributes">

		<cfparam name="stPD.minValue" default="">
		<cfparam name="stPD.maxValue" default="">
		<cfparam name="stPD.decimalPlaces" type="numeric" default="0">
		
		<cfparam name="stPD.defaultValue" default=""> <!--- default value for form field --->
		
		<cfif len(stPD.defaultValue) and ( ( stPD.decimalPlaces eq 0 and stPD.defaultValue neq int(stPD.defaultValue) ) or ( stPD.decimalPlaces gt 0 and find(".",stPD.defaultValue) and len(listLast(stPD.defaultValue,".")) gt stPD.decimalPlaces ) )>
		
			<cf_spError error="ATTR_INV" lParams="#stPD.defaultValue#,defaultValue" context=#caller.ca.context#>	<!--- Invalid default value --->
		
		</cfif>
		
		<cfif stPD.decimalPlaces gt 0>
		
			<cfset stPD.databaseColumnType = "float">
		
		<cfelse>
		
			<cfset stPD.databaseColumnType = "integer">
		
		</cfif>
		
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="readFormField">

		<!--- strip thousand separators --->
		<cfset newValue = replace(value,",","","all")>
			
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="validateValue">

		<cfif len(newValue)>
		
			<!--- Check that value is numeric --->	
			<cfif not isNumeric(newValue)>
			
				<cfset lErrors = request.speck.buildString("P_NUMBER_NOT_NUMERIC","#stPD.caption#,#newValue#")>
				
			<cfelse>
			
				<cfif stPD.decimalPlaces gt 0>
				
					<cfif find(".",newValue) and len(listLast(newValue,".")) gt stPD.decimalPlaces>
						
						<cfset lErrors = request.speck.buildString("P_NUMBER_INVALID_DECIMALPLACES","#stPD.caption#,#newValue#,#stPD.decimalPlaces#")>
						
					</cfif>
				
				<cfelseif newValue neq int(newValue)>
				
					<cfset lErrors = request.speck.buildString("P_NUMBER_NOT_INTEGER","#stPD.caption#,#newValue#")>
				
				</cfif>
				
				<cfif len(stPD.minValue) and newValue lt stPD.minValue>
				
					<cfset lErrors = request.speck.buildString("P_NUMBER_LT_MIN_VALUE","#stPD.caption#,#newValue#,#stPD.minValue#")>
				
				</cfif>
				
				<cfif len(stPD.maxValue) and newValue gt stPD.maxValue>
				
					<cfset lErrors = request.speck.buildString("P_NUMBER_GT_MAX_VALUE","#stPD.caption#,#newValue#,#stPD.maxValue#")>
				
				</cfif>
			
			</cfif>
		
		</cfif>

	</cf_spPropertyHandlerMethod>
	
	<cf_spPropertyHandlerMethod method="renderFormField">
		
		<cfparam name="stPD.defaultValue" default=""> <!--- temporary code - remove once all apps have been refreshed --->
		
		<cfif len(stPD.defaultValue) and value eq "" and ( action eq "add" and cgi.request_method neq "post" )>
		
			<cfset value = stPD.defaultValue>
		
		</cfif>
		
		<cfif isNumeric(value)>
		
			<cfif stPD.decimalPlaces gt 0>
			
				<cfset formatMask = repeatString("_",len(listFirst(value,"."))) & "." & repeatString("0",stPD.decimalPlaces)>
				
				<cfset value = numberFormat(value,"#formatMask#")>
				
			<cfelse>
			
				<cfset value = numberFormat(value)>
			
			</cfif>
		
		</cfif>

		<cfoutput><input type="text" name="#stPD.name#" value="#value#" size="#stPD.displaySize#" maxlength="#stPD.maxlength#"></cfoutput>
		
	</cf_spPropertyHandlerMethod>
	
	<!--- No customised actions implemented for readFormField, contentGet or contentPut --->
	
</cf_spPropertyHandler>