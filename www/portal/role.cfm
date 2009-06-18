<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfparam name="url.rolename" default=""> <!--- this will have content if we are editing a role --->
<cfparam name="form.referrer" default="#cgi.http_referer#">

<cfif len(url.rolename)>

	<!--- get the role details --->
	<cfquery name="qRole" datasource="#request.speck.codb#">
		SELECT * FROM spRoles WHERE rolename = '#url.rolename#'
	</cfquery>
	
	<!--- now update the form fields --->
	<cfparam name="form.rolename" default="#qRole.rolename#"> <!--- this should be readonly when editing --->
	<cfparam name="form.description" default="#qRole.description#">

<cfelse>
	
	<cfparam name="form.rolename" default="">
	<cfparam name="form.description" default="">
	<cfparam name="form.groupname" default="">

</cfif>

<!--- include the template that handles the form post --->
<cfinclude template="role_action.cfm">

<cfinclude template="header.cfm">

<cfoutput>
<h1><cfif len(url.rolename)>Edit<cfelse>Add</cfif> Role</h1>
</cfoutput>

<!--- include template to handle any form submission errors --->
<cfinclude template="action_errors.cfm">

<cfoutput>
<form name="spRoleForm" action="#cgi.script_name#?app=#url.app#&rolename=#url.rolename#" method="post">
<input type="hidden" name="referrer" value="#form.referrer#" />
<fieldset>
<legend>Role Details</legend>
<table cellpadding="2" cellspacing="2" border="0">
	<tr>
	<td style="vertical-align:middle"><span class="required">*</span><label for="rolename">Name</label></td>
	<td><input <cfif len(url.rolename)>readonly="yes" class="readonly"</cfif> type="text" name="rolename" id="rolename" value="#form.rolename#" size="30" maxlength="50" /></td>
	</tr>
	<tr>
	<td style="vertical-align:middle"><label for="description">Description</label></td>
	<td><input type="text" name="description" id="description" value="#form.description#" size="80" maxlength="100" /></td>
	</tr>
	<cfif not len(url.rolename)>
		<!--- <cfsavecontent variable="hint">
		<cfoutput>
			Roles are used to grant users access to various elements of the content management system (CMS). 
			Users can only be connected to roles via groups, and you can use this option to create a group 
			when creating a role. This is useful when granting edit permissions to a number of site sections 
			to certain users, without giving those users edit permissions for the entire site. In this case, 
			you need to create the new role, but also need some way of granting that role to users.
		</cfoutput>
		</cfsavecontent>
		<cfset hint = jsStringFormat(reReplace(hint,"[[:space:]]+"," ","all"))> --->
		<tr>
		<td style="vertical-align:middle;whitespace:no-wrap;" nowrap="yes"><label for="groupname">Group Name</label>&nbsp;<span class="hint" onmouseover="return escape('Enter a group name to create a new group with this role');"> </span>&nbsp;</td>
		<td>
		<input type="text" name="groupname" id="groupname" value="#form.groupname#" size="30" maxlength="50" />
		<a href="javascript:return false;" onclick="this.style.display='none';document.getElementById('create_group_info_text').style.display='block';">more info</a>
		</td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>
			<div id="create_group_info_text" style="display:none;">
			Roles are used to grant users access to various elements of the content management system (CMS). 
			Users can only be connected to roles via groups, and you can use this option to create a group 
			when creating a role. This is useful when granting edit permissions to a number of site sections 
			to certain users, without giving those users edit permissions for the entire site. In this case, 
			you need to create the new role, but also need some way of granting that role to users, and this 
			can be achieved by making them members of the group. 
			<br><em>Note: when choosing a group name, it's good practice to choose the plural of the role name.</em>
			</div>
			</td>
		</tr>
	</cfif>
</table>
</fieldset>

<table width="100%" border="0" cellpadding="5">
	<tr>
	<td align="right">
	<input class="button" name="submit" type="submit" value="Save Changes" />&nbsp;&nbsp;
	<input class="button" type="button" value="Cancel" onclick="javascript:window.location.href='#form.referrer#';" />
	</td>
	</tr>
</table>
</form>
</cfoutput>
		
<cfinclude template="footer.cfm">