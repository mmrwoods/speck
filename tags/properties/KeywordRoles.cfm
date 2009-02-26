<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- 
Note: uses some strings from simplepicker property type
--->

<cf_spPropertyHandler>


	<cf_spPropertyHandlerMethod method="renderFormField">
	
		<cfset size = 3>
		
		<cfparam name="stPD.defaultValue" default="">
		<cfscript>
			selectedValues = value;
			if ( not len(selectedValues) and len(stPD.defaultValue) and ( action eq "add" and cgi.request_method neq "post" ) ) {
				selectedValues = stPD.defaultValue;
			}
		</cfscript>
		
		<!--- nab a copy of the security zones for the app --->
		<cflock scope="application" timeout="3" type="READONLY">
		<cfset stSecurityZones = duplicate(application.speck.securityZones)>
		</cflock>
	
		<cfset lAllRoles = ""> <!--- we'll need a list of all roles to loop over --->
		
		<!--- get the list of roles for each security zone and append to list of all roles --->
		<cfloop list="#structKeyList(stSecurityZones)#" index="zone">
		
			<cfif structKeyExists(stSecurityZones[zone],"roles")>
			
				<cfif stSecurityZones[zone].roles.options.source eq "file">
				
					<!--- get a list of all the roles in the file --->
					<cfset lRoles = structKeyList(stSecurityZones[zone].roles.file)>		
					
				<cfelse>
					
					<!--- query user database to get list of roles --->
					<cfparam name="stSecurityZones[zone].roles.database.datasource" default="#request.speck.codb#">
					<cfparam name="stSecurityZones[zone].roles.database.username" default="">
					<cfparam name="stSecurityZones[zone].roles.database.password" default="">
					<cfparam name="stSecurityZones[zone].roles.database.dbtype" default="">
					
					<cfset sql = stSecurityZones[zone].roles.database.roleslist>
					
					<cfif stSecurityZones[zone].roles.database.dbtype eq "query">
					
						<!--- check if we need to use a scoped lock when executing the query --->
						<cfset stQueryScope = REFindNoCase("FROM[[:space:]]+((Server|Application|Session)\.)",sql,1,true)>
						
						<cfif arrayLen(stQueryScope.pos) eq 3>
						
							<cfset lockScope = mid(sql,stQueryScope.pos[3],stQueryScope.len[3])>
						
							<cflock type="readonly" scope="#lockScope#" timeout="3">
							<cfquery name="qRoles" dbtype="query">
							
								#preserveSingleQuotes(sql)#
							
							</cfquery>
							</cflock>
							
						<cfelse>
						
							<cfquery name="qRoles" dbtype="query">
							
								#preserveSingleQuotes(sql)#
							
							</cfquery>
						
						</cfif>
					
					<cfelse>
					
						<cfquery name="qRoles" datasource="#stSecurityZones[zone].roles.database.datasource#" username="#stSecurityZones[zone].roles.database.username#" password="#stSecurityZones[zone].roles.database.password#">
						
							#preserveSingleQuotes(sql)#
						
						</cfquery>
						
					</cfif>
					
					<cfset lRoles = valueList(qRoles.role)>			
				
				</cfif>
			
				<!--- append roles for this security zone to all roles --->
				<cfscript>
					lNewRoles = "";
					for ( i=1; i lte listLen(lRoles); i=i+1 ) {
						role = listGetAt(lRoles,i);
						if ( not listFindNoCase(lAllRoles,role) ) {
							lNewRoles = listAppend(lNewRoles,role);
						}
					}
					lAllRoles = listAppend(lAllRoles,lNewRoles);
				</cfscript>
			
			</cfif>
			
			<cfscript>
				// remove speck reserved roles from roles list (keyword roles are only set when you want to grant additional premission to managing content to custom roles)
				lSpeckRoles = "spEdit,spLive,spSuper,spUsers,spKeywords";
				for ( i=1; i lte listLen(lSpeckRoles); i=i+1 ) {
					role = listGetAt(lSpeckRoles,i);
					position = listFindNoCase(lAllRoles,role);
					if ( position gt 0 ) {
						lAllRoles = listDeleteAt(lAllRoles,position);
					}
				}
			</cfscript>
			
		</cfloop>
	
		<cfoutput>
		<script type="text/javascript">
			// Modified versions of selectbox functions by Matt Kruse <matt@mattkruse.com>
			// Check out his JavaScript toolbox at http://www.mattkruse.com/
			
			#stPD.name#_modified = false; // set to true if value changed (any options moved)
			
			function hasOptions_#stPD.name#(obj) {
				if (obj!=null && obj.options!=null) { return true; }
				return false;
			}
			
			function moveSelectedOptions_#stPD.name#(from,to) {
				// Move them over
				if (!hasOptions_#stPD.name#(from)) { return; }
				for (var i=0; i<from.options.length; i++) {
					var o = from.options[i];
					if (o.selected) {
						if (!hasOptions_#stPD.name#(to)) { var index = 0; } else { var index=to.options.length; }
						to.options[index] = new Option( o.text, o.value, false, false);
					}
				}
				// Delete them from original
				for (var i=(from.options.length-1); i>=0; i--) {
					var o = from.options[i];
					if (o.selected) {
						from.options[i] = null;
					}
				}
				if ((arguments.length<3) || (arguments[2]==true)) {
					sortSelect_#stPD.name#(from);
					sortSelect_#stPD.name#(to);
				}
				from.selectedIndex = -1;
				to.selectedIndex = -1;
				
				// update modified flag
				#stPD.name#_modified = true;
			}
			
			function sortSelect_#stPD.name#(obj) {
				var o = new Array();
				if (!hasOptions_#stPD.name#(obj)) { return; }
				for (var i=0; i<obj.options.length; i++) {
					o[o.length] = new Option( obj.options[i].text, obj.options[i].value, obj.options[i].defaultSelected, obj.options[i].selected) ;
				}
				if (o.length==0) { return; }
				o = o.sort( 
					function(a,b) { 
						if ((a.text+"") < (b.text+"")) { return -1; }
						if ((a.text+"") > (b.text+"")) { return 1; }
						return 0;
					} 
				);
			
				for (var i=0; i<o.length; i++) {
					obj.options[i] = new Option(o[i].text, o[i].value, o[i].defaultSelected, o[i].selected);
				}
			}
			
			function selectAllOptions_#stPD.name#(obj) {
				if (!hasOptions_#stPD.name#(obj)) { return; }
				for (var i=0; i<obj.options.length; i++) {
					obj.options[i].selected = true;
				}
			}
			
			// add selectAllOptions() to form onsubmit
			if ( document.speditform.onsubmit ) 
				otherOnSubmit_#stPD.name# = document.speditform.onsubmit;
			else 
				otherOnSubmit_#stPD.name# = new Function;
			document.speditform.onsubmit = function() {
												selectAllOptions_#stPD.name#(document.speditform.#stPD.name#);
												<cfif isDefined("request.bKeywordHasChildren") and request.bKeywordHasChildren>
													if ( #stPD.name#_modified && document.speditform.#stPD.name#_force_permissions.value != 1 ) {
														// permissions changed, ask user whether changes should be forced to children
														if ( confirm("Update permissions for all sub-sections?\n\nHighly recommended, if unsure, click yes/ok.") ) {
															document.speditform.#stPD.name#_force_permissions.value = 1;
														}
													}
												</cfif>
												otherOnSubmit_#stPD.name#();
											};
		</script>
		<input type="hidden" name="#stPD.name#_force_permissions" value="0" />
		<table border="0" cellpadding="0" cellspacing="0" width="100%">
		<tr>
		<td width="45%">#request.speck.buildString("P_SIMPLEPICKER_AVAILABLE")#<br />
			<select name="#stPD.name#_from" multiple="multiple" size="#size#" style="width:100%;">
			</cfoutput>
			
			<cfloop list="#lCase(lAllRoles)#" index="i">
				
				<cfif not listFindNoCase(selectedValues,i)>
					
					<cfoutput><option value="#i#">#i#</option></cfoutput>
					
				</cfif>
	
			</cfloop>
					
			<cfoutput>
			</select>
		</td>
		<td width="10%" style="vertical-align:middle;text-align:center;"><br />
			<input class="button" name="#stPD.name#_right" value="&gt;&gt;" onclick="moveSelectedOptions_#stPD.name#(this.form['#stPD.name#_from'],this.form['#stPD.name#'],true);" type="button"><br />
			<input class="button" name="#stPD.name#_left" value="&lt;&lt;" onclick="moveSelectedOptions_#stPD.name#(this.form['#stPD.name#'],this.form['#stPD.name#_from'],true)" type="button">
		</td>
		<td width="45%">#request.speck.buildString("P_SIMPLEPICKER_SELECTED")#<br />
			<select name="#stPD.name#" multiple="multiple" size="#size#" style="width:100%;">
			</cfoutput>
			
			<cfloop list="#lCase(lAllRoles)#" index="i">
				
				<cfif listFindNoCase(selectedValues,i)>
					
					<cfoutput><option value="#i#">#i#</option></cfoutput>
					
				</cfif>
	
			</cfloop>
					
			<cfoutput>
			</select>
		</td>
		</tr>
		</table>
		</cfoutput>

	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="contentPut">
		
		<cfif structKeyExists(form,"keyword")>
		
			<cfparam name="form.#stPD.name#_force_permissions" default="0">
			
			<cfif not request.speck.userHasPermission("spSuper")>
				
				<!--- if a non-super user is adding a keyword, we need to set the role to that of the parent --->
				<cfquery name="qKeyword" datasource="#request.speck.codb#">
					SELECT * FROM spKeywords WHERE spId = '#id#'
				</cfquery>
	
				<cfif not qKeyword.recordCount and listLen(form.keyword,".") gt 1>
				
					<cfset parent = listDeleteAt(form.keyword,listLen(form.keyword,"."),".")>
					
					<cfquery name="qParent" datasource="#request.speck.codb#">
						SELECT * FROM spKeywords WHERE keyword = '#parent#'
					</cfquery>
					
					<cfset newValue = qParent.roles>
	
				</cfif>
	
			<cfelseif evaluate("form.#stPD.name#_force_permissions")> <!--- note: using evaluate rather than simply form[] syntax because I can't recall if the latter will work in CF5 and I haven't time to go testing --->
	
				<cfquery name="qUpdate" datasource="#request.speck.codb#">
					UPDATE spKeywords 
					SET #stPD.name# = '#newValue#'
					WHERE keyword = '#form.keyword#' OR keyword LIKE '#form.keyword#.%' <!--- durty frickin' hack ---> 
				</cfquery>
				
				<!--- update application.speck.qKeywords and application.speck.keywords --->
				<cfquery name="request.speck.qKeywords" datasource="#request.speck.codb#">
					SELECT * FROM spKeywords ORDER BY sortId, keyword
				</cfquery>
				<cfscript>
					request.speck.keywords = structNew();
					for(i=1; i le request.speck.qKeywords.recordCount; i = i + 1) {
						structInsert(request.speck.keywords, request.speck.qKeywords.keyword[i], request.speck.qKeywords.roles[i]);
					}
				</cfscript>
				<cflock scope="application" timeout="5" type="exclusive">
				<cfset application.speck.keywords = duplicate(request.speck.keywords)>
				<cfset application.speck.qKeywords = duplicate(request.speck.qKeywords)>
				</cflock>
				
			</cfif>
		
		</cfif>
		
	</cf_spPropertyHandlerMethod>
	
	
</cf_spPropertyHandler>
