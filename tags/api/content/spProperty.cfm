<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!---
Description:

	Define property settings in a content type's type handler script.

Usage:

	<handler script
		method = "spTypeDefinition|method name"
		r_stType = "variable name"
		qContent=#query#
		type="string"
		separator="string"
		columns=number
		updateContent="yes|no"
		context = "structure">
	
		<cf_spType
			...>
			
			<cf_spProperty
				name = "property name"
				type = "text|html|check|radio|select|asset|picker|..."
				caption = "Property caption used on edit form"
				required = "yes|no"
				displaySize = "field display size"
				maxLength = "max field size to save in characters"
				index = "yes|no"
				...
				attributes particular to property type>
				
			<cf_spHandler
				...>
				
		</cf_spType>

	
Attributes:	

	handler script:
	
		method(string, optional):		Default "spTypeDefinition".  If spTypeDefinition, return type structure in variable r_stType.  
										Otherwise ignore cf_spProperty tags and invoke handler with matching method if it exists.
		context(structure, optional):	Default to request.speck.  Only used when spApp calls handler, as request scope not set up at that point.	
										
	cf_spProperty:
	
		name(string, required):			Property name, should match column in content type's table.
		type(string, required):  		Property type, corresponding to property handler name in /tags/propertyHandlers directory.
		caption(string, required):		Property caption used on edit form.
		required(boolean, optional):	Default "no".
		displaySize(string, optional):	Default 50. Dimensions of edit control.  For simple property types this is the length in characters, or "width,height"
										in characters for textarea-like controls.  Other property types may have custom formats for this attribute.
		maxLength(number, optional):	Max length of content to allow in characters.
		index(boolean, optional):		Default "no".  Create index on database column.

		Remaining attributes are particular to each property type.  See property handler script for attribute definitions.
--->
 
<!--- If context provided to caller use that, else use request.speck --->
<cfscript>

	ca = caller.attributes;
	
	if (not isDefined("ca.context"))
		ca.context = request.speck;
	
	speckInstallRoot = ca.context.speckInstallRoot;
	fs = ca.context.fs;
	
</cfscript>

<!--- Check we are placed inside cf_spType tag --->
<cfset lBaseTags = getBaseTagList()>
<cfif listFind(lBaseTags, "CF_SPTYPE") eq 0>

	<cf_spError error="PR_NOT_IN_TYPE" lParams="" context=#ca.context#>	<!--- Must be placed inside cf_spType tag --->

</cfif>

<!--- Only execute if spType method is "spTypeDefinition" --->
<cfset stTypeVars = getBaseTagData("CF_SPTYPE")>

<cfif stTypeVars.a.method neq "spTypeDefinition">

	<cfexit method="EXITTAG">

</cfif>

<!--- If this tag has nested spProperty tags, only run at end tag --->

<cfif thisTag.hasEndTag and thisTag.executionMode eq "START">

	<cf_spDebug msg="Skipping processing for property #attributes.name# because tag has end tag and execution mode = START" context=#ca.context#>

