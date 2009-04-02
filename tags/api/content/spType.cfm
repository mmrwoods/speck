<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!---

Description:

	Called by content type's handler script to build type definition structure or check that method being invoked exists.  
	Tag also checks to see if database table/columns exist and creates table and columns as required.  For this reason
	the codb datasource should have table create permissions enabled during development (not in production of course).

Usage:
	
	<handler script
		method = "spTypeDefinition|method name"
		r_stType = "variable name"
		qContent=#query#
		type="string"
		separator="string"
		columns=number
		updateContent="yes|no">
	
		<cf_spType
			name = "type name"
			description = "Short sentance describing type"
			keywordFilter = "keyword prefix 1, keyword prefix 2, ..., keyword prefix N"
			revisioned = "yes|no"
			context = "structure"
			keywordsRequired = "yes|no"
			labelRequired = "yes|no"
			extends = "parent type name">
			
			<cf_spProperty
				...>
				
			<cf_spHandler
				...>
				
		</cf_spType>
	
Attributes:	
	
	handler script:
	
		method(string, optional):		Default "spTypeDefinition".  If spTypeDefinition, return type structure in variable r_stType.  
										Otherwise invoke handler with matching method if it exists.
		r_stType(string, optional):		Default "stType".  Name of variable to return type structure in for method = "spTypeDefinition".
										Stucture contains:
		
											key for each type attribute.
											props[1..n] array of property structures in order of definition, each containing property attribute keys.
											
		context(structure, optional):	Default to request.speck.  Only used when spApp calls handler, as request scope not set up at that point.										methods stucture containing a key for each defined method.
	
	cf_spType:
								
		name(string, required):				Type name, should match handler directory name.
		description(string, optional):		Default "".
		keywordFilter(list, optional):  	Default "".  Restrict keywords assigned to content items of this type to those beginning with one of the listed prefixes.
		revisioned(boolean, optional):		Default yes.  Do not create new revisions of this type when revisioning is enabled.  "No" used for content types that
											sit outside the revisioning/promotion process (e.g. the "Change" type).
		keywordsRequired(boolean,optional):	Default no. Require keywords for each instance of this content type.
		labelRequired(boolean,optional):	Default no. Require lebel for each instance of this content type.
		extends(string,optional):			Default "". Name of parent content type. Currently, type inheritance is only supported for application content types 
											extending server content types. The parent name given as the extends attribute must exactly match a server or speck 
											content type. Future versions of Speck are expected to support type inheritance using "speck" or an application name 
											as a qualifier for the name of the parent type, allowing types to extend other types in their own and other applications. 
											Obviously, this brings with it some serious security concerns that have to be addressed first.  
		final(boolean,optional):			Default no. Prevent this type from being inherited by other types

--->

<cfset a = attributes>
<cfset ca = caller.attributes>

<cfif thisTag.ExecutionMode eq "START">

	<!--- get context --->
	<cfif not isDefined("ca.context")>
	
		<cfset ca.context = request.speck>
	
	</cfif>

	<!--- Validate type name --->
	<cfif not isDefined("a.name")>
	
		<cf_spError error="ATTR_REQ" lParams="name" context=#ca.context#>	<!--- Missing attribute --->
		
	<cfelseif len(trim(a.name)) gt 50>
	
		<cf_spError error="ATTR_INV" lParams="#a.name#,name" context=#ca.context#>
	
	</cfif>
	
	<!--- Validate other attributes --->
	<cfif not isDefined("ca.refresh")>
	
		<cfset ca.refresh = "no">
	
	</cfif>
	
	<cfparam name="ca.method" default="spTypeDefinition">
	<cfparam name="ca.r_stType" default="stType">
	<cfparam name="a.description" default="#a.name#">
	<cfparam name="a.keywordFilter" default="">
	<cfparam name="a.revisioned" default="yes">
	<cfparam name="a.keywordsRequired" default="no">
	<cfparam name="a.labelRequired" default="no">
	
	<cfparam name="a.extends" default=""> <!---parent type to extend (note: ONLY USE THIS ATTRIBUTE FOR APPLICATION TYPES) --->
	<cfparam name="a.final" default="no"> <!--- prevent type from being extended? --->
	<cfparam name="a.public" default="no"> <!--- type can be extended by other types outside this application? - NOT IMPLEMENTED --->
	
	<cfparam name="a.caption" default="#a.description#"> <!--- use for admin links, document titles etc. --->
	
	<cfset a.method = ca.method> <!--- Make this visible to child tags --->
	
	<cfif a.method eq "spTypeDefinition" and not ca.refresh>

		<cflock scope="APPLICATION" type="READONLY" timeout="3">
	
		<cfif isDefined("application.speck.types.#a.name#")>
		
			<!--- Return structure --->
			<cfset "caller.caller.#caller.attributes.r_stType#" = application.speck.types[a.name]>
			<cfexit method="EXITTAG">
		
		</cfif>
		
		</cflock>
		
	</cfif>

