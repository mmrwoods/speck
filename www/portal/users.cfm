<cfsetting enablecfoutputonly="yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfinclude template="header.cfm">

<cfparam name="url.search" default="">
<cfparam name="url.field" default="username">
<cfparam name="url.match" default="start">
<cfparam name="url.orderby" default="username">
<cfparam name="url.group" default="">
<cfparam name="url.status" default="">
<cfparam name="url.from" default="YYYY-MM-DD">
<cfparam name="url.to" default="YYYY-MM-DD">

<!--- get groups to allow search by group membership --->
<cfquery name="qGroups" datasource="#request.speck.codb#">
	SELECT * 
	FROM spGroups
</cfquery>

<cfoutput>
<script type="text/javascript">
	function openCalendar(e,field) {
		if (!e) var e = window.event;
		//document.search_users[field].value = '';
		var calendarWindow = window.open('/speck/properties/date/calendar.html?form=search_users&field=' + field,'calendar','width=225,height=160,left=' + e.screenX +',top=' + e.screenY + ',screenX=' + e.screenX +',screenY=' + e.screenY);
		calendarWindow.focus();
		return false;
	}	
	
	// sourced from Breaking Par Consulting Inc, http://www.breakingpar.com (appears to be public domain, couldn't find any license info)
	function isValidDate(dateStr, format) {
	   if (format == null) { format = "MDY"; }
	   format = format.toUpperCase();
	   if (format.length != 3) { format = "MDY"; }
	   if ( (format.indexOf("M") == -1) || (format.indexOf("D") == -1) || (format.indexOf("Y") == -1) ) { format = "MDY"; }
	   if (format.substring(0, 1) == "Y") { // If the year is first
	      var reg1 = /^\d{2}(\-|\/|\.)\d{1,2}\1\d{1,2}$/
	      var reg2 = /^\d{4}(\-|\/|\.)\d{1,2}\1\d{1,2}$/
	   } else if (format.substring(1, 2) == "Y") { // If the year is second
	      var reg1 = /^\d{1,2}(\-|\/|\.)\d{2}\1\d{1,2}$/
	      var reg2 = /^\d{1,2}(\-|\/|\.)\d{4}\1\d{1,2}$/
	   } else { // The year must be third
	      var reg1 = /^\d{1,2}(\-|\/|\.)\d{1,2}\1\d{2}$/
	      var reg2 = /^\d{1,2}(\-|\/|\.)\d{1,2}\1\d{4}$/
	   }
	   // If it doesn't conform to the right format (with either a 2 digit year or 4 digit year), fail
	   if ( (reg1.test(dateStr) == false) && (reg2.test(dateStr) == false) ) { return false; }
	   var parts = dateStr.split(RegExp.$1); // Split into 3 parts based on what the divider was
	   // Check to see if the 3 parts end up making a valid date
	   if (format.substring(0, 1) == "M") { var mm = parts[0]; }
	      else if (format.substring(1, 2) == "M") { var mm = parts[1]; } else { var mm = parts[2]; }
	   if (format.substring(0, 1) == "D") { var dd = parts[0]; } 
	      else if (format.substring(1, 2) == "D") { var dd = parts[1]; } else { var dd = parts[2]; }
	   if (format.substring(0, 1) == "Y") { var yy = parts[0]; } 
	      else if (format.substring(1, 2) == "Y") { var yy = parts[1]; } else { var yy = parts[2]; }
	   if (parseFloat(yy) <= 50) { yy = (parseFloat(yy) + 2000).toString(); }
	   if (parseFloat(yy) <= 99) { yy = (parseFloat(yy) + 1900).toString(); }
	   var dt = new Date(parseFloat(yy), parseFloat(mm)-1, parseFloat(dd), 0, 0, 0, 0);
	   if (parseFloat(dd) != dt.getDate()) { return false; }
	   if (parseFloat(mm)-1 != dt.getMonth()) { return false; }
	   return true;
	}	
	
	function validateDates() {
		var from = document.search_users.from.value;
		var to = document.search_users.to.value;
		if ( from.length > 0 && from != 'YYYY-MM-DD' && !isValidDate(from,"YMD") ) {
			alert("From date is not valid.\n\nEnter a valid date in YYYY-MM-DD format or delete the value.");
			return false;
		}
		if ( to.length > 0 && to != 'YYYY-MM-DD' && !isValidDate(to,"YMD") ) {
			alert("To date is not valid.\n\nEnter a valid date in YYYY-MM-DD format or delete the value.");
			return false;
		}
		return true;
	}
