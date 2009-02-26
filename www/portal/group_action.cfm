<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfif cgi.request_method eq "post">
	
	<!--- form posted --->
	
	<cfif len(url.groupname)>
	
	
		<!--- check that at least one group will still have spSuper role after this update... --->
		<cfif not listFindNoCase(form.roles,"spSuper")>
		
			<!--- current group will not be spSuper after update, check that at least one other group will --->
			<cfquery name="qSuperGroups" datasource="#request.speck.codb#">
				SELECT accessor 
				FROM spRolesAccessors 
				WHERE rolename = 'spSuper'
					AND accessor <> '#url.groupname#'
			</cfquery>
			
			<cfif not qSuperGroups.recordCount>
			
				<cfset void = actionError("The group will not have spSuper role after this update. Update cannot proceed because this is the only group that currently has spSuper role and at least one group must have spSuper role.")>
			
			</cfif>
		
		</cfif>
		
		<cfif not isDefined("actionErrors")>
	
			<!--- update group --->
			<cfquery name="qUpdate" datasource="#request.speck.codb#">
	
				UPDATE spGroups
				SET description = <cfif len(form.description)>'#form.description#'<cfelse>NULL</cfif>
				WHERE groupname = '#url.groupname#'
			
			</cfquery>
			
			<!--- delete existing role relationships --->
			<cfquery name="qDelete" datasource="#request.speck.codb#">
			
				DELETE FROM spRolesAccessors WHERE accessor = '#url.groupname#'
			
			</cfquery>	
			
			<!--- now insert all role relationships --->
			<cfloop list="#form.roles#" index="role">
			
				<cfquery name="qInsert" datasource="#request.speck.codb#">
				
					INSERT INTO spRolesAccessors (rolename, accessor) VALUES ('#role#', '#url.groupname#')
				
				</cfquery>
			
			</cfloop>
			
			<cfset message = "Group '#url.groupname#' updated">
	
			<cflocation url="action_response.cfm?app=#url.app#&message=#urlEncodedFormat(message)#&location=#urlEncodedFormat(form.referrer)#" addToken="no">

		</cfif>
		
		
	<cfelse>
	
	
		<!--- validate groupname --->
		<cfif not len(form.groupname)>
		
			<cfset void = actionError("Group name is a required field.")>
			
		<cfelseif not REFind("^[A-Za-z0-9][A-Za-z0-9_]+$",form.groupname)>
				
			<cfset void = actionError("Group name format invalid. Group name must start with a letter and may only contain letters, numbers and underscore characters.")>
			
		</cfif>
		
		<cfif not isDefined("actionErrors")>
		
			<!--- check that new groupname is not already in use before inserting --->

			<cfquery name="qCheckGroup" datasource="#request.speck.codb#">
				SELECT groupname 
				FROM spGroups 
				WHERE UPPER(groupname) = '#uCase(form.groupname)#'
			</cfquery>
			
			<cfif qCheckGroup.recordCount>
			
				<cfset void = actionError("Group name '#form.groupname#' is already in use, please choose another name.")>
			
			</cfif>
			
		</cfif>
		
		<cfif not isDefined("actionErrors")>
			
			<!--- insert user --->
			<cfquery name="qInsert" datasource="#request.speck.codb#">

				INSERT INTO spGroups (
					groupname, 
					description
				) 
				VALUES (
					'#form.groupname#',
					<cfif len(form.description)>'#form.description#'<cfelse>NULL</cfif>
				)
			
			</cfquery>
			
			<!--- now insert all role relationships --->
			<cfloop list="#form.roles#" index="role">
			
				<cfquery name="qInsert" datasource="#request.speck.codb#">
				
					INSERT INTO spRolesAccessors (rolename, accessor) VALUES ('#role#', '#form.groupname#')
				
				</cfquery>
			
			</cfloop>
			
			<cfset message = "Group '#form.groupname#' added">

			<cflocation url="action_response.cfm?app=#url.app#&message=#urlEncodedFormat(message)#&location=#urlEncodedFormat(form.referrer)#" addToken="no">
		
		</cfif>
		
			
	</cfif>

</cfif>