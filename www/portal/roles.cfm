<cfsetting enablecfoutputonly="yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfquery name="qRoles" datasource="#request.speck.codb#">
	SELECT rolename, description
	FROM spRoles
	ORDER BY UPPER(rolename)
</cfquery>

<cfinclude template="header.cfm">

<cfoutput>
<h1>List Roles</h1>
</cfoutput>

<cfif qRoles.recordCount>

	<cf_spContentPaging
		totalRows="#qRoles.recordCount#"
		displayPerPage="25">
	
	#stPaging.menu#
	
</cfif>

<cfoutput>
<table cellpadding="1" cellspacing="1" border="0" width="100%" class="data_table">
<caption>All Roles</caption>
<thead>
	<tr>
		<th>Role Name</th>
		<th>Description</th>
		<th>&nbsp;</th>
		<th>&nbsp;</th>
	</tr>
</thead>
<tbody>
</cfoutput>

<cfif qRoles.recordCount>

	<cfloop query="qRoles" startrow="#stPaging.startRow#" endrow="#stPaging.endRow#">
		<cfoutput>
			<tr <cfif currentRow mod 2 eq 1>class="alternateRow"</cfif>>
				<td nowrap="yes">#rolename#</td>
				<td>#description#</td>
				<td style="text-align:center"><a href="role.cfm?app=#url.app#&rolename=#rolename#">edit</a></td>
				<cfif listFindNoCase("spSuper,spLive,spEdit,spKeywords,spUsers",rolename)>
					<td style="text-align:center"><del>delete</del></td>
				<cfelse>
					<td style="text-align:center"><a href="role_delete.cfm?app=#url.app#&rolename=#rolename#" onclick="return confirm('Delete role \'#rolename#\'.\n\nAre you sure?');">delete</a></td>
				</cfif>
			</tr>
		</cfoutput>
	</cfloop>
		
	<cfoutput>
	</tbody>
	</table>
	</cfoutput>
	
<cfelse>

	<cfoutput><tr><td colspan="7" class="alternateRow" style="text-align:center"><em>No Roles Found</em></td></tr></cfoutput>

</cfif>

<cfinclude template="footer.cfm">