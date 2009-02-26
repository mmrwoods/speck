<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->
<!---
Description:

	Mark code to be executed when propertyHandler called with specified method.  The following variables are available to the handler code:
	
	value:		Read only.  Current property value.
	type:		Read only.	Current content item type.
	id:			Read only.  Current content item id.
	revision:	Read only.  Current content item revision.
	newLevel	Read only.  Promotion level current revision of content item is being promoted to.
	newValue:	Read/write.  Proposed new property value.  Modifications to this variable will apply to value returned by contentGet or saved to database by contentPut.
	lErrors:	Write Only.  Comma separated list of validation errors to report to user when method = "validateValue"
	stPD:		Read/write.  Structure containing property definition attributes.

Usage:

	<cf_spPropertyHandler>
	
		<cf_spPropertyHandlerMethod method="validateAttributes|validateValue|renderFormField|readFormField|contentGet|contentPut|promote">
		
		</cf_spPropertyHandlerMethod>
		
		...
	
	</cf_spPropertyHandler>
	
Attributes:	
			
	method(string, required):		validateAttributes: Handler should call speckError if the property attributes in stPropertyAttrs are invalid.
									validateValue: 		Handler should validate value attribute and write comma seperated list of errors to lErrors.
									renderFormField: 	Handler should render HTML to display property on edit form with existing value.
									readFormField:		Handler should set newValue according to posted form variables.  If no handler method implemented default behaviour
														is to copy form.#stPD.name# to newValue.
									contentGet: 		Handler should perform any loading/modification required on newValue before it is returned by contentGet.
									contentPut: 		Handler should perform any saving/modification required on newValue when contentPut called.
									promote:			Handler should peform actions required when content item is promoted to new level.
--->

<cfset a = attributes>

<cfif thisTag.executionMode eq "START">

	<!--- Check we are placed inside cf_propertyHandler tag --->
	<cfif listFind(getBaseTagList(), "CF_SPPROPERTYHANDLER") eq 0>
	
		<cf_spError error="PHA_NOT_IN_PH" lParams="">	<!--- Must be placed inside cf_propertyHandler tag --->
	
	</cfif>

	<!--- spTypeDefinition?? --->
	<cfif find("CF_SPTYPE",getBaseTagList())>
	
		<cfset stTypeVars = getBaseTagData("CF_SPTYPE")>

		<cfif stTypeVars.a.method eq "spTypeDefinition">
	
			<cfassociate basetag="CF_SPPROPERTY" datacollection="methods">
		
		</cfif>
	
	</cfif>

	<!--- Only execute if propertyHandler method attribute matches propertyHandlerAction method attribute --->
	<cfset stPropertyHandlerVars = getBaseTagData("CF_SPPROPERTYHANDLER")>

	<cfif a.method neq stPropertyHandlerVars.a.method>
	
		<cfexit method="EXITTAG">
	
	</cfif>
		
	<!--- Validate attributes --->
	<cfif not isdefined("a.method")>
	
		<cf_spError error="ATTR_REQ" lParams="method">	<!--- Missing attribute --->
		
	</cfif>
	
	<cfif not listFind("validateAttributes,validateValue,renderFormField,readFormField,contentGet,contentPut,promote,spPropertyDefinition,delete", a.method)>
	
		<cf_spError error="PH_ACTION" lParams="#a.method#">	<!--- Invalid property handler method --->
	
	</cfif>	
	
</cfif>