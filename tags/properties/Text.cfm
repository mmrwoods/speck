<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spPropertyHandler>


	<cf_spPropertyHandlerMethod method="validateAttributes">
	
		<cfparam name="stPD.password" type="boolean" default="no">
		<cfparam name="stPD.httpurl" type="boolean" default="no">
		<cfparam name="stPD.allowRelativeUrl" type="boolean" default="yes"> <!--- only relevant when stPD.httpUrl is true --->
		<cfparam name="stPD.email" type="boolean" default="no">
		<cfparam name="stPD.convertWin1252" type="boolean" default="true">		
		<cfparam name="stPD.defaultValue" default=""> <!--- default value for form field --->
		
		<cfparam name="stPD.match" default=""> <!--- optional regular expression pattern to test against --->
		
		<cfparam name="stPD.editable" type="boolean" default="yes"> <!--- allow property value to be edited once added? --->
		
		<!--- Check format of displaySize attribute, allowed formats are "N" or "N,M" --->
		<cfset ds = stPD.displaySize>
		<cfif not (((listLen(ds) eq 1) and isNumeric(ds)) or ((listLen(ds) eq 2) and (isNumeric(listFirst(ds)) and isNumeric(listLast(ds)))))>
		
			<cf_spError error="PH_TEXT_DS" lParams="#ds#" context=#caller.ca.context#>	<!--- Invalid displaySize format --->
		
		</cfif>
	
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="validateValue">
		
		<cfif len(stPD.match) and len(value) and not reFind(stPD.match,newValue)>
		
			<cfset lErrors = request.speck.buildString("P_TEXT_MATCH_FAILED","#stPD.caption#,#newValue#")>
			
		</cfif>
		
		<!--- Check that passwords match for password field --->	
		<cfif stPD.password and stPD.confirm and (newValue neq form[stPD.name & "_confirm"])>
		
			<cfset lErrors = request.speck.buildString("P_TEXT_PASSWORD_NEQ_CONFIRM","#stPD.caption#")>
		
		</cfif>
		
		<!--- Check for valid email address format (assumes user@host) --->	
		<cfif stPD.email and len(newValue) and not reFind("^([a-zA-Z0-9][-a-zA-Z0-9_%\.'\+]*)?[a-zA-Z0-9]@[a-zA-Z0-9][-a-zA-Z0-9%\>.]*\.[a-zA-Z]{2,}$",newValue)>
		
			<cfset lErrors = request.speck.buildString("P_TEXT_NOT_EMAIL","#stPD.caption#,#newValue#")>
		
		</cfif>
		
		<cfif stPD.httpurl and len(newValue) and ( left(newValue,1) neq "/" and not reFindNoCase("^http[s]{0,1}://[^[:space:]]+$",newValue) )>
			
			<cfset lErrors = request.speck.buildString("P_TEXT_NOT_URL","#stPD.caption#,#newValue#")>
			
		</cfif>
		
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="readFormField">
		
		<cfset newValue = value>

		<cfif stPD.httpurl and len(newValue)>

			<cfif reFindNoCase("^http[s]{0,1}://$",newValue)>
			
				<!--- value is just protocol --->
				<cfset newValue = "">
			
			<cfelseif not reFindNoCase("^http[s]{0,1}://",newValue) and ( not stPD.allowRelativeUrl or left(newValue,1) neq "/" )>
			
				<!--- value missing protocol, try to handle malformed protocol --->
				<cfset newValue = "http://" & reReplaceNoCase(newValue,"^http(:)?/{0,}","")>
			
			</cfif>
			
			<cfif stPD.allowRelativeUrl>
			
				<!--- don't save protocol and host name with relative urls --->
				<cfset newValue = reReplaceNoCase(newValue,"http(s)?://#cgi.HTTP_HOST#(/)?","/","all")>
				
			</cfif>
		
		</cfif> 
		
		<cfif stPD.convertWin1252 and not stPD.email and not stPD.httpurl and not stPD.password>
			
			<cfif request.speck.cfVersion eq 5>
			
				<!--- replace some Windows 1252 chars with nearest ASCII equivalents --->
				<cfset newValue = replaceList(newValue,"#chr(133)#,#chr(145)#,#chr(146)#,#chr(147)#,#chr(148)#,#chr(150)#,#chr(151)#,#chr(152)#","...,',',"","",-,-,~")>
				
			<cfelse>
			
				<!--- convert to equivalent unicode code point --->
				<cfset lFind = "#chr(128)#,#chr(130)#,#chr(131)#,#chr(132)#,#chr(133)#,#chr(134)#,#chr(135)#,#chr(136)#,#chr(137)#,#chr(138)#,#chr(139)#,#chr(140)#,#chr(142)#,#chr(145)#,#chr(146)#,#chr(147)#,#chr(148)#,#chr(149)#,#chr(150)#,#chr(151)#,#chr(152)#,#chr(153)#,#chr(154)#,#chr(155)#,#chr(156)#,#chr(158)#,#chr(159)#">
				<cfset lReplace = "#chr(8364)#,#chr(8218)#,#chr(402)#,#chr(8222)#,#chr(8230)#,#chr(8224)#,#chr(8225)#,#chr(710)#,#chr(8240)#,#chr(352)#,#chr(8249)#,#chr(338)#,#chr(381)#,#chr(8216)#,#chr(8217)#,#chr(8220)#,#chr(8221)#,#chr(8226)#,#chr(8211)#,#chr(8212)#,#chr(732)#,#chr(8482)#,#chr(353)#,#chr(8250)#,#chr(339)#,#chr(382)#,#chr(376)#">
				<cfset newValue = replaceList(newValue,lFind,lReplace)>
			
			</cfif>
		
		</cfif>
		
	</cf_spPropertyHandlerMethod>
		
	
	<cf_spPropertyHandlerMethod method="renderFormField">

		<cfset readonlyAttribute = "">
		<cfif len(value) and not stPD.editable and action eq "edit">
		
			<cfset readonlyAttribute = 'readonly="yes" class="readonly"'>
			
		</cfif>		
		
		<cfif len(stPD.defaultValue) and value eq "" and ( action eq "add" and cgi.request_method neq "post" )>
		
			<cfset value = stPD.defaultValue>
		
		</cfif>

		<cfif listLen(stPD.displaySize) eq 2>
		
			<cfoutput><textarea class="text" #readonlyAttribute# name="#stPD.name#" id="#stPD.name#" wrap="virtual" cols="#listFirst(stPD.displaySize)#" rows="#listLast(stPD.displaySize)#">#value#</textarea></cfoutput>
		
		<cfelse>
		
			<cfif stPD.password>
			
				<cfoutput><input class="password" #readonlyAttribute# type="password" name="#stPD.name#" id="#stPD.name#" value="#value#" size="#stPD.displaySize#" maxlength="#stPD.maxlength#"></cfoutput>
				
				<cfif stPD.confirm>
				
					<cfif isDefined("form.#stPD.name#_confirm")>
						
						<cfset confirmValue = evaluate("form.#stPD.name#_confirm")>
						
					<cfelse>
					
						<cfset confirmValue = value>
					
					</cfif>
				
					<cfoutput>#request.speck.buildString("P_TEXT_CONFIRM_CAPTION")# <input class="password" type="password" name="#stPD.name#_confirm" id="#stPD.name#_confirm" value="#confirmValue#" size="#stPD.displaySize#" maxlength="#stPD.maxlength#"></cfoutput>
				
				</cfif>
			
			<cfelse>
			
				<cfoutput><input class="text" #readonlyAttribute# type="text" name="#stPD.name#" id="#stPD.name#" value="#replace(value,"""","&quot;","all")#" size="#stPD.displaySize#" maxlength="#stPD.maxlength#"></cfoutput>
			
			</cfif>
		
		</cfif>
	
	</cf_spPropertyHandlerMethod>
	
	
</cf_spPropertyHandler>