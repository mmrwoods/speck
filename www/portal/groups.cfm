<cfsetting enablecfoutputonly="yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- always return all groups (we'll just assume there won't be hundreds of groups) --->
<!--- um, maybe this correlated subquery and union is overly complicated if we're not returning loads of rows --->
<cfquery name="qGroups" datasource="#request.speck.codb#">
	
	SELECT x.groupname AS groupname, x.description AS description, 
		1 AS hasCMSRole, 
		UPPER(groupname) AS ordergroup
	FROM spGroups x
	WHERE EXISTS (
		SELECT accessor 
		FROM spRolesAccessors y 
		WHERE <!--- y.rolename IN ('spSuper','spEdit','spLive','spKeywords','spUsers')
			AND  --->x.groupname = y.accessor
	)
	UNION 
	SELECT x.groupname AS groupname, x.description AS description, 
		0 AS hasCMSRole,
		UPPER(groupname) AS ordergroup
	FROM spGroups x
	WHERE NOT EXISTS (
		SELECT accessor 
		FROM spRolesAccessors y 
		WHERE <!--- y.rolename IN ('spSuper','spEdit','spLive','spKeywords','spUsers') 
			AND  --->x.groupname = y.accessor
	)
	ORDER BY ordergroup
	
</cfquery>

<cfinclude template="header.cfm">

<cfoutput>
<h1>List Groups</h1>
</cfoutput>

<cfif qGroups.recordCount>

	<cf_spContentPaging
		totalRows="#qGroups.recordCount#"
		displayPerPage="25">
	
	#stPaging.menu#
	
</cfif>

<cfoutput>
<table cellpadding="1" cellspacing="1" border="0" width="100%" class="data_table">
<caption>All Groups</caption>
<thead>
	<tr>
		<th>Group Name</th>
		<th>Description</th>
		<th>CMS</th>
		<th>&nbsp;</th>
		<th>&nbsp;</th>
	</tr>
</thead>
<tbody>
</cfoutput>

<cfif qGroups.recordCount>

	<cfloop query="qGroups" startrow="#stPaging.startRow#" endrow="#stPaging.endRow#">
		<cfoutput>
			<tr <cfif currentRow mod 2 eq 1>class="alternateRow"</cfif>>
				<td nowrap="yes">#groupname#</td>
				<td>#description#</td>
				<td nowrap="yes" style="text-align:center">#yesNoFormat(hasCMSRole)#</td>
				<td style="text-align:center"><a href="group.cfm?app=#url.app#&groupname=#groupname#">edit</a></td>
				<td style="text-align:center"><a href="group_delete.cfm?app=#url.app#&groupname=#groupname#" onclick="return confirm('Delete group \'#groupname#\'.\n\nAre you sure?');">delete</a></td>
			</tr>
		</cfoutput>
	</cfloop>
		
	<cfoutput>
	</tbody>
	</table>
	</cfoutput>
	
<cfelse>

	<cfoutput><tr><td colspan="7" class="alternateRow" style="text-align:center"><em>No Groups Found</em></td></tr></cfoutput>

</cfif>

<cfinclude template="footer.cfm">