</script>
<h1>Search Users</h1>
<form action="#cgi.script_name#" name="search_users" method="get" onsubmit="return validateDates();">
	<input type="hidden" name="app" value="#url.app#" />
	<fieldset>
	<legend>Search Criteria</legend>
	<table cellpadding="2" cellspacing="2" border="0" summary="table for form layout">
		<tr>
			<td style="vertical-align:middle"><label for="search">Find String</label></td>
			<td><input type="text" name="search" id="search" value="#url.search#" size="20" style="vertical-align:middle;" /></td>
			<td style="vertical-align:middle"><label for="field">In Field</label></td>
			<td>
				<select name="field" id="field" style="vertical-align:middle;">
					<option value="username"<cfif url.field eq "username"> selected</cfif>>username</option>
					<option value="fullname"<cfif url.field eq "fullname"> selected</cfif>>fullname</option>
					<option value="email"<cfif url.field eq "email"> selected</cfif>>email address</option>
				</select>
			</td>
			<td style="vertical-align:middle"><label for="match">Match At</label></td>
			<td>
				<select name="match" id="match" style="vertical-align:middle;">
					<option value="start"<cfif url.match eq "start"> selected</cfif>>start of field</option>
					<option value="anywhere"<cfif url.match eq "anywhere"> selected</cfif>>anywhere in field</option>
					<option value="exact"<cfif url.match eq "exact"> selected</cfif>>exact match</option>
					<option value="end"<cfif url.match eq "end"> selected</cfif>>end of field</option>
				</select>
			</td>
		</tr>
		<tr>
			<td style="vertical-align:middle"><label for="group">Member of Group</label></td>
			<td>
				<select name="group" id="group" style="vertical-align:middle;">
					<option value="">-- any --</option>
					</cfoutput>
					
					<cfloop query="qGroups">
					
					   <cfoutput><option value="#groupname#"<cfif url.group eq groupname> selected</cfif>>#groupname#</option></cfoutput>
					   
					</cfloop>
					
					<cfoutput>
				</select>
			</td>
			<td style="vertical-align:middle"><label for="status">Status</label></td>
			<td>
				<select name="status" id="status" style="vertical-align:middle;"s>
					<option value="">-- any --</option>
					<option value="active"<cfif url.status eq "active"> selected</cfif>>active</option>
					<option value="suspended"<cfif url.status eq "suspended"> selected</cfif>>suspended</option>
					<option value="unconfirmed"<cfif url.status eq "unconfirmed"> selected</cfif>>unconfirmed</option>
				</select>
			</td>
			<td style="vertical-align:middle"><label for="orderby">Order by</label></td>
			<td>
				<select name="orderby" id="group" style="vertical-align:middle;">
					<option value="username"<cfif url.orderby eq "username"> selected</cfif>>username</option>
					<option value="fullname"<cfif url.orderby eq "fullname"> selected</cfif>>fullname</option>
					<option value="email"<cfif url.orderby eq "email"> selected</cfif>>email address</option>
				</select>
			</td>
		</tr>
		<tr>
			<td style="vertical-align:middle"><label for="from">Created From</label></td>
			<td>
			<input type="text" name="from" value="#url.from#" onfocus="if (this.value == 'YYYY-MM-DD' ) { this.value='' };" size="14" maxlength="10" style="vertical-align:middle;">
			<a href="javascript:return false;" 
				onclick="openCalendar(event,'from');return false;"	
				title="#request.speck.buildString("P_DATE_CALENDAR_CAPTION")#"><img src="/speck/properties/date/calendar_blue.gif" border="0" style="vertical-align:middle;"></a>
			</td>
			<td style="vertical-align:middle"><label for="to">Created To</label></td>
			<td>
			<input type="text" name="to" value="#url.to#" onfocus="if (this.value == 'YYYY-MM-DD' ) { this.value='' };" size="14" maxlength="10" style="vertical-align:middle;">
			<a href="javascript:return false;" 
				onclick="openCalendar(event,'to');return false;"	
				title="#request.speck.buildString("P_DATE_CALENDAR_CAPTION")#"><img src="/speck/properties/date/calendar_blue.gif" border="0" style="vertical-align:middle;"></a>
			</td>
			<td colspan="2" style="vertical-align:middle;text-align:right;">
			<input class="button" name="submit" type="submit" value="Search" />
			</td>
		</tr>
	</table>
	</fieldset>
</cfoutput>