<cfelse>

	<cfif a.method eq "spTypeDefinition">
	
		<cfscript>
		
			// Add array of property attributes to type structure
			if (isDefined("thisTag.props"))
				a.props = thisTag.props;
			
			// Add methods and roles structures
			a.methods = structNew();
			
			// default handler template for this type
			fs = ca.context.fs;
			if ( fileExists("#ca.context.appInstallRoot##fs#tags#fs#types#fs##a.name#.cfm") )
				handlerTemplate = "/" & ca.context.mapping & "/types/" & a.name & ".cfm";
			else
				handlerTemplate = "/speck/types/" & a.name & ".cfm";
			
			if ( isDefined("thisTag.methods") ) {
				for(i=1; i le arrayLen(thisTag.methods); i = i + 1)
					structInsert(a.methods, thisTag.methods[i].method, handlerTemplate);
				structDelete(a, "method");
			}
			
			// create access structure to store access control information
			a.access = structNew();
			
		</cfscript>
		
		
		<cfif len(trim(a.extends)) and listValueCountNoCase(getBaseTagList(),"CF_SPTYPE") lte 2> <!--- avoid infinite recursive calls to spType if someone mistakenly sets a server type to extend itself --->
		
			<!--- this type extends a server/default type --->
			<!--- note: cf_spType attributes are not inherited from extended type --->
			
			<cftry>
			
				<cfmodule template="/speck/types/#a.extends#.cfm" 
						r_stType="stExtendedType"
						context=#ca.context#
						refresh=#ca.refresh#>
				
			<cfcatch type="missingInclude">
				
				<cf_spError error="EXTENDED_TYPE_NOT_FOUND" lParams="#a.name#,#a.extends#" context=#ca.context#>
				
			</cfcatch>
			</cftry>
			
			<cfif stExtendedType.final>
		
				<cf_spError error="EXTENDED_TYPE_FINAL" lParams="#a.name#,#a.extends#" context=#ca.context#>
		
			</cfif>
			
			<cfscript>
				// inherit methods (note: local methods override those in extended type)
				lLocalMethods = structKeyList(a.methods);
				for(method in stExtendedType.methods) {

					if ( not listFindNoCase(lLocalMethods,method) ) 
						structInsert(a.methods, method, "/speck/types/" & a.extends & ".cfm");

				}
			
				// inherit properties (local properties override those in extended type)
				
				if ( isDefined("stExtendedType.props") ) {
					
					if ( isDefined("a.props") ) {
						
						// we have some local props in addition to the props in the extended type
						// we'll build a new props array made up of those in the extended and local type
						aProps = arrayNew(1);
						
						// get list of local property names
						lLocalProperties = "";
						for(i=1; i le arrayLen(a.props); i = i + 1) 	
							lLocalProperties = listAppend(lLocalProperties, a.props[i].name);
							
						lOverriddenProperties = ""; //list of local property names which override properties in the extended type
						
						// loop over the props in the extended types
						for(i=1; i le arrayLen(stExtendedType.props); i = i + 1) {
							
							// check if this property in the extended type is found in the local props array
							localPropFoundAt = listFindNoCase(lLocalProperties,stExtendedType.props[i].name);
							
							if ( localPropFoundAt neq 0 ) {
								// local property overrides property in extended type
								arrayAppend(aProps,duplicate(a.props[localPropFoundAt]));
								// add this to the list of local props which override those in the extended type
								lOverriddenProperties = listAppend(lOverriddenProperties, a.props[localPropFoundAt].name);
							} else {
								// property is inherited as is from extended type
								arrayAppend(aProps,duplicate(stExtendedType.props[i]));
								// set inherited value to true
								aProps[i].inherited = "yes";
							}
							
						}
						
						// loop over the props in the local type
						for(i=1; i le arrayLen(a.props); i = i + 1) {
							
							if ( not listFindNoCase(lOverriddenProperties,a.props[i].name) ) {
								arrayAppend(aProps,duplicate(a.props[i]));
							}
							
						}
						
						// and finally, copy the new props array back 
						a.props = duplicate(aProps);
					
					} else {
					
						// no local properties, just use the extended props
						a.props = duplicate(stExtendedType.props);
						
					}

				}
			</cfscript>
			
		</cfif>

		<!--- Check to see that the table for the type exists, create it if necessary --->
		<cfif not isDefined("a.props")>
		
			<!--- No properties -> nothing to put in database, so bail out --->
			<cfset "caller.caller.#caller.attributes.r_stType#" = a>
			<cfexit method="EXITTAG">
			
		<cfelse>
		
			<!--- check property names are not duplicated... --->
			<cfset lPropNames = "">
			<cfloop from="1" to="#arrayLen(a.props)#" index="i">
				
				<cfif listFindNoCase(lPropNames,a.props[i].name)>
				
					<!--- call spError --->
					<cf_spError error="DUPLICATE_PROPERTY" lParams="#a.name#,#a.props[i].name#" context=#ca.context#>
					
				<cfelse>
				
					<cfset lPropNames = listAppend(lPropNames,a.props[i].name)>
				
				</cfif>
				
			</cfloop>
		
		</cfif>
		
		<cfset bCreateTable=false>
		
		<cftry>
		
			<cfquery name="qTableCheck" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
			
				SELECT * FROM #ca.context.dbIdentifier(a.name,ca.context)#
				WHERE spId='noSuchId'
			
			</cfquery>
		
		<cfcatch type="Any">
		
			<cfif cfcatch.sqlstate eq "S0002" or ca.context.dbTableNotFound(cfcatch.detail,ca.context)> <!--- ODBC Error base table does not exist --->
			
				<cfset bCreateTable=true>
				
			<cfelse>
			
				<cfrethrow>
			
			</cfif>
		
		</cfcatch>
		</cftry>
		
		<cfif bCreateTable>
		
			<cf_spError logOnly="true" error="NO_TYPE_TABLE" lParams=#a.name# context=#ca.context#>
			
			<cfquery name="qCreateTable" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
			
				CREATE TABLE #ca.context.dbIdentifier(a.name,ca.context)# (
					spId CHAR (35) NOT NULL ,
					spSequenceId INTEGER NOT NULL ,
					spRevision #ca.context.database.integerDDLString# NOT NULL ,
					spLabel #ca.context.textDDLString(250,ca.context)# ,
					spLabelIndex #ca.context.textDDLString(250,ca.context)# ,
					spCreated #ca.context.database.tsDDLString# NOT NULL ,
					spCreatedby #ca.context.textDDLString(20,ca.context)# ,
					spUpdated #ca.context.database.tsDDLString# ,
					spUpdatedby #ca.context.textDDLString(20,ca.context)# ,
					spKeywords #ca.context.textDDLString(ca.context.database.maxIndexKeyLength,ca.context)# ,
					PRIMARY KEY (spId,spRevision)
				)
				
			</cfquery>
			
			<cfquery name="qInsert" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
				INSERT INTO spSequences (contentType, sequenceId) VALUES ('#uCase(a.name)#',0)
			</cfquery>
			
			<cftry>
			
				<cfquery name="qAddIndex" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
				
					CREATE INDEX #a.name#_spLabel
					ON #ca.context.dbIdentifier(a.name,ca.context)# (spLabelIndex)
					
				</cfquery>
			
			<cfcatch type="Database">
				<cflog type="warning" 
					file="#ca.context.appName#" 
					application="no"
					text="CF_SPTYPE: Could not create database index #a.name#_spLabel. Error: #cfcatch.message# #cfcatch.detail#">
			</cfcatch>
			</cftry>
			
			<cftry>
			
				<cfquery name="qAddIndex" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
				
					CREATE INDEX #a.name#_spKeywords
					ON #ca.context.dbIdentifier(a.name,ca.context)# (spKeywords)
					
				</cfquery>
			
			<cfcatch type="Database">
				<cflog type="warning" 
					file="#ca.context.appName#" 
					application="no"
					text="CF_SPTYPE: Could not create database index #a.name#_spKeywords. Error: #cfcatch.message# #cfcatch.detail#">
			</cfcatch>
			</cftry>			
			
		<cfelse>
		
			<!--- ############# temporary code to add spLabelIndex column to existing tables ################### --->
			<cfif not listFindNoCase(qTableCheck.columnList, "spLabelIndex")>
				<cfquery name="qCreateColumn" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
					ALTER TABLE #ca.context.dbIdentifier(a.name,ca.context)# ADD spLabelIndex #ca.context.textDDLString(250,ca.context)#
				</cfquery>
				<!--- populate the spLabelIndex with the upper case version of the real label --->
				<cfquery name="qUpdateColumn" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
					UPDATE #ca.context.dbIdentifier(a.name,ca.context)#
					SET spLabelIndex = <cfif ca.context.dbtype eq "access">spLabel<cfelse>UPPER(spLabel)</cfif>
				</cfquery>
				<!--- drop the existing index on the mixed case label and create an index on the upper case version --->
				<cftry>
					<cfquery name="qDropIndex" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
						DROP INDEX #a.name#_spLabel
					</cfquery>
					<cftry>
						<cfquery name="qAddIndex" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
							CREATE INDEX #a.name#_spLabel
							ON #ca.context.dbIdentifier(a.name,ca.context)# (spLabelIndex)
						</cfquery>
					<cfcatch type="Database">
						<cflog type="warning" 
							file="#ca.context.appName#" 
							application="no"
							text="CF_SPTYPE: Could not create database index #a.name#_spLabel. Error: #cfcatch.message# #cfcatch.detail#">
					</cfcatch>
					</cftry>
				<cfcatch type="Database">
					<cflog type="warning" 
						file="#ca.context.appName#" 
						application="no"
						text="CF_SPTYPE: Could not drop database index #a.name#_spLabel. Error: #cfcatch.message# #cfcatch.detail#">
				</cfcatch>
				</cftry>
			</cfif>
			<!--- ############# end temp code ############# --->		
			
			
			<!--- ############# temporary code to add spSequenceId column to existing tables ################### --->
			<cfif not listFindNoCase(qTableCheck.columnList, "spSequenceId")>
			
				<cftransaction isolation="serializable">
				
					<cfquery name="qCreateColumn" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
						ALTER TABLE #ca.context.dbIdentifier(a.name,ca.context)# ADD spSequenceId INTEGER
					</cfquery>
					
					<!--- populate the spSequenceId column --->
					<cfquery name="qContent" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
						SELECT DISTINCT spId, spCreated FROM #ca.context.dbIdentifier(a.name,ca.context)# ORDER BY spCreated ASC
					</cfquery>
					
					<cfset sequenceId = 0>
					
					<cfloop query="qContent">
					
						<cfset sequenceId = sequenceId + 1>
						<cfquery name="qUpdate" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
								UPDATE #ca.context.dbIdentifier(a.name,ca.context)# SET spSequenceId = #sequenceId# WHERE spId = '#spId#'
						</cfquery>
						
					</cfloop>
					
					<!--- check for content type in spsequences table --->
					<cfquery name="qCheckExists" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
						SELECT * FROM spSequences WHERE contentType = '#uCase(a.name)#'
					</cfquery>
					
					<cfif qCheckExists.recordCount>
						
						<cfquery name="qUpdate" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
							UPDATE spSequences 
							SET sequenceId = #sequenceId#
							WHERE contentType = '#uCase(a.name)#'
						</cfquery>
					
					<cfelse>
					
						<cfquery name="qInsert" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
							INSERT INTO spSequences (contentType, sequenceId) VALUES ('#uCase(a.name)#',#sequenceId#)
						</cfquery>
					
					</cfif>
				
				</cftransaction>
				
			</cfif>
			<!--- ############# end temp code ############# --->	
			
		</cfif>
		
		<cfquery name="qTableCheck" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
		
			SELECT * FROM #ca.context.dbIdentifier(a.name,ca.context)#
			WHERE spId='noSuchId'
		
		</cfquery>
		
		<!--- Compare columns in table with properties, create missing columns --->
		<cfloop from=1 to=#arrayLen(a.props)# index="propIndex">
		
			<cfset prop=a.props[propIndex]>
			
			<cfif prop.saveToDatabase and not listFindNoCase(qTableCheck.columnList, prop.name)>
				
				<!--- Create column this code very brittle dep on database type! --->
				<cf_spError logOnly="true" error="NO_COLUMN" lParams="#a.name#,#prop.name#" context=#ca.context#>
				
				<!--- DDL string for column type --->
				<cfswitch expression=#prop.databaseColumnType#>
				
					<cfcase value="TEXT">
						<cfset propDDLString = ca.context.textDDLString(prop.maxLength,ca.context)>
					</cfcase>
					
					<cfcase value="DATETIME">
						<cfset propDDLString = ca.context.database.tsDDLString>
					</cfcase>		
					
					<cfcase value="FLOAT">
						<cfset propDDLString = ca.context.database.floatDDLString>
					</cfcase>
					
					<cfcase value="INTEGER">
						<cfset propDDLString = ca.context.database.integerDDLString>
					</cfcase>										
					
					<cfdefaultcase>
						<cfset propDDLString = prop.databaseColumnType>
					</cfdefaultcase>
				
				</cfswitch>
				
				<cfquery name="qCreateColumn" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
				
						ALTER TABLE #ca.context.dbIdentifier(a.name,ca.context)# ADD #ca.context.dbIdentifier(prop.name,ca.context)# #propDDLString#

				</cfquery>
				
				<cfif prop.index>
				
					<cftry>
					
						<cfquery name="qAddIndex" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
				
							CREATE INDEX #a.name#_#prop.name#
							ON #ca.context.dbIdentifier(a.name,ca.context)# (#prop.name#<cfif ca.context.dbtype eq "mysql" and prop.maxLength gt 255>(255)</cfif>)
						
						</cfquery>
					
					<cfcatch type="Database">
						<cflog type="warning" 
							file="#ca.context.appName#" 
							application="no"
							text="CF_SPTYPE: Could not create database index #a.name#_spLabel. Error: #cfcatch.message# #cfcatch.detail#">
					</cfcatch>
					</cftry>
					
				</cfif>
			
			</cfif>
		
		</cfloop>
		
		<!--- add a flag to the type definition to say whether it contains revisions at the moment - if revisioning disabled, spContentGet can use this info to improve query performance --->
		<cfquery name="qRevisionsCheck" datasource=#ca.context.codb# username=#ca.context.database.username# password=#ca.context.database.password#>
			SELECT MAX(spRevision) AS maxRevision FROM #ca.context.dbIdentifier(a.name,ca.context)#
		</cfquery>
		
		<cfif isNumeric(qRevisionsCheck.maxRevision) and qRevisionsCheck.maxRevision gt 1>
			<cfset a.containsRevisions = true>
		<cfelse>
			<cfset a.containsRevisions = false>
		</cfif>
		
		<!--- Return structure --->
		<cfset "caller.caller.#caller.attributes.r_stType#" = a>
			
	</cfif>
	
</cfif>