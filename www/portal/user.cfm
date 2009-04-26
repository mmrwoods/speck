<cfsetting enablecfoutputonly="true">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfset json = createObject("component","json")>

<cfparam name="url.username" default=""> <!--- this will have content if we are editing a user --->

<cfset return_to = "/speck/portal/users.cfm?app=#request.speck.appName#">

<cfset lSystemProperties = "username,fullname,password,email,notes,suspended,expires,newsletter">
<cfset stType = request.speck.types.spUsers>

<cfif len(url.username)>

	<!--- get the user details --->
	<cfquery name="qUser" datasource="#request.speck.codb#">
		SELECT * FROM spUsers WHERE username = '#url.username#'
	</cfquery>
	
	<!--- users group memberships --->
	<cfquery name="qUserGroups" datasource="#request.speck.codb#">
		SELECT groupname, expires
		FROM spUsersGroups 
		WHERE username = '#url.username#' 
		ORDER BY UPPER(groupname)
	</cfquery>
	
	<!--- now update the form fields --->
	<!--- 
	note re passwords: we set the form values to the first 20 characters of the current password, 
	whether the current password is hashed or not (the maxlength of the form field is 20). Then, 
	when processing the form post, if the posted password value is different than the first 20 
	characters of the existing password, we assume the password has been changed, otherwise assume 
	the password has not been changed. The chances of someone managing to modify their existing 
	password and entering the first 20 characters of the encrypted/hashed version of that existing 
	password as the new one has gotta be damn remote.
	 --->
	<cfparam name="form.username" default="#qUser.username#"> <!--- this should be readonly when editing --->
	<cfparam name="form.fullname" default="#qUser.fullname#">
	<cfparam name="form.password" default="#left(qUser.password,20)#">
	<cfparam name="form.password_confirm" default="#left(qUser.password,20)#">
	<cfparam name="form.email" default="#qUser.email#">
	<cfparam name="form.notes" default="#qUser.notes#">
	
	<cfif isDefined("qUser.suspended") and isDate(qUser.suspended)>
		<cfparam name="form.suspended" default="1" type="boolean">
	<cfelse>
		<cfparam name="form.suspended" default="0" type="boolean">
	</cfif>
	
	<cfif isDefined("qUser.newsletter") and isBoolean(qUser.newsletter)>
		<cfparam name="form.newsletter" default="#qUser.newsletter#">
	<cfelse>
		<cfparam name="form.newsletter" default="0" type="boolean">
	</cfif>
	
	<cfif cgi.request_method eq "post">
		<cfparam name="form.groups" default=""> <!--- hack to allow for the fact that when the selectbox is empty, nothing is submitted --->
	<cfelse>
		<cfparam name="form.groups" default="#valueList(qUserGroups.groupname)#">
	</cfif>
	
	<!--- cfparam the groups expiration struct --->
	<cfset stGroupsExpiration = structNew()>
	<cfloop query="qUserGroups">
		<cfset void = structInsert(stGroupsExpiration,groupname,dateFormat(expires,"YYYY-MM-DD"))>
	</cfloop>
	<cfparam name="form.groups_expiration" default="#json.encode(stGroupsExpiration)#">
	
	<cfif len(qUser.expires)>
		<cfparam name="form.expires" default="#dateFormat(qUser.expires,"YYYY-MM-DD")#">
	<cfelse>
		<cfparam name="form.expires" default="YYYY-MM-DD">
	</cfif>
	
	<cfloop from="1" to="#arrayLen(stType.props)#" index="i">
	
		<cfif not listFindNoCase(lSystemProperties,stType.props[i].name)>
			
			<cfif listFindNoCase(qUser.columnList,stType.props[i].name)>
				<cfparam name="form.#stType.props[i].name#" default="#qUser[stType.props[i].name]#">
			<cfelse>
				<cfparam name="form.#stType.props[i].name#" default="">
			</cfif>

		</cfif>
	
	</cfloop>
	
	<cfset id = qUser.spId>
	
