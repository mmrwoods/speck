<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfoutput>
<!--- note: DOCTYPE required to force IE to render in standards mode and allow the use of tr:hover --->
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>Manage Users</title>
	<link rel="stylesheet" href="#request.speck.adminStylesheet#" type="text/css">
	<!--- additional style stuff - we'll move this to a separate file later --->
	<style type="text/css">
		##navigation ul {
			list-style-type: none;
			padding: 3px 0;
			margin: 1px 0 0 0;
			border-bottom: 1px solid ##669;			
		}
		##navigation li {
			list-style: none;
			margin: 0;
			display: inline;
		}
		##navigation ul li a {
			padding: 3px 0.5em;
			margin-left: 3px;
			border: 1px solid ##669;
			border-bottom: none;
			background: ##f7f7f7;
			text-decoration: none;
		}
		##navigation ul li a:link {
			color: ##667;
		}
		##navigation ul li a:visited {
			color: ##667;
		}
		##navigation ul li a:link:hover, ##navigation ul li a:visited:hover {
			color: black;
			background: ##f2f2ee;
		}
		##navigation ul li a.selected {
			color: black;
			background: ##ece9d8;
			border-bottom: 1px solid ##ece9d8;
		}
		##system_response {
			margin-top: 20px;
			margin-left: 150px;
		}
		##spUserForm select { width:190px; }
		
		table.data_table tbody tr:hover { background: ##F2F5A9; }
	</style>
</head>
<body>
</cfoutput>

<!--- navigation stuff is next, but we need to know what section we are in first --->
<!--- 
this could be neater, there should really be a single entry point / controller 
which is passed the action etc., but I'm in a hurry, hence the hacky solution
--->	  
<cfif find("user",cgi.script_name)>
	<cfset section = "users">
<cfelseif find("group",cgi.script_name)>
	<cfset section = "groups">
<cfelseif find("role",cgi.script_name)>
	<cfset section = "roles">
<cfelse>
	<cfset section = "unknown">
</cfif>

<cfif request.speck.userHasPermission("spSuper")>

	<cfoutput>
	<!--- top level navigation, hide from non-super users (no, this is not security, it's just a way of stopping people do foolish things) --->
	<div id="navigation">
	
		<ul>
			<li><a href="users.cfm?app=#url.app#"<cfif section eq "users"> class="selected"</cfif>>Users</a></li>
			<li><a href="groups.cfm?app=#url.app#"<cfif section eq "groups"> class="selected"</cfif>>Groups</a></li>
			<li><a href="roles.cfm?app=#url.app#"<cfif section eq "roles"> class="selected"</cfif>>Roles</a></li>
		</ul>
	
	</div>
	</cfoutput>

</cfif>

<cfoutput>
<!--- now sub-navigation --->
<div id="subnav">
</cfoutput>

<cfswitch expression="#section#">

	<cfcase value="users">
		<cfoutput>
		<a href="users.cfm?app=#url.app#">search users</a> |
		<a href="user.cfm?app=#url.app#">add a user</a>
		</cfoutput>
	</cfcase>
	
	<cfcase value="groups">
		<cfoutput>
		<a href="groups.cfm?app=#url.app#">list groups</a> |
		<a href="group.cfm?app=#url.app#">add a group</a>
		</cfoutput>
	</cfcase>
	
	<cfcase value="roles">
		<cfoutput>
		<a href="roles.cfm?app=#url.app#">list roles</a> |
		<a href="role.cfm?app=#url.app#">add a role</a>
		</cfoutput>
	</cfcase>

</cfswitch>
	
<cfoutput>
</div> <!--- replace br with styling on the div later --->
</cfoutput>