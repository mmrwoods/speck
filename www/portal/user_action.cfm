<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfif cgi.request_method eq "post">
	
	<!--- form posted --->
	<cfif len(form.groups_expiration)>
		<cfset stGroupsExpiration = json.decode(form.groups_expiration)>
	<cfelse>
		<cfset stGroupsExpiration = structNew()> 
	</cfif>

	<!--- <cfif not isStruct(stGroupsExpiration)>
		<cfset stGroupsExpiration = structNew()> 
	</cfif> --->

	<cfscript>
		function parseISODateString(str) {
			// note: no validation
			return createDate(listGetAt(str,1,"-"),listGetAt(str,2,"-"),listGetAt(str,3,"-"));
		}
	</cfscript>
	
	<cfif len(url.username)>
	
		<!--- updating an existing user, start with the existing content --->
		<cfscript>
		/**
		 * Makes a row of a query into a structure.
		 * 
		 * @param query 	 The query to work with. 
		 * @param row 	 Row number to check. Defaults to row 1. 
		 * @return Returns a structure. 
		 * @author Nathan Dintenfass (nathan@changemedia.com) 
		 * @version 1, December 11, 2001 
		 */
		function queryRowToStruct(query){
			//by default, do this to the first row of the query
			var row = 1;
			//a var for looping
			var ii = 1;
			//the cols to loop over
			var cols = listToArray(query.columnList);
			//the struct to return
			var stReturn = structnew();
			//if there is a second argument, use that for the row number
			if(arrayLen(arguments) GT 1)
				row = arguments[2];
			//loop over the cols and build the struct from the query row
			for(ii = 1; ii lte arraylen(cols); ii = ii + 1){
				stReturn[cols[ii]] = query[cols[ii]][row];
			}		
			//return the struct
			return stReturn;
		}
		</cfscript>
		
		<cfset stContent = queryRowToStruct(qUser)>
	
	<cfelse>
	
		<!--- new user --->
		<cfset stContent = structNew()>
		<cfset stContent.spId = createUUID()>
	
	
	</cfif>
	
	<!--- validate standard spUsers properties --->
	<cfif not len(form.username)>
	
		<cfset void = actionError("Username is a required field.")>
	
	</cfif>
	
	<cfif not len(form.fullname)>
	
		<cfset void = actionError("Full name is a required field.")>
	
	</cfif>
	
	<cfif not len(form.password)>
	
		<cfset void = actionError("Password is a required field.")>
	
	</cfif>
	
	<cfif not isDefined("actionErrors")>
	
		<!--- no errors with required fields, validate values --->

		<cfif len(url.username) and compare(form.password,form.password_confirm) neq 0> <!--- note: no need to confirm the password when adding a user - password text is not hidden and user will normally be emailed the username and password --->
		
			<cfset void = actionError("Password and confirm password fields do not match.")>
		
		</cfif>
		
		<cfif len(form.email)>
			
			<!--- validate email address and check unique --->
			
			<cfif not REFind("^([a-zA-Z0-9][-a-zA-Z0-9_%\.']*)?[a-zA-Z0-9]@[a-zA-Z0-9][-a-zA-Z0-9%\>.]*\.[a-zA-Z]{2,}$",form.email)>
			
				<cfset void = actionError("Email address '#form.email#' does not appear to be a valid email address.")>
	
			<cfelse>
			
				<cfquery name="qCheckEmail" datasource="#request.speck.codb#">
					SELECT * 
					FROM spUsers 
					WHERE UPPER(email) = '#uCase(form.email)#'
						AND spId <> '#stContent.spId#'
				</cfquery>
				
				<cfif qCheckEmail.recordCount>
				
					<cfset void = actionError("Email address '#form.email#' has already been assigned to user '#qCheckEmail.username#'. Email addresses must be unique.")>
				
				</cfif>
			
			</cfif>
			
		<cfelseif isDefined("form.send_password") and form.send_password>
		
			<cfset void = actionError("Send password is set to 'yes', but email address is blank.")>
			
		</cfif>
		
		<cfif len(form.expires) and form.expires neq "YYYY-MM-DD">
		
			<cfif not reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",form.expires)>
			
				<cfset void = actionError("Expiration date '#form.expires#' is not in the correct format. Please make sure the date is in YYYY-MM-DD format.")>
				
			<cfelse>
			
				<cfset void = setLocale("English (US)")>
				<cfif not isDate("#listGetAt(form.expires,2,"-")#/#listLast(form.expires,"-")#/#listFirst(form.expires,"-")#")>
			
					<cfset void = actionError("Expiration date '#form.expires#' is not a valid date.")>

				</cfif>
				<cfset void = setLocale(request.speck.locale)>
				
			</cfif>
		
		</cfif>
		
	</cfif>

	<!--- read and validate any extended spUsers properties --->
	<cfloop from=1 to="#arrayLen(stType.props)#" index="i">
	
		<cfif not listFindNoCase(lSystemProperties,stType.props[i].name)>
			
			<cfset stPD = duplicate(stType.props[i])>
			<cfset stPD.required = false>
			
			<cfif isDefined("form.#stPD.name#") and stPD.type neq "Asset">
			
				<cfset value = evaluate("form.#stPD.name#")>
			
			<cfelse>
				
				<cfset value = form[stPD.name]>
				
			</cfif>
			
			<cfmodule template=#request.speck.getPropertyHandlerTemplate(stPD,"readFormField")#
				method="readFormField"
				stPD=#stPD#
				id=#stContent.spId#
				revision=1
				value=#value#
				r_newValue="stContent.#stPD.name#">
			
			<cfmodule template=#request.speck.getPropertyHandlerTemplate(stPD,"validateValue")#
				method="validateValue"
				stPD=#stPD#
				id=#stContent.spId#
				revision=1
				value=#value#
				newValue=#stContent[stPD.name]#
				r_lErrors ="lPropertyErrors">
			
			<cfif len(lPropertyErrors)>
			
				<!--- add property validation errors to action errors array --->
			
				<cfloop list="#lPropertyErrors#" index="err">
					
					<cfset void = actionError(err)>
				
				</cfloop>
				
			</cfif>
			
		</cfif>
		
	</cfloop>
	
	<cfif not isDefined("actionErrors")>
	
		<!--- still no errors... let's update/insert --->
		
		<!--- ########## temporary code, remove once all apps have been refreshed ########## --->
		
		<!--- disgusting hack to ensure we never have an error due to missing registered or suspended columns --->
		<cfquery name="qCheckColumns" datasource="#request.speck.codb#">
			SELECT * 
			FROM spUsers 
			WHERE spId = 'noSuchId'
		</cfquery>
		
		<cfif not listFindNoCase(qCheckColumns.columnList,"salt")>
	
			<cfquery name="qAlterUsers" datasource="#request.speck.codb#">
				ALTER TABLE spUsers ADD salt #request.speck.textDDLString(50)#
			</cfquery>
			
		</cfif>
		
		<cfif not listFindNoCase(qCheckColumns.columnList,"registered")>

			<cfquery name="qAlterUsers" datasource="#request.speck.codb#">
				ALTER TABLE spUsers ADD registered #request.speck.database.tsDDLString#
			</cfquery>
			
			<cfquery name="qUpdateUsers" datasource="#request.speck.codb#">
				UPDATE spUsers SET registered = spCreated
			</cfquery>
		
		</cfif>
		
		<cfif not listFindNoCase(qCheckColumns.columnList,"suspended")>

			<cfquery name="qAlterUsers" datasource="#request.speck.codb#">
				ALTER TABLE spUsers ADD suspended #request.speck.database.tsDDLString#
			</cfquery>
			
		</cfif>
		
		<cfif not listFindNoCase(qCheckColumns.columnList,"expires")>

			<cfquery name="qAlterUsers" datasource="#request.speck.codb#">
				ALTER TABLE spUsers ADD expires #request.speck.database.tsDDLString#
			</cfquery>
			
		</cfif>
		
		<cfif not listFindNoCase(qCheckColumns.columnList,"newsletter")>

			<cfquery name="qAlterUsers" datasource="#request.speck.codb#">
				ALTER TABLE spUsers ADD newsletter #request.speck.database.integerDDLString#
			</cfquery>
			
		</cfif>
		
		<!--- ########## end temporary code ########## --->
		
		<cfif len(url.username)>

			<!--- 
			One last thing...
			if we're updating, we need to make sure that after the update there will still be at 
			least one user with spSuper role, otherwise, all users will be locked out of portal admin	  
			--->
			<!--- first get the groups with spSuper role... --->
			<cfquery name="qSuperGroups" datasource="#request.speck.codb#">
				SELECT accessor FROM spRolesAccessors WHERE rolename = 'spSuper'
			</cfquery>
			<!--- now check if posted groups contain at least one group with spSuper role --->
			<cfscript>
				bSuper = false; // set to true if current user has super role
				lSuperGroups = valueList(qSuperGroups.accessor);
				while (lSuperGroups neq "" and not bSuper) {
					group = listFirst(lSuperGroups); 
					lSuperGroups = listRest(lSuperGroups);
					if ( listFindNoCase(form.groups,group) ) {
						bSuper = true;
						break;
					}
				}
			</cfscript>
			
			<cfif not bSuper>
			
				<!--- this user will not have spSuper role after this update, check that at least one other user does before proceeding with the update --->
				<cfquery name="qSuperUsers" datasource="#request.speck.codb#">
					SELECT username 
					FROM spUsersGroups 
					WHERE groupname IN (#quotedValueList(qSuperGroups.accessor)#)
						AND username <> '#url.username#'
				</cfquery>
				<cfif not qSuperUsers.recordCount>
				
					<!--- there will be no super users after this update, barf! --->
					<cfset void = actionError("The user will not be a member of a group with spSuper role after this update. Update cannot proceed because this is the only user that currently has spSuper role and at least one user must have spSuper role.")>
					
				</cfif>
				
			</cfif>
		
			<cfif not isDefined("actionErrors")> <!--- really - is it finally ok to go ahead? --->
			
				<!--- update user --->
				
				<cfscript>
					stContent.fullname = form.fullname;
					if ( form.password neq left(qUser.password,20) ) {
						if ( len(request.speck.portal.passwordEncryption) ) {
							stContent.salt = makePassword();
							stContent.password = evaluate("#request.speck.portal.passwordEncryption#(form.password & stContent.salt)");
						} else {
							stContent.password = form.password;
						}
					}
					stContent.email = form.email;
					stContent.notes = form.notes;
					stContent.newsletter = form.newsletter;
					stContent.spKeywords = "";
					stContent.spLabel = "";
				</cfscript>
				
				<cf_spContentPut stContent=#stContent# type="spUsers">
				
				<cfif structKeyExists(stContent,"salt")>

					<cfquery name="qUpdate" datasource="#request.speck.codb#">
						UPDATE spUsers 
						SET salt = '#stContent.salt#'
						WHERE username = '#stContent.username#'
					</cfquery>
				
				</cfif>
				
				<cfif structKeyExists(stContent,"suspended")>
				
					<cfif form.suspended and not isDate(stContent.suspended)>
					
						<!--- set suspended to current date --->
						<cfquery name="qUpdate" datasource="#request.speck.codb#">
							UPDATE spUsers 
							SET suspended = #createODBCDateTime(now())#
							WHERE username = '#stContent.username#'
						</cfquery>
						
					<cfelseif not form.suspended and isDate(stContent.suspended)>
					
						<!--- set suspended to null --->
						<cfquery name="qUpdate" datasource="#request.speck.codb#">
							UPDATE spUsers 
							SET suspended = NULL
							WHERE username = '#stContent.username#'
						</cfquery>
						
					</cfif>
				
				</cfif>
				
				<cfif structKeyExists(stContent,"expires")>

					<cfquery name="qUpdate" datasource="#request.speck.codb#">
						UPDATE spUsers 
						SET expires = <cfif len(form.expires) and form.expires neq "YYYY-MM-DD">#createODBCDate(parseISODateString(form.expires))#<cfelse>NULL</cfif>
						WHERE username = '#stContent.username#'
					</cfquery>
				
				</cfif>
				
				<!--- delete existing group relationships --->
				<cfquery name="qDelete" datasource="#request.speck.codb#">
					DELETE FROM spUsersGroups 
					WHERE username = '#url.username#' 
					<cfif len(form.groups)>
						AND groupname NOT IN (#listQualify(form.groups,"'")#)
					</cfif>
				</cfquery>	
				
				<!--- now insert all group relationships --->
				<cfloop list="#form.groups#" index="group">
				
					<cftry>
					
						<cfquery name="qInsert" datasource="#request.speck.codb#">
							INSERT INTO spUsersGroups (groupname, username, expires) 
							VALUES ('#group#', '#url.username#', <cfif structKeyExists(stGroupsExpiration,group) and reFind("^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$",stGroupsExpiration[group])>#createODBCDate(parseISODateString(stGroupsExpiration[group]))#<cfelse>NULL</cfif>)
						</cfquery>
					
					<cfcatch>
						
						<cftry>
						
						<cfquery name="qUpdate" datasource="#request.speck.codb#">
							UPDATE spUsersGroups 
							SET expires = <cfif structKeyExists(stGroupsExpiration,group) and reFind("^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$",stGroupsExpiration[group])>#createODBCDate(parseISODateString(stGroupsExpiration[group]))#<cfelse>NULL</cfif>
							WHERE groupname = '#group#' AND username = '#url.username#'
						</cfquery>
						
						<cfcatch>
							
							<cfdump var="#stGroupsExpiration#">
							<cfoutput>#structKeyExists(stGroupsExpiration,group)#</cfoutput>
							<cfabort>
						
						</cfcatch>
						</cftry>
						
					</cfcatch>
					</cftry>
				
				</cfloop>
				
				<cfset message = "User '#url.username#' updated">
				
				<cfif isDefined("url.return_to") and len(url.return_to)>
				
					<cflocation url="action_response.cfm?app=#url.app#&message=#urlEncodedFormat(message)#&location=#urlEncodedFormat(url.return_to)#" addToken="no">
					
				</cfif>
			
			</cfif>
		
		<cfelse>
		
			<!--- check that new username is valid and not already in use before inserting --->
			
			<cfif not REFind("^[A-Za-z0-9_]+$",form.username)>
			
				<cfset void = actionError("Username format invalid. Username must start with a letter and may only contain letters, numbers and underscore characters.")>
			
			<cfelse>
			
				<cfloop list="#structKeyList(application.speck.securityZones)#" index="securityZone">
					
					<cfset stUser = structNew()> <!--- spUserGet doesn't return anything if user not found, which is a pain --->
				
					<cf_spUserGet user="#form.username#" securityZone="#securityZone#" r_stUser="stUser">
						
					<cfif not structIsEmpty(stUser)>
					
						<cfset void = actionError("Username '#form.username#' is already in use, please choose another username.")>
						
						<cfbreak>
					
					</cfif>
				
				</cfloop>
				
			</cfif>
			
			<cfif not isDefined("actionErrors")>		
			
				<!--- insert user --->
				
				<cfscript>
					stContent.username = lCase(form.username);
					stContent.fullname = form.fullname;
					if ( len(request.speck.portal.passwordEncryption) ) {
						stContent.salt = makePassword();
						stContent.password = evaluate("#request.speck.portal.passwordEncryption#(form.password & stContent.salt)");
					} else {
						stContent.password = form.password;
					}
					stContent.email = form.email;
					stContent.notes = form.notes;
					stContent.newsletter = form.newsletter;
				</cfscript>
				
				<!--- insert user --->
				<cf_spContentPut stContent=#stContent# type="spUsers">
				
				<!--- update registered date (registered is not a speck property - 'cos we don't want it to ever be modified) --->
				<cfquery name="qUpdate" datasource="#request.speck.codb#">
					UPDATE spUsers 
					SET registered = #createODBCDateTime(now())#
					<cfif structKeyExists(stContent,"salt")>,salt = '#stContent.salt#'</cfif>
					<!--- <cfif form.suspended>,suspended = #createODBCDateTime(now())#</cfif> --->
					WHERE username = '#stContent.username#'
				</cfquery>
				
				<!--- now insert all group relationships --->
				<cfloop list="#form.groups#" index="group">
				
					<cfquery name="qInsert" datasource="#request.speck.codb#">
						INSERT INTO spUsersGroups (groupname, username, expires) 
						VALUES ('#group#', '#stContent.username#',<cfif structKeyExists(stGroupsExpiration,group) and reFind("^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$",stGroupsExpiration[group])>#createODBCDate(parseISODateString(stGroupsExpiration[group]))#<cfelse>NULL</cfif>)
					</cfquery>
				
				</cfloop>
				
				<cfif len(stContent.email) and form.send_password>
				
					<cfset nl = chr(13) & chr(10)>
					<cfset domain = request.speck.portal.domain>
					<cfset mailFrom = "#request.speck.portal.name# <noreply@#domain#>">
					<cfset subject = "Welcome to #request.speck.portal.name#">
					<cfset message = "
						This is a automatically generated email. Please do not reply to this email. If you have any questions, please email info@#domain#.
						
						You have been registered as a user on the #request.speck.portal.name# web site.
						
						To log in, you will need your username and password. Please make a note of these for future reference.
			
						Your username is: #lCase(form.username)#
						Your password is: #form.password#
			
						Thank you and welcome to #request.speck.portal.name#.
					">
					<cfset message = replace(message,chr(9),"","all")>
					<cfset message = replace(message,chr(10),chr(13) & chr(10),"all")>
					<cfmail to="#stContent.email#" from="#mailFrom#" subject="#subject#">#message#</cfmail>
				
				</cfif>
				
				<cfif isDefined("url.return_to") and len(url.return_to)>
				
					<cflocation url="action_response.cfm?app=#url.app#&message=#urlEncodedFormat("User '#form.username#' added")#&location=#urlEncodedFormat(url.return_to)#" addToken="no">
					
				</cfif>

			</cfif>
				
		</cfif>
		
	</cfif>

</cfif>