<cfelse>

	<!---
	
		This library is part of the Common Function Library Project. An open source
		collection of UDF libraries designed for ColdFusion 5.0. For more information,
		please see the web site at:
		
			http://www.cflib.org
		
		Warning:
		You may not need all the functions in this library. If speed
		is _extremely_ important, you may want to consider deleting
		functions you do not plan on using. Normally you should not
		have to worry about the size of the library.
		
		License:
		This code may be used freely. 
		You may modify this code as you see fit, however, this header, and the header
		for the functions must remain intact.
	
		This code is provided as is.  We make no warranty or guarantee.  Use of this code is at your own risk.
	--->

	<cfscript>
	/**
	* Generates an 8-character random password free of annoying similar-looking characters such as 1 or l.
	* 
	* @return Returns a string. 
	* @author Alan McCollough (amccollough@anmc.org) 
	* @version 1, December 18, 2001 
	*/
	function MakePassword() {
		var valid_password = 0;
		var loopindex = 0;
		var this_char = "";
		var seed = "";
		var new_password = "";
		var new_password_seed = "";
		while (valid_password eq 0) {
			new_password = "";
			new_password_seed = CreateUUID();
			for(loopindex=20; loopindex LT 35; loopindex = loopindex + 2) {
				this_char = inputbasen(mid(new_password_seed, loopindex,2),16);
				seed = int(inputbasen(mid(new_password_seed,loopindex/2-9,1),16) mod 3)+1;
				switch(seed){
					case "1": {
					new_password = new_password & chr(int((this_char mod 9) + 48));
					break;
					}
					case "2": {
					new_password = new_password & chr(int((this_char mod 26) + 65));
					break;
					}
					case "3": {
					new_password = new_password & chr(int((this_char mod 26) + 97));
					break;
					}
				} //end switch
			}
			valid_password = iif(refind("(O|o|0|i|l|1|I|5|S)",new_password) gt 0,0,1);	
		}
		return new_password;
	}
	</cfscript>
	
	<cfparam name="form.username" default="">
	<cfparam name="form.fullname" default="">
	<cfif cgi.request_method eq "post">
		<cfparam name="form.password" default="">
		<cfparam name="form.password_confirm" default="">
	<cfelse>
		<cfset generatedPassword = makePassword()>
		<cfparam name="form.password" default="#generatedPassword#">
		<cfparam name="form.password_confirm" default="#generatedPassword#">
	</cfif>
	<cfparam name="form.email" default="">
	<cfparam name="form.notes" default="">
	<cfparam name="form.suspended" default="0" type="boolean">
	<cfparam name="form.newsletter" default="1" type="boolean">
	<cfparam name="form.groups" default="">
	<cfparam name="form.groups_expiration" default="">
	<cfparam name="form.expires" default="">
	
	<cfparam name="form.send_password" default="1" type="boolean">
	
	<cfloop from="1" to="#arrayLen(stType.props)#" index="i">
	
		<cfif not listFindNoCase(lSystemProperties,stType.props[i].name)>
		
			<cfparam name="form.#stType.props[i].name#" default="">
			
		</cfif>
	
	</cfloop>
	
	<cfset id = createUuid()>

</cfif>


<!--- get all groups --->
<cfquery name="qGroups" datasource="#request.speck.codb#">
	SELECT * FROM spGroups ORDER BY UPPER(groupname)
</cfquery>


<!--- include the template that handles the form post --->
<cfinclude template="user_action.cfm">


<cfinclude template="header.cfm">