<!--- always run the search query --->
<cfquery name="qUsers" datasource="#request.speck.codb#">

	SELECT *
	FROM spUsers
	WHERE 1 = 1
	<cfif len(trim(url.search))>
		AND UPPER(#url.field#)
		<cfswitch expression="#url.match#">
			<cfcase value="start">LIKE '#trim(uCase(url.search))#%'</cfcase>
			<cfcase value="anywhere">LIKE '%#trim(uCase(url.search))#%'</cfcase>
			<cfcase value="exact">= '#trim(uCase(url.search))#'</cfcase>
			<cfcase value="end">LIKE '%#trim(uCase(url.search))#'</cfcase>
		</cfswitch>
	</cfif>
	<cfif len(trim(url.status))>
	    <cfif url.status eq "active">
			AND suspended IS NULL
		<cfelseif url.status eq "suspended">
			AND suspended IS NOT NULL
		<cfelseif url.status eq "unconfirmed">
			AND registered IS NULL
		</cfif>
	</cfif>
	<cfif len(url.from) and url.from neq "YYYY-MM-DD">
		AND spCreated >= #createODBCDate(createDate(listGetAt(url.from,1,"-"),listGetAt(url.from,2,"-"),listGetAt(url.from,3,"-")))#
	</cfif>
	<cfif len(url.to) and url.to neq "YYYY-MM-DD">
		AND spCreated <= #createODBCDate(createDate(listGetAt(url.to,1,"-"),listGetAt(url.to,2,"-"),listGetAt(url.to,3,"-")))#
	</cfif>
	<cfif len(trim(url.group))>
	    AND username IN ( SELECT DISTINCT username FROM spUsersGroups WHERE groupname = '#trim(url.group)#' )
	</cfif>
	ORDER BY UPPER(#url.orderby#)
	
</cfquery>

<cf_spContentPaging
	totalRows="#qUsers.recordCount#"
	displayPerPage="20">
	
<cfscript>
	queryString = "";
	for ( key in url ) {
		if ( key neq "logoff" ) {
			queryString = listAppend(queryString,lCase(key) & "=" & url[key],"&");	
		}
	}
</cfscript>

<cfoutput>
<table width="100%">
	<tr>
	<td>
	</cfoutput>
	
	<cfif qUsers.recordCount>
	
		<cfoutput>
		<strong>#qUsers.recordCount# User<cfif qUsers.recordCount neq 1>s</cfif> Found</strong> 
		<em><a href="users_export.cfm?#queryString#" title="Export as comma-separated value format file that can be opened using Excel.">export users</a></em>
		</cfoutput>
		
		<cfquery name="qNewsletterKeywords" dbtype="query">
			SELECT * FROM request.speck.qKeywords
			WHERE template = 'newsletter'
			ORDER BY sortId
		</cfquery>
		
		<cfif qNewsletterKeywords.recordCount>
			
			<cfoutput>
			<em>| <a href="newsletter_export.cfm?app=#request.speck.appName#" title="Export newsletter subscribers as comma-separated value format file that can be opened using Excel.">export newsletter subscribers</a></em>					
			</cfoutput>
			
		</cfif>
		
	<cfelse>
		
		<cfoutput>
		No Users Found
		</cfoutput>
		
	</cfif>
	
	<cfoutput>
	</td>
	<td align="right">#stPaging.menu#</td>
	</tr>
</table>
<table cellpadding="1" cellspacing="1" border="0" width="100%" summary="search results" class="data_table">
<caption></caption>
<thead>
	<tr>
		<th>Username</th>
		<th>Full Name</th>
		<th>Email Address</th>
		<th>Groups</th>
		<th>&nbsp;</th>
		<th>&nbsp;</th>
	</tr>
</thead>
<tbody>
</cfoutput>

<cfif qUsers.recordCount>

	<cfloop query="qUsers" startrow="#stPaging.startRow#" endrow="#stPaging.endRow#">
	
		<!--- ok, this is slow, but there's only ever 20 of these queries per page --->
		<cfquery name="qGroups" datasource="#request.speck.codb#">
			SELECT groupname 
			FROM spUsersGroups 
			WHERE username = '#username#' 
				AND ( expires IS NULL OR expires > CURRENT_TIMESTAMP )
		</cfquery>
		
		<!--- TODO: make me pretty, add some nice DHTML tooltip thingymajig etc. --->
		<cfset lGroups = valueList(qGroups.groupname)>
		<cfif len(lGroups) gt 25>
			<cfset lGroups = left(lGroups,25) & "...">
		</cfif>
	
		<cfoutput>
			<tr <cfif currentRow mod 2 eq 1>class="alternateRow"</cfif>>
				<td nowrap="yes">#username#</td>
				<td nowrap="yes">#fullname#</td>
				<td nowrap="yes">#email#</td>
				<td nowrap="yes">#lGroups#</td>
				<td style="text-align:center"><a href="user.cfm?app=#url.app#&username=#username#">edit</a></td>
				<td style="text-align:center"><a href="user_delete.cfm?app=#url.app#&username=#username#" onclick="return confirm('Delete user \'#username#\'.\n\nAre you sure?');">delete</a></td>
			</tr>
		</cfoutput>
		
		
	</cfloop>
		
	<cfoutput>
	</tbody>
	</table>
	</cfoutput>
	
<cfelse>

	<cfoutput><tr><td colspan="7" class="alternateRow" style="text-align:center"><em>No Users Found</em></td></tr></cfoutput>

</cfif>

<cfinclude template="footer.cfm">