<cfelse>

	<cf_spDebug msg="Processing property #attributes.name#" context=#ca.context#>

	<!--- Validate attributes --->
	
	<cfset a = attributes>
	
	<cfloop list="name,type,caption" index="attribute">
	
		<cfif not isdefined("a.#attribute#")>
		
			<cf_spError error="ATTR_REQ" lParams="#attribute#" context=#ca.context#>	<!--- Missing attribute --->
			
		</cfif>
	
	</cfloop>
	
	<cfif not fileExists(speckInstallRoot & fs & "tags" & fs & "properties" & fs & a.type & ".cfm")
		and not fileExists(ca.context.appInstallRoot & fs & "tags" & fs & "properties" & fs & a.type & ".cfm")>
	
		<cf_spError error="PD_NO_HANDLER" lParams=#a.type# context=#ca.context#>	<!--- Can't find property handler --->
	
	</cfif>
	
	<cfparam name="a.required" default="no">
	<cfparam name="a.unique" default="no">
	<cfparam name="a.displaySize" default="50">
	<cfparam name="a.maxLength" default="50">
	<cfparam name="a.index" default="no">		<!--- Create database index? --->
	<cfparam name="a.finder" default="no">		<!--- Use this property as one of the search fields in the content finder --->
	
	<!--- class and style attributes are used in spDefault type when rendering edit form --->
	<cfparam name="a.class" default="">
	<cfparam name="a.style" default="">
	
	<!--- Default settings for all property types.  validateAttributes action can override the settings for a specific property type --->
	<cfset a.saveToDatabase = "yes">  		<!---  Save property values to database column with matching name --->
	<cfset a.databaseColumnType = "TEXT">	<!--- One of DATETIME, FLOAT, INTEGER, TEXT --->
	
	<!--- these are attributes for spPropertyHandler, but we need to return them to spType so they are stored in the meta data for the type (and property) --->
	<cfparam name="attributes.extends" default="">
	<cfparam name="attributes.final" default="no">
	
	<cfset validateAttributesTemplate = "/#ca.context.mapping#/properties/#a.type#.cfm"> <!--- default path to template containing validateAttributes method --->
	
	<!--- check if we're doing type definition... --->
	<cfset stTypeVars = getBaseTagData("CF_SPTYPE")>
	
	<cfif stTypeVars.a.method eq "spTypeDefinition">

		<!--- if doing type definition, do property definition, i.e. get methods list --->
		
		<cfscript>
			// get the default handler template
			fs = ca.context.fs;
			if ( fileExists("#ca.context.appInstallRoot##fs#tags#fs#properties#fs##a.type#.cfm") )
				handlerTemplate = "/" & ca.context.mapping & "/properties/" & a.type & ".cfm";
			else {
				attributes.extends = ""; // server properties cannot inherit from other properties
				validateAttributesTemplate = "/speck/properties/" & a.type & ".cfm"; // change validateAttributes path
				handlerTemplate = "/speck/properties/" & a.type & ".cfm";
			}
		</cfscript>
		
		<!--- get property definition --->
		<cfmodule template="#handlerTemplate#" method="spPropertyDefinition" stPD=#a#>
		
		<cfscript>
		
			// deal with methods...
			if ( isDefined("thisTag.methods") ) {
			
				attributes.methods = structNew();
				
				// default handler template for this property				
				if ( fileExists("#ca.context.appInstallRoot##fs#tags#fs#properties#fs##a.type#.cfm") )		
					handlerTemplate = "/" & ca.context.mapping & "/properties/" & a.type & ".cfm";
				else
					handlerTemplate = "/speck/properties/" & a.type & ".cfm";
				
				for(i=1; i le arrayLen(thisTag.methods); i = i + 1)
					structInsert(attributes.methods, thisTag.methods[i].method, handlerTemplate);
			
			}
			
			// get extends and final attributes from property handler (directly reference the first index in the array - spPropertyHander cannot be nested)
			attributes.extends = thisTag.propertyHandlerAttributes[1].extends;
			// attributes.final = thisTag.propertyHandlerAttributes[1].final;  <--- not implemented
		
		</cfscript>
		
		<cfif len(trim(attributes.extends))>
		
			<!--- property extends another, get inherited methods... --->
			<cfmodule template="/speck/properties/#trim(attributes.extends)#.cfm" method="spPropertyDefinition" stPD=#a#>
			
			<cfscript>
			
				// deal with methods...
				if ( isDefined("thisTag.methods") ) {
				
					lLocalMethods = structKeyList(attributes.methods); // list of local methods
					
					// if validateAttributes method not found in list of local methods, assume it must be a method of the extended type...
					if ( not listFindNoCase(lLocalMethods,"validateAttributes") )
						validateAttributesTemplate = "/speck/properties/" & attributes.extends & ".cfm";
				
					// create methods structure if not already created, though it should be seeing as we're inheriting
					if ( not isDefined("attributes.methods") )
						attributes.methods = structNew();
											
					// inherit methods from extended property (note: local methods always override methods in extended property)
					for(i=1; i le arrayLen(thisTag.methods); i = i + 1) {
					
						if ( not listFindNoCase(lLocalMethods,thisTag.methods[i].method) )
							structInsert(attributes.methods, thisTag.methods[i].method, "/speck/properties/" & attributes.extends & ".cfm");
						
					}

				}	
			
			</cfscript>
		
		</cfif>

	</cfif>
	
	<!--- Call property handler, method="validateAttributes" to give it a chance to throw an error for invalid attributes and default others --->
	<cfmodule template="#validateAttributesTemplate#" method="validateAttributes" stPD=#a# r_stPD="stValidatedPD">
	<cfset attributes = duplicate(stValidatedPD)>
	
	<!--- 
		Return structure to base tag - spProperty tags can be nested for some property types
		such as table or structure, so if this tag is nested inside another spProperty pass
		the property attributes back to that tag, otherwise pass back to spType tag
	--->
	
	<cfif listValueCountNoCase(getBaseTagList(),"CF_SPPROPERTY") gt 1>
	
		<!--- nested property --->
	
		<cftry>
	
			<cfif isDefined("thisTag.props")>
				
				<cfset attributes.props = thisTag.props>
			
			</cfif>	
	
			<cfassociate basetag="CF_SPPROPERTY" datacollection="props">
		
		<cfcatch type="Any">
		
			<cf_spDebug msg="Caught error '#cfcatch.message#' trying to associate with cf_spProperty, trying to associate #a.name# attributes with SPTYPE instead" context=#ca.context#>
			<cfassociate basetag="CF_SPTYPE" datacollection="props">
		
		</cfcatch>
		</cftry>		
	
	<cfelse>
	
		<cfassociate basetag="CF_SPTYPE" datacollection="props">
	
	</cfif>


</cfif>