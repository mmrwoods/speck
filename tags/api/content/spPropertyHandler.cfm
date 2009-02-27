<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->
<!---

Description:

	Called by property handlers to validate attributes and organise handler code. Property handler actions are normally called in the following sequence:
	
		-	validateAttributes is called by propertyDef when the property definition is loaded (once per request).
		-	contentGet is called by contentGet to load property values not stored in the database (e.g. assets) or 
			modify database values somehow (e.g. parsing <content> tags in html property values) before they are returned by contentGet.
		-	renderFormField and readFormField are only called by edit forms, the first to render the field HTML (e.g. an <input> tag)
			and the second to read the value posted in the form submit.  The default read behaviour if no handler method is specified is to copy the
			form variable matching the property name to newValue, but sometimes more is requrired (e.g. picker has to remove items selected for
			deletion from the content id list according to checkbox values).
		-	validateValue is normally used by edit forms to build a list of errors to present to the user when a form is submitted, but it could also
			be used in other situations (e.g. a bulk import to reject invalid content and log a reason for rejection).
		-	contentPut is called by contentPut to save property values not stored in the database (e.g. assets) or
			modify database values somehow (e.g a timestamp property being set to the current time) before storage.
		-	promote is called when a content item is promoted to a new level, passed in the newLevel attribute.  At the moment this is only used by
			asset properties to copy/remove asset files from the browsable asset directory when content gets promoted to live.

Usage:

	<cf_spPropertyHandler>
	
		<cf_spPropertyHandlerMethod method="">
		
		</cf_spPropertyHandlerMethod>
		
		...
	
	</cf_spPropertyHandler>
	
Attributes:	
	
	propertyHandler expects the following attributes to be passed to the calling property handler:
	
	method(string, required):		validateAttributes:	Handler should set defaults in stPD and call speckError if the property attributes in stPD are invalid.
									contentGet:			Handler should perform any loading/modification required on newValue before it is returned by contentGet.
									renderFormField:	Handler should render HTML to display property on edit form with existing value.
									readFormField:		Handler should set newValue according to posted form variables.  If no handler method implemented default behaviour
														is to copy form.#stPD.name# to newValue.
									validateValue: 		Handler should validate newValue attribute and write comma seperated list of errors to lErrors.
									contentPut: 		Handler should perform any saving/modification required on newValue when contentPut called.
									
	stPD(structure, required):		Structure containing attributes specified in propDef tag.
	value(string, required):		Required if method = validateValue, renderFormField or contentGet.  Existing value.
	id(uuid, required):				Required if method = validateValue, renderFormField, readFormField, contentGet, contentPut or promote.  Id of content item.
	type(string, required):			Required if method = contentGet.
	revision(number, required):		Required if method = validateValue, renderFormField, readFormField, contentGet, contentPut or promote.  Revision number of content item.
	newValue(string, required):		Required if method = validateFormField or contentPut.  New value.
	newLevel(string, required):		Required if method = promote.  New promotion level.  
	r_lErrors(string, required):	Required if method = validateFormField.  Name of variable to return list of validation errors in when method = validateFormField
	r_newValue(string, required):	Required if method = readFormField, contentGet or contentPut.  Name of variable to return transformed content in.
	r_stPD(string, required):		Required if method = validateAttributes.  Name of variable to return validated stPD structure (e.g. cfparamed attributes)
--->

<cfparam name="url.type" default="">
<cfparam name="caller.attributes.contentType" default="#url.type#">

<cfset a = caller.attributes>

