<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfif cgi.request_method eq "post">
	
	<!--- form posted --->
	
	<cfif len(url.rolename)>
	
		<!--- update group --->
		<cfquery name="qUpdate" datasource="#request.speck.codb#">

			UPDATE spRoles
			SET description = <cfif len(form.description)>'#form.description#'<cfelse>NULL</cfif>
			WHERE rolename = '#url.rolename#'
		
		</cfquery>
		
		<cfset message = "Role '#url.rolename#' updated">

		<cflocation url="action_response.cfm?app=#url.app#&message=#urlEncodedFormat(message)#&location=#urlEncodedFormat(form.referrer)#" addToken="no">


	<cfelse>
	
	
		<!--- validate rolename --->
		<cfif not len(form.rolename)>
		
			<cfset void = actionError("Role name is a required field.")>
			
		<cfelseif not REFind("^[A-Za-z0-9_\.]+$",form.rolename)>
				
			<cfset void = actionError("Role name contains invalid characters. Only letters, numbers, period and underscore are allowed.")>
			
		</cfif>
		
		<cfif not isDefined("actionErrors")>
		
			<!--- check that new rolename is not already in use before inserting --->

			<cfquery name="qCheckRole" datasource="#request.speck.codb#">
				SELECT rolename 
				FROM spRoles 
				WHERE UPPER(rolename) = '#uCase(form.rolename)#'
			</cfquery>
			
			<cfif qCheckRole.recordCount>
			
				<cfset void = actionError("Role name '#form.rolename#' is already in use, please choose another name.")>
			
			</cfif>
			
		</cfif>
		
		<cfif not isDefined("actionErrors")>
			
			<!--- insert user --->
			<cfquery name="qInsert" datasource="#request.speck.codb#">

				INSERT INTO spRoles (
					rolename, 
					description
				) 
				VALUES (
					'#form.rolename#',
					<cfif len(form.description)>'#form.description#'<cfelse>NULL</cfif>
				)
			
			</cfquery>
			
			<cfset message = "Role '#form.rolename#' added">

			<cflocation url="action_response.cfm?app=#url.app#&message=#urlEncodedFormat(message)#&location=#urlEncodedFormat(form.referrer)#" addToken="no">
		
		</cfif>
		
			
	</cfif>

</cfif>