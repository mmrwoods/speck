<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spType
	name="spDefault"
	description="Default methods">
	

	<cf_spHandler method="display">
	
		<cfdump var="#content#">
	
	</cf_spHandler>
	
	
	<cf_spHandler method="picker">
	
		<cfoutput>
		ID: #content.spId#, #request.speck.buildString("T_DEFAULT_EDIT_REVISION_CAPTION")# #content.spRevision#<br />
		#request.speck.buildString("T_DEFAULT_EDIT_CREATED_CAPTION")#: #dateformat(content.spCreated, "yyyy-mm-dd")# #content.spCreatedby#,
		#request.speck.buildString("T_DEFAULT_EDIT_UPDATED_CAPTION")#: #dateformat(content.spUpdated, "yyyy-mm-dd")# #content.spUpdatedby#<br />
		#request.speck.buildString("T_DEFAULT_EDIT_LABEL_CAPTION")#: #content.spLabel#<br />
		#request.speck.buildString("T_DEFAULT_EDIT_KEYWORDS_CAPTION")#: #content.spKeywords#
		</cfoutput>
		
	</cf_spHandler>
	
	
	<cf_spHandler method="help">
	
		<!--- no generic system wide help page at the moment - override this method to create custom help pages for your content types --->
	
	</cf_spHandler>
	
	
	<cf_spHandler method="spEdit">

		<cfparam name="url.cacheList" default="">
		<cfparam name="url.action" default="edit">
		
		<cfoutput>
		<span id="loading" style="position:absolute;z-index:87655234;top:2px;left:2px;visibility:visible;vertical-align:middle;">Loading...</span>
		</cfoutput>

		<!--- Get type information --->
		<cfmodule template=#request.speck.getTypeTemplate(attributes.type)# r_stType="stType">
		
		<cflock scope="session" type="readonly" timeout="3" throwontimeout="yes">
		<cfset bSessionEdit = structKeyExists(session.speck.roles,"spEdit")>
		</cflock>
		
		<cfscript>
			lFormErrors = ""; // List of errors on submitted form
			stNewContent = structNew(); // Submitted values
			
			bSuper = request.speck.userHasPermission("spSuper"); 
			bEdit = request.speck.userHasPermission("spEdit");
			bLive = request.speck.userHasPermission("spLive");
			
			// localised user-interface strings
			stStrings = structNew();
			stStrings.details = request.speck.buildString("T_DEFAULT_EDIT_DETAILS_CAPTION");
			stStrings.label = request.speck.buildString("T_DEFAULT_EDIT_LABEL_CAPTION");
			stStrings.keywords = request.speck.buildString("T_DEFAULT_EDIT_KEYWORDS_CAPTION");
			stStrings.help = request.speck.buildString("T_DEFAULT_EDIT_HELP_CAPTION");
			stStrings.hint = request.speck.buildString("T_DEFAULT_EDIT_HINT_CAPTION");
			stStrings.revision = request.speck.buildString("T_DEFAULT_EDIT_REVISION_CAPTION");
			stStrings.created = request.speck.buildString("T_DEFAULT_EDIT_CREATED_CAPTION");
			stStrings.updated = request.speck.buildString("T_DEFAULT_EDIT_UPDATED_CAPTION");
			stStrings.saveChanges = request.speck.buildString("T_DEFAULT_EDIT_SAVE_CAPTION");
			stStrings.closeWindow = request.speck.buildString("T_DEFAULT_EDIT_CLOSE_CAPTION");
			stStrings.notSaved = request.speck.buildString("T_DEFAULT_EDIT_NOT_SAVED");

			// build access control struct from roles property attributes...
			stPropRoles = structNew();
			
			// role permissions for accessing and modifying spLabel
			if ( structKeyExists(stType,"labelRoles") )
				stPropRoles.spLabel = trim(stType.labelRoles);
			else if ( structKeyExists(request.speck,"labelRoles") )
				stPropRoles.spLabel = trim(request.speck.labelRoles);
			else
				stPropRoles.spLabel = "";
			
			// role permissions for accessing and modifying spKeywords
			if ( structKeyExists(stType,"keywordsRoles") )
				stPropRoles.spKeywords = trim(stType.keywordsRoles);
			else if ( structKeyExists(request.speck,"keywordsRoles") )
				stPropRoles.spKeywords = trim(request.speck.keywordsRoles);
			else
				stPropRoles.spKeywords = "";
			
			// role permissions for accessing and modifying other properties
			for(i=1; i le arrayLen(stType.props); i = i + 1)
				if ( structKeyExists(stType.props[i],"roles") )
					structInsert(stPropRoles,stType.props[i].name,trim(stType.props[i].roles));
				else
					structInsert(stPropRoles,stType.props[i].name,"");
					
			stAccess = structNew();
			lPropsNoWriteAccess = ""; // we'll populate this with a list of property names which the user doesn't have write access to
			if ( bSuper ) {
				for ( prop in stPropRoles ) {
					"stAccess.#prop#" = structNew();			
					"stAccess.#prop#.read" = true;
					"stAccess.#prop#.write" = true;	
				}	
			} else {
				for ( prop in stPropRoles ) {
					"stAccess.#prop#" = structNew();
					if ( len(stPropRoles[prop]) ) {
						readRoles = "";
						writeRoles = "";
						for(i=1; i le listLen(stPropRoles[prop]); i = i + 1) {
							roleValue = listGetAt(stPropRoles[prop],i);
							roleName = trim(REReplace(roleValue,"[\=\+\-].*$",""));
							if ( find("=",roleValue) )
								propPermissions = lCase(listLast(roleValue,"="));
							else {
								propPermissions = "rw"; // default permissions
								if ( find("-",roleValue) ) {
									// have to deny some permissions (above condition only there to avoid running REFindNoCase() unnecessarily)
									if ( REFindNoCase("\-[^\+]*r",roleValue) )
										// remove read permission...
										propPermissions = replace(propPermissions,"r","");
									if ( REFindNoCase("\-[^\+]*w",roleValue) ) 
										// remove write permission...
										propPermissions = replace(propPermissions,"w","");
								}
							}
							if ( find("r",propPermissions) )
								readRoles = listAppend(readRoles,roleName);
							if ( find("w",propPermissions) )
								writeRoles = listAppend(writeRoles,roleName);
						}
						"stAccess.#prop#.read" = ( len(readRoles) and request.speck.userHasPermission(readRoles) );
						if ( len(writeRoles) and request.speck.userHasPermission(writeRoles) )
							"stAccess.#prop#.write" = true;
						else {
							lPropsNoWriteAccess = listAppend(lPropsNoWriteAccess,prop);
							"stAccess.#prop#.write" = false;
						}
					} else {
						"stAccess.#prop#.read" = true;
						"stAccess.#prop#.write" = true;				
					}
				}
			}
			
			// never allow the label and keywords be edited when content type is spKeywords or when user has 
			// only been granted temporary edit rights for this request (we don't want them moving content) 
			if ( attributes.type eq "spKeywords" or ( not bSuper and not bSessionEdit ) ) {
				stAccess.spLabel.read = false;
				stAccess.spLabel.write = false;
				stAccess.spKeywords.read = false;
				stAccess.spKeywords.write = false;
			}
		
		</cfscript>
		
		<!--- If form submitted, Read and validate form fields --->
		
		<cfif isDefined("form.spId")>
		
			<cfloop from=1 to="#arrayLen(stType.props)#" index="iProp">

				<cfset stPD = stType.props[iProp]>
				
				<!--- <cfif isDefined("form.#stPD.name#") and stPD.type neq "Asset">
				
					<cfset value = evaluate("form.#stPD.name#")>
				
				<cfelse>
					
					<cfset value = content[stPD.name]>
					
				</cfif> --->
				
				<cfparam name="form.#stPD.name#" default="">
				
				<cfif stPD.type eq "Asset">
					
					<cfset value = content[stPD.name]>
				
				<cfelse>
					
					<cfset value = evaluate("form.#stPD.name#")>
					
				</cfif>
				
				<!--- If form submitted, Read and validate form fields --->
				<cfif listFindNoCase(lPropsNoWriteAccess,stPD.name)>
				
					<!--- user does not have write access to this property, use existing value --->
					<cfset "stNewContent.#stPD.name#" = content[stPD.name]>
					
				<cfelse>

					<!--- <cftry> --->
				
						<cfmodule template=#request.speck.getPropertyHandlerTemplate(stPD,"readFormField")#
							method="readFormField"
							action="#url.action#"
							stPD=#stPD#
							id=#content.spId#
							revision=#content.spRevision#
							value=#value#
							r_newValue="stNewContent.#stPD.name#">
							
						<cfmodule template=#request.speck.getPropertyHandlerTemplate(stPD,"validateValue")#
							method="validateValue"
							stPD=#stPD#
							id=#content.spId#
							revision=#content.spRevision#
							value=#value#
							newValue=#stNewContent[stPD.name]#
							r_lErrors ="lPropertyErrors">
							
						<cfset lFormErrors = listAppend(lFormErrors, lPropertyErrors)>
						
					<!--- <cfcatch>
					
						<cfif len(trim(evaluate("form.#stPD.name#")))>
						
							<!--- this dirty code assumes that any errors reading a form field will be due an unsupported image type (was I asleep when I wrote this? I need to come back and sort this mess out!) --->
							<cfset lFormErrors = listAppend(lFormErrors,"#stPD.caption# file could not be saved due to an 'Unsupported Image Type' error. Please open the file you are trying to upload in an image editing program on your computer&##44; save a copy of the file in JPEG format and try uploading the new copy.")>
							
						</cfif>
					
					</cfcatch>
					</cftry> --->
				
				</cfif>		
				
			</cfloop>

			<!--- Read and validate common form fields --->
			<cfparam name="form.spKeywords" default=""> <!--- added because if user selects nothing in select multiple, form name/value pair not sent --->
			<cfparam name="form.spLabel" default="">
			<cfscript>
				// id never changes
				stNewContent.spId = trim(content.spId);
			
				// get label, if user has no wite access to label, set to existing value
				if ( listFindNoCase(lPropsNoWriteAccess,"spLabel") )
					stNewContent.spLabel = content.spLabel;
				else
					stNewContent.spLabel = REReplace(htmlEditFormat(form.spLabel),"&amp;(##*[A-Za-z0-9]+;)","&\1","all");
					
				// get keywords, if user has no wite access to keywords, set to existing value
				if ( listFindNoCase(lPropsNoWriteAccess,"spKeywords") )
					stNewContent.spKeywords = content.spKeywords;
				else {
					stNewContent.spKeywords = "";
					formKeywords = listChangeDelims(form.spKeywords, ",", chr(10) & chr(13) & ",;"); // need to accept barf from possible textarea
					formKeywords = REReplace(formKeywords,"[\,]+",",","all"); // replace multiple commas with single
					formKeywords = listSort(formKeywords, "TEXTNOCASE");
					if ( bSuper or structIsEmpty(request.speck.keywords) )
						lKeywords = formKeywords;
					else {
						// check user has permission to use each keyword...
						lKeywords = "";
						for(i=1; i le listLen(formKeywords); i = i + 1) {
							keyword = listGetAt(formKeywords,i);
							if ( not structKeyExists(request.speck.keywords,keyword) or not len(trim(request.speck.keywords[keyword])) or listFindNoCase(content.spKeywords,keyword) or request.speck.userHasPermission(request.speck.keywords[keyword]) )
								lKeywords = listAppend(lKeywords,keyword);
						}
					}
					if ( len(stType.keywordFilter) ) {
						for(i=1; i le listLen(lKeywords); i = i + 1) {
							keyword = listGetAt(lKeywords,i);
							if ( findNoCase(stType.keywordFilter, keyword) eq 1 )
								stNewContent.spKeywords = listAppend(stNewContent.spKeywords, keyword);
						}
					} else 
						stNewContent.spKeywords = lKeywords;
				}
				
				// show error if label is required and value is empty				
				if ( stType.labelRequired and stNewContent.spLabel eq "") 
					lFormErrors = listAppend(lFormErrors, request.speck.buildString("A_PROPERTY_REQUIRED",stStrings.label));	
									
				// show error if keywords are required and value is empty
				if ( stType.keywordsRequired and stNewContent.spKeywords eq "" )
					lFormErrors = listAppend(lFormErrors, request.speck.buildString("A_PROPERTY_REQUIRED",stStrings.keywords));		
			</cfscript>
			
			<!--- If no errors, save new values and reload from database --->
			
			<cfif len(lFormErrors)>
			
				<!--- error in form submission - content not saved, copy values from form to 
				content struct so user does not lose additions / modifications to content item --->
				
				<cfscript>
					// get a list of asset propeties for this content type. We don't want to update the 
					// related key in the content struct with the form value where the property type is
					// asset because the form value will be a path to a temp file
					lAssetProps = "";
					for(i=1; i le arrayLen(stType.props); i = i + 1)
						if ( stType.props[i].type eq "asset" )
							lAssetProps = listAppend(lAssetProps,stType.props[i].name);
					
					for ( key in content )
						if ( isDefined("form." & key) )
							if ( not listFindNoCase(lAssetProps,key) )
								content[key] = form[key];
							else if ( REFind("\.tmp$",content[key]) )
								content[key] = ""; // hack to ignore tmp files created during upload
				</cfscript>	
				
				<!--- delete any tmp files that, due to the form submission errors, haven't made it to their final destinations --->
				<cfset fs = request.speck.fs>
				<cfdirectory action="LIST" 
					directory="#request.speck.appInstallRoot##fs#tmp" 
					filter="#stNewContent.spId#_*" 
					sort="type DESC" 
					name="qTmpFiles">
					
				<cfloop query="qTmpFiles">
				
					<cftry>
						<cffile action="delete" file="#request.speck.appInstallRoot##fs#tmp#fs##qTmpFiles.name#">
					<cfcatch><!--- do nothing ---></cfcatch>
					</cftry>
					
				</cfloop>			
			
			<cfelse>

				<cf_spDebug msg="No errors on form - calling contentPut">
				<cf_spContentPut
					stContent = #stNewContent#
					type=#attributes.type# 
					changeId="spSystem">			
					
				<cf_spDebug msg="Calling contentGet to populate edit form from database">
				<cf_spContentGet
					r_qContent="qContent"
					type=#attributes.type#
					id=#stNewContent.spId#
					bEdit="yes">
					
				<cfscript>
				
					for (key in content)
						if (isDefined("qContent." & key))
							content[key] = qContent[key][1];

				</cfscript>
				
				<cfif request.speck.session.viewLevel eq "live">
				
					<!--- reset cache on opener --->
					<cfoutput>
						<script type="text/javascript">
							if ( window.opener && !window.opener.closed ) {
								if ( window.opener.resetCache ) {
									window.opener.resetCache("#urlEncodedFormat(url.cacheList)#");
								} else {
									<cfif isDefined("url.picker_fieldname")>
										<cfif isDefined("url.id")>
											<!--- edited an existing item - update selection --->
											opener.picker_edit_update_#url.picker_fieldname#();
										<cfelse>
											<!--- added a new item - add to selection --->
											opener.picker_add_#url.picker_fieldname#('#stNewContent.spId#');
										</cfif>
									<cfelse>
										// reload opener window - use replace rather than reload to avoid reposting forms
										if ( window.opener.location.pathname != "#cgi.script_name#" ) { // avoid reloading the admin windows, it's only the base window we want to reload
											window.opener.location.replace(window.opener.location.href);
										} 
									</cfif>
								}
							}
						</script>
					</cfoutput>
				
				<cfelse>
				
					<!--- reload opener --->
					<cfoutput>
						<script type="text/javascript">
							if ( window.opener && !window.opener.closed ) {
								if ( window.opener.refresh ) {
									window.opener.refresh();
								} else {
									<cfif isDefined("url.picker_fieldname")>
										<cfif isDefined("url.id")>
											<!--- edited an existing item - update selection --->
											opener.picker_edit_update_#url.picker_fieldname#();
										<cfelse>
											<!--- added a new item - add to selection --->
											opener.picker_add_#url.picker_fieldname#('#stNewContent.spId#');
										</cfif>
									<cfelse>
										// reload opener window - use replace rather than reload to avoid reposting forms
										if ( window.opener.location.pathname != "#cgi.script_name#" ) { // avoid reloading the admin windows, it's only the base window we want to reload
											window.opener.location.replace(window.opener.location.href);
										}
									</cfif>
								}
							}
						</script>
					</cfoutput>
				
				</cfif>
				
				<!--- <cfset url.action = "edit"> --->
				
				<!---
				arse, can't do this because the javascript won't get called
				<cflocation url="#cgi.script_name#?#replace(cgi.query_string,"action=add","action=edit")#" addToken="no">
				<cfabort>
				--->
				<cfif url.action eq "add">
					<cfset newLocation = cgi.script_name & "?id=" & form.spId & "&" & replace(cgi.query_string,"action=add","action=edit")>
				<cfelse>
					<cfset newLocation = cgi.script_name & "?" & cgi.query_string>
				</cfif>
				<cfhtmlhead text='<meta http-equiv="refresh" content="0;url=#newLocation#" />'>
				<cfoutput>
				<script type="text/javascript">
					if ( window.onload ) 
						otherOnLoad_spDefault = window.onload;
					else 
						otherOnLoad_spDefault = new Function;
					window.onload = function() {
										window.location.href= "#newLocation#";
										otherOnLoad_spDefault();
									};
				</script>
				</body>
				</html>
				</cfoutput>
				<cfabort>
					
			</cfif>
			
		</cfif>
		
		<!--- output link to help if help method exists for type (at the moment these is no generic help page) --->
		
		<cfif structKeyExists(stType.methods, "help")>
		
			<cfoutput>
			<script language="JavaScript">
			
				function launch_help_#attributes.type#() {
					var win = window.open("/speck/admin/help.cfm?type=#attributes.type#&id=#trim(content.spId)#&app=#request.speck.appname#", "help", "menubar=no,scrollbars=yes,resizable=yes,width=500,height=500,screenX=200,screenY=100,left=200,top=100");
					win.focus();
				}	
			
			</script>
			<div align="right"><a href="javascript:launch_help_#attributes.type#();" style="cursor:help;">#stStrings.help#</a></div>
			</cfoutput>
		
		</cfif>
		
		<!--- Output the form header --->
		<cfoutput>
		<form autocomplete="off" name="speditform" id="speditform" action="#cgi.script_name#?#reReplace(cgi.query_string,"action=[a-z]+","action=" & url.action)#" enctype="multipart/form-data" method="post">
		<table>
		</cfoutput>
		
		<!--- add opener url to querystring if necessary --->
		<cfif not isDefined("url.openerUrl")>

			<cfoutput>
			<script type="text/javascript">
				try {
					if ( window.opener.opener && !window.opener.opener.closed ) 
						document.speditform.action = document.speditform.action + "&openerurl=" + escape(window.opener.opener.location.href);
					else if ( window.opener && !window.opener.closed )
						document.speditform.action = document.speditform.action + "&openerurl=" + escape(window.opener.location.href);
				} catch (e) {
					 // do nothing
				}
			</script>	
			</cfoutput>		
		
		</cfif>	
		
		<cfif lFormErrors neq "">
		
			<!--- List the errors at the top of the form --->
			
			<cfoutput><p class="notsaved">#stStrings.notSaved#:</p><ul class="notsaved"></cfoutput>
			
			<cfloop list=#lFormErrors# index="error">
			
				<cfoutput><li>#error#</li></cfoutput>
				
			</cfloop>
			
			<cfoutput></ul></cfoutput>
			
		</cfif>	
		
		<!--- Render type specific form fields --->
		
		<cfloop from=1 to="#arrayLen(stType.props)#" index="iProp">
			
			<cfset stPD = stType.props[iProp]>
			<cfset displayValue = content[stPD.name]>
	
			<cfif stAccess[stPD.name].read>
				
				<cfif stPD.displaySize eq 0>
				
					<cfif stPD.type eq "Asset">
						<cfoutput><input type="hidden" name="#stPD.name#" value=""></cfoutput>
					<cfelseif stPD.type eq "DateTime" and len(displayValue)>
						<cfoutput><input type="hidden" name="#stPD.name#" value="#dateFormat(displayValue,"YYYY-MM-DD")# #timeFormat(displayValue,"HH:MM")#"></cfoutput>
					<cfelse>
						<cfoutput><input type="hidden" name="#stPD.name#" value="#replace(displayValue,"""","&quot;","all")#"></cfoutput>
					</cfif>
					
				<cfelseif stPD.type eq "fieldset"> 
				
					<!--- When is a hack a kludge? When it's like this... ;-) --->
				
					<!--- just render the form field --->
					<cfmodule template=#request.speck.getPropertyHandlerTemplate(stPD,"renderFormField")#
						method="renderFormField"
						stPD=#stPD#
						id=#content.spId#
						revision=#content.spRevision#
						value=#displayValue#>	
				
				<cfelse>
						
					<cfoutput>
					<tr <cfif len(stPD.class)>class="#stPD.class#"</cfif> <cfif len(stPD.style)>style="#stPD.style#"</cfif>>
					<td style="padding-top:5px;" width="60"></cfoutput>
					
					<cfif stPD.required><cfoutput><span class="required">*</span></cfoutput></cfif>
					
					<cfoutput>#stPD.caption#</cfoutput>
					
					<cfif isDefined("stPD.hint") and len(stPD.hint)>
					
						<cfoutput>&nbsp;<span class="hint" onmouseover="return escape('#jsStringFormat(stPD.hint)#');"><!--- ? ---></span>&nbsp;</cfoutput>

					</cfif>

					<cfoutput>
					</td>
					<td>
					</cfoutput>
					
					<cfif stAccess[stPD.name].write>
					
						<cfmodule template=#request.speck.getPropertyHandlerTemplate(stPD,"renderFormField")#
							method="renderFormField"
							stPD=#stPD#
							id=#content.spId#
							revision=#content.spRevision#
							value=#displayValue#
							action="#url.action#">					
					
					<cfelse>
						
						<cfif stPD.type eq "Asset">
							<cfoutput>#displayValue#<input type="hidden" name="#stPD.name#" value=""></cfoutput>
						<cfelse>
							<cfoutput>#displayValue#<input type="hidden" name="#stPD.name#" value="#replace(displayValue,"""","&quot;","all")#"></cfoutput>
						</cfif>
						
					</cfif>
						
					<cfoutput>
					</td>
					</tr>
					</cfoutput>
		
				</cfif>
				
			</cfif>
			
		</cfloop>
		
		<!--- hide the loading indicator when the page has fully loaded --->
		<cfoutput>
		<script type="text/javascript">
			if ( window.onload ) 
				otherOnLoad_spDefault = window.onload;
			else 
				otherOnLoad_spDefault = new Function;
			window.onload = function() {
								$('loading').style.visibility = 'hidden';							
								otherOnLoad_spDefault();
							};
		</script>
		</cfoutput>
		
		<!--- Render common form fields --->
		
		<cfoutput>
		<tr><td colspan="2">&nbsp;</td></tr>
		<tr><td colspan="2"></td></tr>
		</table>
		<table width="100%" border="0" cellpadding="5">
			<tr>
			<td align="right" style="vertical-align:middle;">
			<cfif request.speck.session.viewLevel neq "review">
				<span id="saving" style="vertical-align:middle;visibility:hidden;">Saving...</span>
				<input class="button" type="submit" value="#stStrings.saveChanges#" style="vertical-align:middle;" onclick="this.disabled=true;$('saving').style.visibility='visible';if (this.form.onsubmit) {this.form.onsubmit();};this.form.submit();">
			</cfif>
			<input class="button" type="button" value="#stStrings.closeWindow#" style="vertical-align:middle;" onclick="window.close()">
			</td>
			</tr>
		</table>
		<hr>
		<input type="Hidden" name="spId" value="#trim(content.spId)#">
		<table width="100%">
			<tr>
				<td width="60">#stStrings.details#</td>
				<td>ID: #content.spId# #stStrings.revision# #content.spRevision#</td>
			</tr>
			<tr>
				<td width="60">&nbsp;</td>
				<td>#stStrings.created#: #dateformat(content.spCreated, "yyyy-mm-dd")# #content.spCreatedby#
					#stStrings.updated#: #dateformat(content.spUpdated, "yyyy-mm-dd")# #content.spUpdatedby#</td>
			</tr>
			</cfoutput>
			
		
			<cfif stAccess.spLabel.read>
				
				<cfif len(lFormErrors)>
					<cfset variables.spLabel = stNewContent.spLabel>
				<cfelse>
					<cfset variables.spLabel = content.spLabel>
				</cfif>
			
				<cfoutput>
				<tr>
					<cfif stAccess.spLabel.write>
						<td style="padding-top:5px;" width="60"><cfif stType.labelRequired><span class="required">*</span></cfif>#stStrings.label#</td>
						<td><input type="text" name="spLabel" <cfif isDefined("request.speck.portal")>class="readonly"</cfif> size="50" value="#replace(spLabel,"""","&quot;","all")#" maxlength="250"></td>
					<cfelse>
						<td style="padding-top:5px;" width="60">#stStrings.label#</td>
						<td>#spLabel#<input type="hidden" name="spLabel" value="#replace(spLabel,"""","&quot;","all")#"></td>
					</cfif>					
				</tr>
				</cfoutput>
			
			</cfif>		
			
			
			<cfif stAccess.spKeywords.read>
				
				<cfif len(lFormErrors)>
					<cfset variables.spKeywords = stNewContent.spKeywords>
				<cfelse>
					<cfset variables.spKeywords = content.spKeywords>
				</cfif>				
			
				<cfoutput>
				<tr>
				</cfoutput>
				
				<cfif stAccess.spKeywords.write>
				
					<cfoutput><td style="padding-top:5px;" width="60"><cfif stType.keywordsRequired><span class="required">*</span></cfif>#stStrings.keywords#</td></cfoutput>

					<cfif structIsEmpty(request.speck.keywords)>
					
						<cfoutput><td><textarea name="spKeywords" cols="47" rows="6">#listChangeDelims(spKeywords, chr(13), "/,")#</textarea></td></cfoutput>
					
					<cfelse>
					
						<cfif isDefined("request.speck.portal") and structKeyExists(stType,"keywordTemplates") and len(stType.keywordTemplates)>
							
							<cfquery name="qKeywords" dbtype="query">
								SELECT keyword, roles 
								FROM request.speck.qKeywords
								WHERE template IN (#listQualify(stType.keywordTemplates,"'")#)
							</cfquery>
							
							<cfscript>
								stAppKeywords = structNew();
								for (i=1; i lte qKeywords.recordCount; i=i+1) {
									structInsert(stAppKeywords,qKeywords.keyword[i],qKeywords.roles[i]);
								}
							</cfscript>
							
						<cfelse>
						
							<cfset stAppKeywords = duplicate(request.speck.keywords)>
							
						</cfif>
						
						<cfscript>
							stKeywords = structNew();
							
							// get variables.spKeywords into struct
							for(i=1; i le listLen(variables.spKeywords); i = i + 1) {
								keyword = listGetAt(variables.spKeywords,i);
								// insert keyword into struct, storing "selected" as value
								structInsert(stKeywords,keyword,"selected");
								// remove keyword from stAppKeywords
								structDelete(stAppKeywords,keyword);
							}
							
							// loop over app keywords which have not already been written to stKeywords struct
							lenKeywordFilter = len(stType.keywordFilter);
							for ( keyword in stAppKeywords ) {
								
								if ( lenKeywordFilter eq 0 ) {
									bInsertKeyword = true;
								} else {
									bInsertKeyword = false;
									for (i=1; i lte listLen(stType.keywordFilter); i=i+1 ) {
										filterItem = listGetAt(stType.keywordFilter,i);
										if ( left(keyword,len(filterItem)) eq filterItem ) {
											bInsertKeyword = true;
											break;
										}
									}
								}
								
								if ( bInsertKeyword and ( bSuper or bEdit or ( len(trim(stAppKeywords[keyword])) and request.speck.userHasPermission(stAppKeywords[keyword]) ) ) ) {
									structInsert(stKeywords,keyword,"");		
								}
								
							}
							
							// sorted list of keys in stKeywords...
							lKeywords = listSort(structKeyList(stKeywords),"textnocase","asc");
						</cfscript>
						
						<cfoutput><td><select name="spKeywords" multiple size="10"<cfif isDefined("request.speck.portal")> class="readonly"</cfif>>
						<option value=""></cfoutput>
						
						<cfloop list="#lKeywords#" index="i">
						
							<cfoutput><option value="#i#" #stKeywords[i]#>#i#</cfoutput>
						
						</cfloop>
						
						<cfoutput></select></td></cfoutput>								
					
					</cfif>
											
				<cfelse>
				
					<cfoutput>
					<td style="padding-top:5px;" width="60">#stStrings.keywords#</td>
					<td>#spKeywords#<input type="hidden" name="spKeywords" value="#spKeywords#"></td>
					</cfoutput>	
				
				</cfif> <!--- stAccess.spKeywords.write --->
				
				<cfoutput></tr></cfoutput>
				
			</cfif> <!--- stAccess.spKeywords.read --->
			
		<cfoutput>
		</table>
		</form>
		</cfoutput>
		
		<cfif request.speck.enableRevisions and stType.revisioned>
		
			<cfoutput><hr></cfoutput>
		
			<!--- call history tag --->
			<cfmodule template="/speck/api/content/spContentHistory.cfm"
				id=#content.spId#
				type=#attributes.type#
				revision=#content.spRevision#
				maxRows="10">
					
		</cfif>
		
	</cf_spHandler>
	
		
</cf_spType>

