<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spPropertyHandler>

		
	<cf_spPropertyHandlerMethod method="validateAttributes">
	
		<cfparam name="stPD.inputType" default="radio">
		<cfparam name="stPD.defaultValue" default="0">
		
		<cfif not listFind("0,1",stPD.defaultValue)>
		
			<cf_spError error="ATTR_INV" lParams="#stPD.defaultValue#,defaultValue" context=#caller.ca.context#>
		
		</cfif>
	
		<cfset stPD.databaseColumnType = "integer">
		
		<cfset stPD.maxLength = 1>
		
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="readFormField">
		
		<cfscript>
			newValue = value;
			if ( not isBoolean(newValue) ) {
				newValue = 0;
			} else if (newValue) {
				newValue = 1;
			} else {
				newValue = 0;
			}
		</cfscript>
			
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="renderFormField">
	
		<cfparam name="stPD.inputType" default="radio">
		<cfparam name="stPD.defaultValue" default="0">
		
		<cfparam name="stPD.trueCaption" default="Yes">
		<cfparam name="stPD.falseCaption" default="No">
		<cfparam name="stPD.checkboxCaption" default="">
		
		<cfscript>
			if ( not isBoolean(value) ) {
				value = stPD.defaultValue;
			}
		</cfscript>

		<cfif stPD.inputType eq "checkbox">
		
			<cfoutput>
			<input style="vertical-align:middle;" type="checkbox" name="#stPD.name#" value="1" size="#stPD.displaySize#" maxlength="#stPD.maxlength#"<cfif value> checked</cfif>>
			<cfif len(stPD.checkboxCaption)><em style="vertical-align:middle;">#stPD.checkboxCaption#</em></cfif>
			</cfoutput>
			
		<cfelse>
			
			<cfoutput>
			<input style="vertical-align:middle;" type="radio" name="#stPD.name#" value="1"<cfif value> checked</cfif>>
			<span style="vertical-align:middle;">#stPD.trueCaption#&nbsp;&nbsp;&nbsp;&nbsp;</span>
			<input style="vertical-align:middle;" type="radio" name="#stPD.name#" value="0"<cfif not value> checked</cfif>>
			<span style="vertical-align:middle;">#stPD.falseCaption#&nbsp;&nbsp;&nbsp;&nbsp;</span>
			</cfoutput>
			
		</cfif>
	
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="contentPut">

		<cfparam name="stPD.defaultValue" default="0">
	
		<cfscript>
			if ( not isBoolean(newValue) ) {
				newValue = stPD.defaultValue;
			} else if (newValue) {
				newValue = 1;
			} else {
				newValue = 0;
			}
		</cfscript>
	
	</cf_spPropertyHandlerMethod>
	
	
</cf_spPropertyHandler>
