<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!---
Returns structure containing user details.
If user doesn't exist in application's security zones the variable specified in r_stUser is not defined.
--->

<!--- Validate attributes --->
<cfloop list="user,r_stUser" index="attribute">

	<cfif not isdefined("attributes.#attribute#")>
	
		<cf_spError error="ATTR_REQ" lParams="#attribute#">	<!--- Missing attribute --->
		
	</cfif>

</cfloop>

<cfparam name="attributes.securityZone" default=""> <!--- optional attribute, if passed, only return user if found within the specified security zone --->

<!--- nab the security zones from application scope --->
<cflock scope="application" timeout="3" type="READONLY">
<cfset stSecurityZones = duplicate(application.speck.securityZones)>
</cflock>

<cfif len(attributes.securityZone) and structKeyExists(stSecurityZones,attributes.securityZone)>

	<cfset lSecurityZones = attributes.securityZone>
	
<cfelse>

	<cfset lSecurityZones = structKeyList(stSecurityZones)>

</cfif>

<cfset stUser = structNew()> <!--- populate this struct with user details if user is found - only return struct to caller if user found --->

<cfset lUserAttributes = "">

<cfloop list="#lSecurityZones#" index="zone">

	<cflock scope="application" timeout="3" type="READONLY">
	<cfset stSecurityZone = stSecurityZones[zone]>
	</cflock>
	
	<!--- optional encryption setting in user options - if specified, this is the name of function used to encrypt passwords --->
	<cfparam name="stSecurityZone.users.options.encryption" default="">
	<cfset stUser.encryption = stSecurityZone.users.options.encryption>
	
	<cfset stUser.securityZone = zone> <!--- always return the security zone in which the user was found --->

	<cfif stSecurityZone.users.options.source eq "file">
	
		<cfif structKeyExists(stSecurityZone.users.file, attributes.user)>
		
			<!--- Found the user --->
			<cfset lUserAttributes = stSecurityZone.users.file[attributes.user]>
	
			<!--- Format of lUserAttributes is full name, password[, email] --->
			<cfset stUser.user = attributes.user>
			<cfset stUser.fullName = listFirst(lUserAttributes)>
			<cfset stUser.password = listGetAt(lUserAttributes,2)>
			
			<cfif listLen(lUserAttributes) eq 3>
			
				<cfset stUser.email = listLast(lUserAttributes)>
				
			<cfelse>
			
				<cfset stUser.email = "">
			
			</cfif>
		
		</cfif>
		
	<cfelse>
	
		<cfparam name="stSecurityZone.users.database.datasource" default="#request.speck.codb#">
		<cfparam name="stSecurityZone.users.database.username" default="">
		<cfparam name="stSecurityZone.users.database.password" default="">
		<cfparam name="stSecurityZone.users.database.dbtype" default="">
		
		<cfif find("@",attributes.user) and structKeyExists(stSecurityZone.users.database,"emailget")>
		
			<cfset sql = replace(stSecurityZone.users.database.emailget,"%","'#replace(attributes.user,"'","''","all")#'","all")>
		
		<cfelse>
			
			<cfset sql = replace(stSecurityZone.users.database.userget,"%","'#replace(attributes.user,"'","''","all")#'","all")>
		
		</cfif>
		
		<!--- query user database... --->
		<cfif stSecurityZone.users.database.dbtype eq "query">
		
			<!--- check if we need to use a scoped lock when executing the query --->
			<cfset stQueryScope = REFindNoCase("FROM[[:space:]]+((Server|Application|Session)\.)",sql,1,true)>
			
			<cfif arrayLen(stQueryScope.pos) eq 3>
			
				<cfset lockScope = mid(sql,stQueryScope.pos[3],stQueryScope.len[3])>
			
				<cflock type="readonly" scope="#lockScope#" timeout="3">
				<cfquery name="qUserGet" dbtype="query">
				
					#preserveSingleQuotes(sql)#
				
				</cfquery>
				</cflock>
				
			<cfelse>
			
				<cfquery name="qUserGet" dbtype="query">
				
					#preserveSingleQuotes(sql)#
				
				</cfquery>
			
			</cfif>
		
		<cfelse>
		
			<cfquery name="qUserGet" datasource="#stSecurityZone.users.database.datasource#" username="#stSecurityZone.users.database.username#" password="#stSecurityZone.users.database.password#">
			
				#preserveSingleQuotes(sql)#
			
			</cfquery>
		
		</cfif>
		
		<cfif qUserGet.recordCount>
		
			<!--- Found the user --->
			<cfif listFindNoCase(qUserGet.columnList,"user")>
				<cfset stUser.user = trim(qUserGet.user)>
			<cfelse>
				<cfset stUser.user = attributes.user>
			</cfif>
			<cfset stUser.fullName = trim(qUserGet.fullname)>
			<cfset stUser.password = trim(qUserGet.password)>
			
			<!--- email is optional --->
			<cfif listFindNoCase(qUserGet.columnList,"email")>
			
				<cfset stUser.email = trim(qUserGet.email)>
				
			<cfelse>
			
				<cfset stUser.email = "">
			
			</cfif>
			
			<!--- hack: slap any other columns returned in qUserGet into stUser --->
			<cfif listFirst(request.speck.cfVersion) neq 5>
			
				<!--- I don't think this will work with CF 5 --->
				<cfloop list="#qUserGet.columnList#" index="i">
					
					<cfset "stUser.#i#" = qUserGet[i][1]>
					
				</cfloop>
			
			</cfif>
		
		</cfif>	
		
	</cfif>
	
	<!--- 
	Notes RE password matching...
	If encryption enabled but the plain-text password provided matches the password stored in the security zone,
	we'll assume what's happened here is password encryption was enabled at some point and existing passwords 
	have not been encrypted. If we just allowed a match without any further checking, then if someone got hold 
	of the encrypted version of the password, they could log in with the encrypted version. So, we'll assume 
	that the encryption function uses a hashing algorithm, and if the length of the encrypted version of the 
	password is not the same as the length of the plain-text version of the password, we'll allow the match. 
	Hashing algorithms produce a fixed length message digest, so we can reasonably safely assume that if the 
	plain-text password matches what looks like a plain-text password stored in the security zone, but the 
	length of the plain-text password provided and the length of the encrypted version of the plain-text password 
	provided are not the same, then the plain-text password provided was not itself encrypted using the specified 
	encryption function. Of course, this will all goes arseways if the encryption function does not use a hashing
	algorithm and does not produce a fixed-length message digest. Damn, I think I've confused myself at this stage.
	--->

	<cfscript>
		function checkPassword(stUser,password) {
			if ( len(stUser.encryption) ) {
				// encrypted passwords
				if ( structKeyExists(stUser,"salt") and compare(evaluate("#stUser.encryption#(password & stUser.salt)"),stUser.password) eq 0 ) {
					// note: if the salted match fails, the next condition comparing non-salted version will still run, this is intentional to maintain backwards compatibility (though we might get rid of it at some point)
					return true;
				} else if ( compare(evaluate("#stUser.encryption#(password)"),stUser.password) eq 0 ) {
					return true;
				} else if ( compare(password,stUser.password) eq 0 and len(evaluate("#stUser.encryption#(password)")) neq len(password) ) {
					// I know, I know, you're thinking "WTF is this". See notes above RE why we consider this a match
					return true; 
				}
			} else if ( compare(password,stUser.password) eq 0 ) { // plain-text password match
				return true;
			}
			return false;
		}
	</cfscript>
	
	<!--- note: password attribute is optional, if defined, check for password match --->
	<cfif structKeyExists(stUser,"user") and ( not isDefined("attributes.password") or checkPassword(stUser,attributes.password) )>
	
		<!--- get groups and roles for this user --->

		<cfset stUser.groups = structNew()>
		<cfset stUser.roles = structNew()>
		
		<cfif structKeyExists(stSecurityZone,"groups")>

			<cfif stSecurityZone.groups.options.source eq "file">
			
				<cfloop collection=#stSecurityZone.groups.file# item="groupKey">
				
					<cfif listFindNoCase(stSecurityZone.groups.file[groupKey], stUser.user)>
					
						<cfset "stUser.groups.#groupKey#" = structNew()>
					
					</cfif>
				
				</cfloop>
			
			<cfelse>
			
				<cfparam name="stSecurityZone.groups.database.datasource" default="#request.speck.codb#">
				<cfparam name="stSecurityZone.groups.database.username" default="">
				<cfparam name="stSecurityZone.groups.database.password" default="">
				<cfparam name="stSecurityZone.groups.database.dbtype" default="">
				
				<cfset sql = replace(stSecurityZone.groups.database.usergroups,"%","'#replace(stUser.user,"'","''","all")#'","all")>
				
				<!--- query user database... --->
				<cfif stSecurityZone.groups.database.dbtype eq "query">
				
					<!--- check if we need to use a scoped lock when executing the query --->
					<cfset stQueryScope = REFindNoCase("FROM[[:space:]]+((Server|Application|Session)\.)",sql,1,true)>
					
					<cfif arrayLen(stQueryScope.pos) eq 3>
					
						<cfset lockScope = mid(sql,stQueryScope.pos[3],stQueryScope.len[3])>
						
						<cflock type="readonly" scope="#lockScope#" timeout="3">
						<cfquery name="qUserGroups" dbtype="query">
						
							#preserveSingleQuotes(sql)#
						
						</cfquery>
						</cflock>
						
					<cfelse>
						
						<cfquery name="qUserGroups" dbtype="query">
						
							#preserveSingleQuotes(sql)#
						
						</cfquery>
					
					</cfif>
				
				<cfelse>
				
					<cfquery name="qUserGroups" datasource="#stSecurityZone.groups.database.datasource#" username="#stSecurityZone.groups.database.username#" password="#stSecurityZone.groups.database.password#">
					
						#preserveSingleQuotes(sql)#
					
					</cfquery>
				
				</cfif>
				
				<cfloop query="qUserGroups">
				
					<cfset "stUser.groups.#group#" = structNew()>
				
				</cfloop>
				
			</cfif> 
		
		</cfif> <!--- structKeyExists(stSecurityZone,"groups") --->

		<cfif structKeyExists(stSecurityZone,"roles")>

			<cfset lAccessors = stUser.user & "," & structKeyList(stUser.groups)>
			
			<cfif stSecurityZone.roles.options.source eq "file">
				
				<cfloop collection=#stSecurityZone.roles.file# item="roleKey">
					
					<cfloop list=#lAccessors# index="accessor">
			
						<cfif listFindNoCase(stSecurityZone.roles.file[roleKey], accessor)>
						
							<cfset "stUser.roles.#roleKey#" = structNew()>
						
						</cfif>
						
					</cfloop>
				
				</cfloop>
			
			<cfelse>
			
				<cfparam name="stSecurityZone.roles.database.datasource" default="#request.speck.codb#">
				<cfparam name="stSecurityZone.roles.database.username" default="">
				<cfparam name="stSecurityZone.roles.database.password" default="">
				<cfparam name="stSecurityZone.roles.database.dbtype" default="">
				
				<cfset sql = "">
				<cfset noOfAccessors = listLen(lAccessors)>
				<cfloop from="1" to="#noOfAccessors#" index="i">
				
					<cfset accessor = listGetAt(lAccessors,i)>
		
					<cfset sql = sql & replace(stSecurityZone.roles.database.accessorroles,"%","'#replace(accessor,"'","''","all")#'","all")>
					
					<cfif i neq noOfAccessors>
					
						<cfset sql = sql & " UNION ">
					
					</cfif>
					
				</cfloop>
					
				<!--- <cfset sql = reReplace(stSecurityZone.roles.database.accessorroles,"=[[:space:]]*%"," IN (#listQualify(uCase(replace(lAccessors,"'","''","all")),"'")#) ","all")> --->
				
				<!--- query user database... --->
				<cfif stSecurityZone.roles.database.dbtype eq "query">
				
					<!--- check if we need to use a scoped lock when executing the query --->
					<cfset stQueryScope = REFindNoCase("FROM[[:space:]]+((Server|Application|Session)\.)",sql,1,true)>
					
					<cfif arrayLen(stQueryScope.pos) eq 3>
					
						<cfset lockScope = mid(sql,stQueryScope.pos[3],stQueryScope.len[3])>
					
						<cflock type="readonly" scope="#lockScope#" timeout="3">
						<cfquery name="qAccessorRoles" dbtype="query">
						
							#preserveSingleQuotes(sql)#
						
						</cfquery>
						</cflock>
						
					<cfelse>
						
						<cfquery name="qAccessorRoles" dbtype="query">
						
							#preserveSingleQuotes(sql)#
						
						</cfquery>
					
					</cfif>
					
				<cfelse>
				
					<cfquery name="qAccessorRoles" datasource="#stSecurityZone.roles.database.datasource#" username="#stSecurityZone.roles.database.username#" password="#stSecurityZone.roles.database.password#">
					
						#preserveSingleQuotes(sql)#
					
					</cfquery>
				
				</cfif>
				
				<cfloop query="qAccessorRoles">
				
					<cfset "stUser.roles.#role#" = structNew()>
				
				</cfloop>
			
			</cfif>
			
		</cfif> <!--- structKeyExists(stSecurityZone,"roles") --->
		
		
		<!--- only return user structure to caller if the user is found --->
		<cfset "caller.#attributes.r_stUser#" = stUser>
		
		<!--- exit the tag once we've found a user - we want to return the first user found --->
		<cfexit method="EXITTAG">
		
	
	</cfif> <!--- structKeyExists(stUser,"user") --->

</cfloop>