<cfoutput>
<script type="text/javascript" src="/speck/javascripts/json.js"></script>
<script type="text/javascript" src="selectbox.js"></script>
<script type="text/javascript">
	
	function openCalendar(e,field) {
		if (!e) var e = window.event;
		//document.search_users[field].value = '';
		var calendarWindow = window.open('/speck/properties/date/calendar.html?form=speditform&field=' + field,'calendar','width=225,height=160,left=' + e.screenX +',top=' + e.screenY + ',screenX=' + e.screenX +',screenY=' + e.screenY);
		calendarWindow.focus();
		return false;
	}	
	
	function cleanupGroups() {
		// clean up groups after move from selected to available
		var available = document.speditform.groups_from;
		for (var i=0; i<available.options.length; i++) {
			available.options[i].text = available.options[i].text.replace(/ .*/,"");
		}
		// clean up expiration object
		var oldExpirationObj = document.speditform.groups_expiration.value.parseJSON();
		var selected = document.speditform.groups;
		var newExpirationObj = new Object();
		for (var i=0; i<selected.options.length; i++) {
			if ( oldExpirationObj[selected.options[i].value] ) {
				newExpirationObj[selected.options[i].value] = oldExpirationObj[selected.options[i].value];
			} else {
				newExpirationObj[selected.options[i].value] = "";	
			}
		}
		document.speditform.groups_expiration.value = newExpirationObj.toJSONString();
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
	
	function setExpirationDate() {
		var expirationObj = document.speditform.groups_expiration.value.parseJSON();
		var selected = document.speditform.groups;
		if ( selected.selectedIndex == -1 ) { return false; }
		var group = selected.options[selected.selectedIndex].value;
		if ( expirationObj[group] ) {
			var defaultValue = expirationObj[group];
		} else {
			var defaultValue = "";
		}
		var dateString = prompt("Enter new expiration date in YYYY-MM-DD format", defaultValue);
		if ( dateString != null ) {
			var dateComponents = dateString.split("-");
			if ( dateString == "" || isValidDate(dateString,"YMD") ) {
				//var year = parseInt(dateComponents[0]);
				//var month = parseInt(dateComponents[1].replace(/^0/,"")) - 1;
				//var day = parseInt(dateComponents[2].replace(/^0/,""));
				//var newDate = new Date(year,month,day);
				expirationObj[group] = dateString;
				document.speditform.groups_expiration.value = expirationObj.toJSONString();
				// rebuild groups text...
				for (var i=0; i<selected.options.length; i++) {
					selected.options[i].text = selected.options[i].value;
					if ( expirationObj[selected.options[i].value] && expirationObj[selected.options[i].value] != "" ) {
						selected.options[i].text = selected.options[i].text + " (expires " + expirationObj[selected.options[i].value] + ")";	
					}
				}
			} else {
				alert("Invalid Date");
			}
		}
	}
</script>
<h1><cfif len(url.username)>Edit<cfelse>Add</cfif> User</h1>
</cfoutput>

<!--- include template to handle any form submission errors --->
<cfinclude template="action_errors.cfm">

<!--- quick hack to limit the max width on input fields so they fit on the screen (really only added for FF on Linux - it was bugging me) --->
<cfsavecontent variable="addToHtmlHead">
<cfoutput>
<style type="text/css">
input {max-width:220px;}
</style>
</cfoutput>
</cfsavecontent>
<cfhtmlhead text="#addToHtmlHead#">

<cfoutput>
<form name="speditform" id="spUserForm" action="#cgi.script_name#?app=#url.app#&username=#url.username#&return_to=#urlEncodedFormat(return_to)#" autocomplete="off" onsubmit="selectAllOptions(document.speditform.groups)" method="post">
<input type="hidden" name="groups_expiration" value='#form.groups_expiration#' /> <!--- note: json strings are double-quoted --->
<fieldset>
<legend>User Information</legend>
<script type="text/javascript">
	function generateUsername() {
		if ( document.getElementById("username").value.length == 0 ) {
			var namestr = document.getElementById("fullname").value;
			var username = "";
			namestr = namestr.replace(/[^\w\s]+/g,"");
			namestr = namestr.replace(/\s+/g," ");
			namestr = namestr.toLowerCase();
			var namearr = namestr.split(" ");
			if ( namearr.length == 1 ) {
				username = namearr[0];
			} else {
				var lastname = namearr.pop();
				for (i = 0; i < namearr.length; i++) {
					username = username + namearr[i].slice(0,1);
				}
				username = username + lastname;
			}
			document.getElementById("username").value = username;
		}
	}
</script>
<table cellpadding="2" cellspacing="2" border="0" width="100%">
	<tr>
	<td style="vertical-align:middle"><span class="required">*</span><label for="fullname">Full Name</label></td>
	<td><input type="text" onblur="generateUsername()" name="fullname" id="fullname" value="#form.fullname#" size="35" maxlength="100" /></td>
	<td>&nbsp;</td>
	<td style="vertical-align:middle"><span class="required">*</span><label for="username">Username</label></td>
	<td><input  <cfif len(url.username)>readonly="yes" class="readonly"</cfif> type="text" name="username" id="username" value="#form.username#" size="35" maxlength="20" /></td>
	</tr>
	<tr>
	<td style="vertical-align:middle"><label for="email">Email Address</label></td>
	<td><input type="text" name="email" id="email" value="#form.email#" size="35" maxlength="100" /></td>
	<td>&nbsp;</td>
	<td style="vertical-align:middle"><span class="required">*</span><cfif not len(request.speck.portal.passwordEncryption)><label for="password"><span class="hint" onmouseover="return escape('The password is hidden for security purposes, but you can view it by moving the mouse over the password field.');">Password</span></label><cfelse><label for="password">Password</label></cfif></td>
	<td><input <cfif len(url.username)>type="password"<cfelse>type="text"</cfif> name="password" id="password" value="#form.password#" <cfif not len(request.speck.portal.passwordEncryption)>title="#form.password#"</cfif> size="35" maxlength="20" /></td>
	</tr>
	<tr>
	<td style="vertical-align:middle" nowrap="yes"><label for="newsletter"><span class="hint" onmouseover="return escape('Include the user\'s name and email address in the newsletter subscription list? You can export the list of subscribers and use it to send a newsletter.');">Send Newsletter</span></label></td>
	<td style="vertical-align:middle">
		<cfparam name="request.speck.portal.newsletter" default="false" type="boolean">
		<cfset bNewsletterEnabled = request.speck.portal.newsletter>
		<cfif not bNewsletterEnabled>
			<cfquery name="qNewsletterKeywords" dbtype="query">
				SELECT * FROM request.speck.qKeywords
				WHERE template = 'newsletter'
				ORDER BY sortId
			</cfquery>
			<cfif qNewsletterKeywords.recordCount>
				<cfset bNewsletterEnabled = true>
			</cfif>
		</cfif>
		<input type="radio" name="newsletter" value="1"<cfif form.newsletter> checked="yes"</cfif><cfif not bNewsletterEnabled> disabled="yes"</cfif> />Yes
		<input type="radio" name="newsletter" value="0"<cfif not form.newsletter> checked="yes"</cfif><cfif not bNewsletterEnabled> disabled="yes"</cfif> />No
	</td>
	<td>&nbsp;</td>
	</cfoutput>
	
	<cfif len(url.username)>
	
		<cfoutput>
		<td style="vertical-align:middle"><span class="required">*</span><label for="password_confirm">Confirm Password</label></td>
		<td><input <cfif len(url.username)>type="password"<cfelse>type="text"</cfif> name="password_confirm" id="password_confirm" value="#form.password_confirm#" <cfif not len(request.speck.portal.passwordEncryption)>title="#form.password#"</cfif> size="35" maxlength="20" /></td>
		</cfoutput>
	
	<cfelse>
	
		<cfoutput>
		<td style="vertical-align:middle" nowrap="yes"><label for="send_password"><span class="hint" onmouseover="return escape('Email the username and password to the user after creating the account (highly recommended!). Only works if you enter an email address for the user.');">Send Password</span></label></td>
		<td style="vertical-align:middle">
			<input type="radio" name="send_password" value="1"<cfif form.send_password> checked="yes"</cfif> />Yes
			<input type="radio" name="send_password" value="0"<cfif not form.send_password> checked="yes"</cfif> />No
		</td>
		</cfoutput>

	</cfif>
	
	<cfoutput>
	</tr>
	</cfoutput>

	<cfset oddOrEven = 0>
	<cfloop from=1 to="#arrayLen(stType.props)#" index="i">
	
		<cfif not listFindNoCase(lSystemProperties,stType.props[i].name)>
			
			<cfscript>
				stPD = duplicate(stType.props[i]);
				stPD.required = false;
				if ( stPD.type eq "Date" ) {
					stPD.richEdit = true;
				} else if ( stPD.type eq "Text" or stPD.type eq "Html" ) {
					stPD.richEdit = false;
					stPd.displaySize = 35;
				}
				displayValue = form[stPD.name];
			</cfscript>
			
			<cfif stPD.displaySize eq 0>
			
				<cfif stPD.type eq "Asset">
					<cfoutput><input type="hidden" name="#stPD.name#" value=""></cfoutput>
				<cfelseif stPD.type eq "DateTime" and len(displayValue)>
					<cfoutput><input type="hidden" name="#stPD.name#" value="#dateFormat(displayValue,"YYYY-MM-DD")# #timeFormat(displayValue,"HH:MM")#"></cfoutput>
				<cfelse>
					<cfoutput><input type="hidden" name="#stPD.name#" value="#replace(displayValue,"""","&quot;","all")#"></cfoutput>
				</cfif>
				
			<cfelseif stPD.type neq "fieldset">
			
				<cfset oddOrEven = 1 - oddOrEven>
				
				<cfif oddOrEven>
				
					<cfoutput><tr></cfoutput>
				
				</cfif>
				
				<cfoutput>
				<td style="vertical-align:middle"><cfif stPD.required><span class="required" style="color:red;">*</span></cfif><label for="#stPD.name#">#stPD.caption#</label></td>
				<td>
				</cfoutput>
				
				<cfmodule template=#request.speck.getPropertyHandlerTemplate(stPD,"renderFormField")#
					method="renderFormField"
					stPD=#stPD#
					id=#id#
					revision=1
					value=#displayValue#
					action="add">
					
				<cfoutput>
				</td>
				</cfoutput>
				
				<cfif oddOrEven>
				
					<cfoutput><td>&nbsp;</td></cfoutput>
		
				<cfelse>
				
					<cfoutput></tr></cfoutput>
				
				</cfif>
			
			</cfif>
			
		</cfif>
		
	</cfloop>
	
	<cfif oddOrEven>
	
		<cfoutput><td colspan="2">&nbsp;</td></tr></cfoutput>
	
	</cfif>

	<cfoutput>
	<tr>
	<td nowrap="yes"><label for="notes"><span class="hint" onmouseover="return escape('The notes field is only accessible from this window. Standard users cannot view or edit their own notes.');">Notes</span></label></td>
	<td colspan="4">
		<textarea name="notes" id="notes" rows="3" cols="80" style="max-width:800px;width:600px">#form.notes#</textarea>
	</td>
	</tr>
	</cfoutput>
	
	<cfset bSuperUser = false>
	
	<cfif len(url.username)>
		
		<!--- note: can't suspend or expire super users at the moment --->
		<cfquery name="qCheckSuper" datasource="#request.speck.codb#">
			SELECT accessor 
			FROM spRolesAccessors 
			WHERE rolename = 'spSuper'
				AND accessor IN ( SELECT groupname FROM spUsersGroups WHERE username = '#url.username#' )
		</cfquery>
		
		<cfif qCheckSuper.recordCount>
		
			<cfset bSuperUser = true>
		
		</cfif>
			
	</cfif>

	<cfoutput>
	<tr>
	<td style="vertical-align:middle" nowrap="yes"><label for="suspended"><span class="hint" onmouseover="return escape('Set status to suspended to prevent a user from logging in without deleting them.');">Account Status</span></label></td>
	<td style="vertical-align:middle" colspan="2">
		<input type="radio" name="suspended" value="0"<cfif not form.suspended> checked="yes"</cfif><cfif bSuperUser> disabled="yes"</cfif> />Active
		<input type="radio" name="suspended" value="1"<cfif form.suspended> checked="yes"</cfif><cfif bSuperUser> disabled="yes"</cfif> />Suspended
	</td>
	<td style="vertical-align:middle" nowrap="yes"><label for="expires"><span class="hint" onmouseover="return escape('Set an expiry date for this account to prevent a user logging in from that date forward.');">Account Expires</span></label></td>
	<td style="vertical-align:middle" colspan="2">
		<input type="text" name="expires" value="#form.expires#" <cfif bSuperUser> disabled="yes"</cfif> onfocus="if (this.value == 'YYYY-MM-DD' ) { this.value='' };" size="14" maxlength="10" style="vertical-align:middle;">
		<a href="javascript:return false;" 
			<cfif bSuperUser>
				onclick="alert('Cannot set expiration date for user account with spSuper role');return false;"	
			<cfelse>
				onclick="openCalendar(event,'expires');return false;"
			</cfif>
			title="#request.speck.buildString("P_DATE_CALENDAR_CAPTION")#"><img src="/speck/properties/date/calendar_blue.gif" border="0" style="vertical-align:middle;"></a>
	</td>
	</tr>
</table>
</fieldset>
</cfoutput>

<!--- <cfif fileExists(expandPath("subscriptions.cfm"))>

	<cfinclude template="subscriptions.cfm">

</cfif> --->

<cfoutput>
<fieldset>
<legend>Group Membership</legend>
<table border="0" cellpadding="0" cellspacing="0" width="100%">
	<tr>
	<td width="45%">Available<br />
		<select name="groups_from" multiple="multiple" size="5" style="width:100%;">
		</cfoutput>
					
		<cfloop query="qGroups">
			
			<cfif not listFind(form.groups,groupname)>
				
				<cfoutput><option value="#groupname#">#groupname#</option></cfoutput>
				
			</cfif>
	
		</cfloop>
				
		<cfoutput>
		</select>
	</td>
	<td width="10%" style="vertical-align:middle;text-align:center;"><br />
		<input class="button" name="groups_right" value="&gt;&gt;" onclick="moveSelectedOptions(this.form['groups_from'],this.form['groups'],true);" type="button"><br />
		<input class="button" name="groups_left" value="&lt;&lt;" onclick="moveSelectedOptions(this.form['groups'],this.form['groups_from'],true);cleanupGroups();" type="button">
	</td>
	<td width="45%">Selected<br />
		<select name="groups" multiple="multiple" size="5" style="width:100%;" ondblclick="setExpirationDate();">
		</cfoutput>
		
		<cfloop query="qGroups">
			
			<cfif listFind(form.groups,groupname)>
				
				<cfoutput><option value="#groupname#">#groupname#<cfif structKeyExists(stGroupsExpiration,groupname) and trim(stGroupsExpiration[groupname]) neq ""> (expire<cfif stGroupsExpiration[groupname] lt now()>d<cfelse>s</cfif> #dateFormat(stGroupsExpiration[groupname],"YYYY-MM-DD")#)</cfif></option></cfoutput>
				
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
	<input class="button" type="submit" value="Save Changes" />&nbsp;&nbsp;
	<input class="button" type="button" value="Cancel" onclick="javascript:window.location.href='#return_to#';" />
	</td>
	</tr>
</table>
</form>
</cfoutput>
		
<cfinclude template="footer.cfm">

