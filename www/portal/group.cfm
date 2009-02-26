<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfparam name="url.groupname" default=""> <!--- this will have content if we are editing a group --->
<cfparam name="form.referrer" default="#cgi.http_referer#">

<cfif len(url.groupname)>

	<!--- get the group details --->
	<cfquery name="qGroup" datasource="#request.speck.codb#">
		SELECT * FROM spGroups WHERE groupname = '#url.groupname#'
	</cfquery>
	
	<!--- role memberships --->
	<cfquery name="qRolesAccessors" datasource="#request.speck.codb#">
		SELECT rolename FROM spRolesAccessors WHERE accessor = '#url.groupname#' ORDER BY UPPER(rolename)
	</cfquery>
	
	<!--- now update the form fields --->
	<cfparam name="form.groupname" default="#qGroup.groupname#"> <!--- this should be readonly when editing --->
	<cfparam name="form.description" default="#qGroup.description#">
	<cfif cgi.request_method eq "post">
		<cfparam name="form.roles" default=""> <!--- hack to allow for the fact that when the selectbox is empty, nothing is submitted --->
	<cfelse>
		<cfparam name="form.roles" default="#valueList(qRolesAccessors.rolename)#">
	</cfif>
	
<cfelse>
	
	<cfparam name="form.groupname" default="">
	<cfparam name="form.description" default="">
	<cfparam name="form.roles" default="">

</cfif>

<!--- get all roles --->
<cfquery name="qRoles" datasource="#request.speck.codb#">
	SELECT * FROM spRoles ORDER BY UPPER(rolename)
</cfquery>


<!--- include the template that handles the form post --->
<cfinclude template="group_action.cfm">


<cfinclude template="header.cfm">

<cfoutput>
<script type="text/javascript" src="selectbox.js"></script>

<h1><cfif len(url.groupname)>Edit<cfelse>Add</cfif> Group</h1>
</cfoutput>

<!--- include template to handle any form submission errors --->
<cfinclude template="action_errors.cfm">

<cfoutput>
<form name="spGroupForm" action="#cgi.script_name#?app=#url.app#&groupname=#url.groupname#" onsubmit="selectAllOptions(document.spGroupForm.roles)" method="post">
<input type="hidden" name="referrer" value="#form.referrer#" />
<fieldset>
<legend>Group Details</legend>
<table cellpadding="2" cellspacing="2" border="0">
	<tr>
	<td style="vertical-align:middle"><span class="required">*</span><label for="groupname">Name</label></td>
	<td><input <cfif len(url.groupname)>readonly="yes" class="readonly"</cfif> type="text" name="groupname" id="groupname" value="#form.groupname#" size="30" maxlength="50" /></td>
	</tr>
	<tr>
	<td style="vertical-align:middle"><label for="description">Description</label></td>
	<td><input type="text" name="description" id="description" value="#form.description#" size="80" maxlength="100" /></td>
	</tr>
</table>
</fieldset>

<fieldset>
<legend>Role Membership</legend>
<table border="0" cellpadding="0" cellspacing="0" width="100%">
	<tr>
	<td width="45%">Available<br />
		<select name="roles_from" multiple="multiple" size="5" style="width:100%;">
		</cfoutput>
					
		<cfloop query="qRoles">
			
			<cfif not listFind(form.roles,rolename)>
				
				<cfoutput><option value="#rolename#">#rolename#</option></cfoutput>
				
			</cfif>
	
		</cfloop>
				
		<cfoutput>
		</select>
	</td>
	<td width="10%" style="vertical-align:middle;text-align:center;"><br />
		<input class="button" name="roles_right" value="&gt;&gt;" onclick="moveSelectedOptions(this.form['roles_from'],this.form['roles'],true);" type="button"><br />
		<input class="button" name="roles_left" value="&lt;&lt;" onclick="moveSelectedOptions(this.form['roles'],this.form['roles_from'],true)" type="button">
	</td>
	<td width="45%">Selected<br />
		<select name="roles" multiple="multiple" size="5" style="width:100%;">
		</cfoutput>
		
		<cfloop query="qRoles">
			
			<cfif listFind(form.roles,rolename)>
				
				<cfoutput><option value="#rolename#">#rolename#</option></cfoutput>
				
			</cfif>
	
		</cfloop>
				
		<cfoutput>
		</select>
	</td>
	</tr>
</table>
</fieldset>
</cfoutput>

<cfoutput>
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