<cfif thisTag.executionMode eq "START">

	<!--- spTypeDefinition?? --->
	<cfif find("CF_SPTYPE",getBaseTagList())>
	
		<cfset stTypeVars = getBaseTagData("CF_SPTYPE")>

		<cfif stTypeVars.a.method eq "spTypeDefinition">
		
			<!--- if type definition, we need to pass back the extends and final attributes to spProperty --->
		
			<cfparam name="attributes.extends" default="">
			<!--- <cfparam name="attributes.final" default="no"> ---> <!--- not implemented --->
			
			<cfassociate basetag="CF_SPPROPERTY" datacollection="propertyHandlerAttributes">			

		</cfif>
	
	</cfif>

	<!--- Validate attributes --->
	<cfif not isdefined("a.method")>
	
		<cf_spError error="ATTR_REQ" lParams="method">	<!--- Missing attribute --->
		
	</cfif>
	
	<cfif not listFind("validateAttributes,validateValue,renderFormField,readFormField,contentGet,contentPut,promote,spPropertyDefinition,delete", a.method)>
	
		<cf_spError error="PH_ACTION" lParams="#a.method#">	<!--- Invalid property handler method --->
	
	</cfif>
	
	<cfscript>
	
		reqAttrs = "stPD";
		
		switch (a.method) {
			case "validateAttributes": {
				reqAttrs = reqAttrs & ",r_stPD";
				break;
			}
			case "validateValue": {
				reqAttrs = reqAttrs & ",value,newValue,r_lErrors,id,revision";
				break;
			}
			case "renderFormField": {
				reqAttrs = reqAttrs & ",value,id,revision";
				break;
			}
			case "readFormField": {
				reqAttrs = reqAttrs & ",r_newValue";
				break;
			}
			case "contentGet": {
				reqAttrs = reqAttrs & ",value,r_newValue,id,type,revision";
				break;
			}
			case "contentPut": {
				reqAttrs = reqAttrs & ",newValue,r_newValue,id,revision";
				break;
			}
			case "promote": {
				reqAttrs = reqAttrs & ",id,revision,newLevel";
				break;
			}
		}
	
	</cfscript>
	
	<cfloop list="#reqAttrs#" index="attribute">
	
		<cfif not isdefined("a.#attribute#")>
		
			<cf_spError error="PH_ATTR_REQ" lParams="#attribute#,#a.method#">	<!--- Missing attribute for method --->
			
		</cfif>
	
	</cfloop>

	<!--- Set handler-scope variables: value, newValue and lErrors --->
	
	<cfscript>
	
		if (isDefined("a.value"))
			caller.value = trim(a.value);
		if (isDefined("a.newValue")) 
			caller.newValue = trim(a.newValue);
		if (isDefined("a.id"))
			caller.id = trim(a.id);	
		if (isDefined("a.type"))
			caller.type = trim(a.type);
		if (isDefined("a.revision"))
			caller.revision = trim(a.revision);	
		if (isDefined("a.newLevel"))
			caller.newLevel = trim(a.newLevel);	
		if (a.method eq "validateValue")
			caller.lErrors = "";
		stPD = a.stPD;
		caller.stPD = stPD;
		

		// new action attribute for renderFormField method
		if ( a.method eq "renderFormField" ) {
			if ( isDefined("a.action") and a.action eq "add" )
				caller.action = "add";
			else
				caller.action = "edit";
		}
	</cfscript>
	
	<!--- Do standard method pre-processing for validateValue --->
	<cfset lErrors = "">
	
	<cfif a.method eq "validateValue">
		
		<cfif stPD.required and trim(a.newValue) eq "">
		
			<cfif stPD.type eq "asset">
			
				<!--- for asset properties, check that both new and existing value is empty --->
				<cfif trim(a.value) eq "">
				
					<cfset lErrors = listAppend(lErrors, request.speck.buildString("A_PROPERTY_REQUIRED",stPD.caption))>
				
				</cfif>
				
			<cfelse>
			
				<cfset lErrors = listAppend(lErrors, request.speck.buildString("A_PROPERTY_REQUIRED",stPD.caption))>
			
			</cfif>

		</cfif>
		
		
		<!--- SOME NASTY EXPERIMENTAL CODE TO ALLOW PROPERTIES REQUIRE THAT OTHER PROPERTIES HAVE VALUES --->
		<cfif not len(lErrors) and isDefined("stPD.requires") and len(stPD.requires)>
		
			<!--- this is a nice idea, but this implementation leaves a lot to be desired (at the moment, validation depends on form variables) --->
		
			<cfif ( stPD.type eq "asset" and ( len(trim(a.value)) or len(trim(a.newValue)) ) ) or ( stPD.type neq "asset" and len(trim(a.newValue)) )>
		
				<!--- remove any spaces from the list --->
				<cfset lRequires = reReplace(stPD.requires,"[[:space:]]+","","all")>
				
				<cfloop list="#lRequires#" index="i">
				
					<cfif structKeyExists(form,i) and trim(form[i]) eq "">
					
						<!--- try to turn the property name into a half decent human readable string --->
						<cfset requiredCaption = reReplace(i,"([a-z])([A-Z])","\1 \2","all")>
						<cfset requiredCaption = lCase(replace(requiredCaption,"_"," ","all"))>
								
						<cfset lErrors = listAppend(lErrors, request.speck.buildString("A_PROPERTY_REQUIRES","#stPD.caption#,#requiredCaption#"))>
					
					</cfif>
				
				</cfloop>
				
			</cfif>
		
		</cfif>
		
		<cfif stPD.unique and len(trim(a.newValue)) and len(a.contentType)> <!--- we need to know the content type to check for a unique property value --->
			
			<!---
			This property value should be unique. This is damn tricky with the promotion model enabled, and in 
			the short term I've gone for the easy solution of just rejecting the property value as not unique 
			if another content item has a matching property value at any revision. With promotion disabled, we 
			just need to check the tip revisions.
			--->
			
			<cfscript>
				// revision to check
				if ( request.speck.enablePromotion ) {
					revision = "all"; // nasty, nasty boys, gimme a nasty groove
				} else {
					revision = ""; // let spContentGet do the work
				}
				// where clause to check if value already in use
				if ( request.speck.dbtype eq "access" ) { // bleedin' access again
					where = "[#stPD.name#] = '#trim(a.newValue)#'";
				} else {
					where = "UPPER(#stPD.name#) = '#uCase(replace(trim(a.newValue),"'","''","all"))#'";
				}
				where = where & " AND spId <> '#a.id#'";
			</cfscript>

			<!--- check for value at this level --->
			<cfmodule template="/speck/api/content/spContentGet.cfm"
		 		type="#a.contentType#"
				properties="spId"
		 		where="#where#"
		 		revision="#revision#"
		 		r_qContent="qCheckUnique">
		 		
		 	<cfif qCheckUnique.recordCount>
		 	
		 		<cfset lErrors = listAppend(lErrors, request.speck.buildString("A_PROPERTY_NOT_UNIQUE","#stPD.caption#,#a.newValue#"))>
		 	
		 	</cfif>	

		</cfif> <!--- isDefined("stPD.unique") and len(a.contentType) --->
		
		<cfif len(trim(a.newValue)) gt stPD.maxLength>
		
			<cfset lErrors = listAppend(lErrors, request.speck.buildString("A_PROPERTY_GT_MAX_LENGTH","#stPD.caption#,#len(a.newValue)#,#stPD.maxLength#"))>
		
		</cfif>

		<cfset caller.lErrors = lErrors>
		
	</cfif>

<cfelse>

	<!--- executionMode = "END", return child tag's lError, newValue and stPD variables --->
	
	<cfloop list="lErrors,newValue,stPD" index="variable">
		
		<cfif isDefined("caller.#variable#") and isDefined("a.r_" & variable)>
	
			<cfset "caller.caller.#a["r_" & variable]#" = evaluate("caller.#variable#")>
	
		</cfif>
	
	</cfloop>
	
	<!--- If method = contentGet and newValue not set by handler, set it to value --->
	
	<cfif a.method eq "contentGet" and not isDefined("caller.newValue")>
	
		<cfset "caller.caller.#a.r_newValue#" = a.value>
	
	</cfif>

	<!--- If method = readFormField and newValue not set, apply default behaviour --->
	
	<cfif a.method eq "readFormField" and not isDefined("caller.newValue")>
	
		<cfif isDefined("form.#stPD.name#")>
		
			<cfset "caller.caller.#a.r_newValue#" = form[stPD.name]>
		
		<cfelse>
		
			<cfset "caller.caller.#a.r_newValue#" = "">
		
		</cfif>
	
	</cfif>

</cfif>