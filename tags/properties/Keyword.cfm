<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spPropertyHandler>


	<cf_spPropertyHandlerMethod method="validateValue">
		
		
		
		<!--- check that keyword string is correctly formatted and is either at root level or has parent --->
	
		<cfif len(value) and not refind("^[A-Za-z][A-Za-z0-9_\.]+[A-Za-z0-9_]$",newValue)>
		
			<cfset lErrors = replace(request.speck.buildString("P_KEYWORD_INVALID_FORMAT","#newValue#"),chr(44),"&##44;","all")>
		
		<cfelseif listLen(value,".") gt 1>
		
			<cfset parent = listDeleteAt(value,listLen(value,"."),".")>
			
			<cfquery name="qParent" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
				SELECT * FROM spKeywords
				WHERE keyword = '#parent#'
			</cfquery>
			
			<cfif not qParent.recordCount>
			
				<cfset lErrors = replace(request.speck.buildString("P_KEYWORD_NO_PARENT","#newValue#,#parent#"),chr(44),"&##44;","all")>

			<cfelse>
				
				<cfif not request.speck.userHasPermission("spSuper") and not listFindNoCase(structKeyList(session.speck.roles),"spEdit")>
				
					<cfif not len(qParent.roles) or not request.speck.userHasPermission(qParent.roles)>
					
						<cfset lErrors = replace(request.speck.buildString("P_KEYWORD_ADD_CHILD_ACCESS_DENIED","#newValue#,#parent#"),chr(44),"&##44;","all")>
						
					</cfif>
				
				</cfif>

			</cfif>
			
		<cfelse>
		
			<!--- must have spSuper or spKeywords to add a top level keyword --->
			<cfquery name="qCheckExists" datasource="#request.speck.codb#">
				SELECT spId FROM spKeywords WHERE keyword = '#newValue#'
			</cfquery>
			
			<cfif not qCheckExists.recordCount and not request.speck.userHasPermission("spSuper") and not listFindNoCase(structKeyList(session.speck.roles),"spEdit")>

				<!--- must have spSuper or site-wide spEdit (and spKeywords) to a top level keyword --->
				<cfset lErrors = replace(request.speck.buildString("P_KEYWORD_ADD_ACCESS_DENIED","#newValue#"),chr(44),"&##44;","all")>
				
			</cfif>
		
		</cfif>
		
		<cfif not len(lErrors) and isDefined("request.speck.maxKeywordLevels") and listLen(value,".") gt request.speck.maxKeywordLevels>
		
			<cfset lErrors = replace(request.speck.buildString("P_KEYWORD_GT_MAX_LEVELS","#newValue#,#listLen(value,".")#,#request.speck.maxKeywordLevels#"),chr(44),"&##44;","all")>
		
		</cfif>
		
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="renderFormField">

		<cfparam name="url.parent" default="">
		<cfparam name="url.child" default="">
		
		<cfset url.child = trim(url.child)>
	
		<cfset readonlyAttribute = "">
		<cfif len(value) and action eq "edit">
		
			<cfset readonlyAttribute = 'readonly="yes" class="readonly"'>
			
		<cfelse>
		
			<cfif len(url.parent)>
	
				<cfset value = url.parent & "." & url.child>
				
			<cfelseif len(url.child)>
	
				<cfset value = url.child>
				
			</cfif>
		
			<cfset value = replaceNoCase(value," and ","_","all")> <!--- maybe this is unnecessary --->
			<cfset value = lCase(reReplace(value,"[^A-Za-z0-9\.]+","_","all"))>
			
		</cfif>
	
		<cfoutput><input #readonlyAttribute# type="text" name="#stPD.name#" value="#value#" size="#stPD.displaySize#" maxlength="#stPD.maxlength#"></cfoutput>
		
		<!--- durty hack to allow other properties take action if the keyword has children (roles and groups may force permissions on child keywords) --->
		<cfset request.bKeywordHasChildren = false>
		
		<cfif len(value)>
		
			<cfquery name="qChildren" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
				SELECT keyword FROM spKeywords
				WHERE keyword LIKE '#value#.%'
			</cfquery>
			
			<cfset request.bKeywordHasChildren = yesNoFormat(qChildren.recordCount)>
		
		</cfif>

	</cf_spPropertyHandlerMethod>
	
	
</cf_spPropertyHandler>

