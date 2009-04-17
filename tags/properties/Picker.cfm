<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spPropertyHandler>


	<cf_spPropertyHandlerMethod method="validateAttributes">
			
		<cfparam name="stPD.autoPromote" default="yes"> <!--- if promotion is enabled - promote picked items along with the content item containing this property? --->
	
		<cfparam name="stPD.dependent" default="no"> <!--- if yes, picked content items are dependent on their containing content item, if the container is deleted/removed, the picked items should also be deleted/removed --->
		
		<cfparam name="stPD.append" default="no"> <!--- append items to the end of the list? default is to insert at the beginning --->
		
		<cfparam name="stPD.showAdd" default="yes"> <!--- show add content item link when rendering form field? --->
		<cfparam name="stPD.showEdit" default="yes"> <!--- show edit content item link when rendering form field? --->
		<cfparam name="stPD.showSort" default="no">
		<cfparam name="stPD.contentType" default="">
		<cfparam name="stPD.contentTypes" default="#stPD.contentType#">
		
		<cfif trim(stPD.contentType) eq "">
			<cfset stPD.contentType = listFirst(stPD.contentTypes)>
		</cfif>
		
		<cfparam name="stPD.displaymethod" default="picker">
		<cfparam name="stPD.maxSelect" default="1">
		<cfset stPD.maxSelect = val(stPD.maxSelect)>
		<cfif stPD.maxSelect lt 1>
			<!--- invalid attribute value - maxSelect must be gt 0 --->
			<cf_spError error="ATTR_INV" lParams="#stPD.maxSelect#,maxSelect" context=#caller.ca.context#>
		</cfif>
		
		<!--- feck it, just force the maxLength to 4000 to allow for changes to the maxSelect attribute --->
		<cfset stPD.maxLength = 4000>
			
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="renderFormField">
	
		<!--- Get type info --->
		<cfmodule template=#request.speck.getTypeTemplate(stPD.contentType)# r_stType="stType">
		
		<!--- get keywords for containing content item --->
		<cfif not structKeyExists(url,"keywords")>

			<cfif not structKeyExists(variables,"type")>
			
				<cfif structKeyExists(url,"type") and len(url.type)>
					<cfset variables.type=url.type>
				<cfelse>
					<cfset variables.type=caller.stType.name>
				</cfif>
				
			</cfif>

			<cf_spContentGet type="#variables.type#" id="#id#" properties="spKeywords" r_qContent="qKeywords">
			
			<cfset variables.keywords = qKeywords.spKeywords>

		<cfelse>
		
			<cfset variables.keywords = url.keywords>
		
		</cfif>
		
		<cfscript>
			bAddEditAccess = false;
			// check access control to determine whether or not to show add link (note: actual access control code is in admin.cfm)
			if ( request.speck.userHasPermission("spSuper") ) {
				bAddEditAccess = true;
			} else if ( not request.speck.enablePromotion or (request.speck.enablePromotion and request.speck.session.viewLevel eq "edit") )  {
				if ( request.speck.userHasPermission("spEdit") ) {
					bAddEditAccess = true;
				} else {
					// see if the user gets granted edit access from having one of the keyword roles
					lKeywords = variables.keywords;
					for ( i=1; i le listLen(lKeywords); i = i + 1 ) {
						thisKeyword = listGetAt(lKeywords,i);
						if ( structKeyExists(request.speck.keywords,thisKeyword) 
								and len(trim(request.speck.keywords[thisKeyword]))
								and request.speck.userHasPermission(trim(request.speck.keywords[thisKeyword])) ) {
							// keyword exists, has edit roles and user has one of the roles
							bAddEditAccess = true;
							break;
						}
					}
				}
			}
			bShowEdit = ( bAddEditAccess and stPD.showEdit );
		</cfscript>
		
		<!--- Render current selection --->
		
		<!--- monitor form for changes and only request confirmation to submit the form after adding/editing/moving an item if the form has been modified --->
		<cfscript>
			bHtmlEditorFound = false;
			for ( i=1; i lte arrayLen(stType.props); i = i+1 ) {
				prop = stType.props[i];
				if ( prop.type eq "Html" and structKeyExists(prop,"richEdit") and prop.richEdit ) {
					bHtmlEditorFound = true;
				}	
			}
		</cfscript>
		<cfif bHtmlEditorFound>
			
			<!--- can't easily observe fck editor instances, so assume form has been modified --->
			<cfoutput>
			<script type="text/javascript">
			var formModified_#stPD.name# = true;
			</script>
			</cfoutput>
			
		<cfelse>
		
			<cfoutput>
			<script type="text/javascript">
				if ( window.onload ) 
					otherOnLoad_#stPD.name# = window.onload;
				else 
					otherOnLoad_#stPD.name# = new Function;
					
				var formModified_#stPD.name# = false;
				
				window.onload = function() {
					new Form.Observer('speditform', 0.3, function(form, value) {
						formModified_#stPD.name# = true;
					});
				};
			</script>
			</cfoutput>
		
		</cfif>
		
		<cfoutput>
		<script type="text/javascript">
			function submitForm_#stPD.name#() {
				if ( document.speditform.onsubmit ) {
					document.speditform.onsubmit();
				}
				document.speditform.action = document.location.href;
				$('saving').style.visibility='visible';
				document.speditform.submit();
			}
			
			function picker_launch_add_#stPD.name#(id) {
				var url = "/speck/admin/admin.cfm?action=add&type=#stPD.contentType#&picker_fieldname=#stPD.name#&app=#request.speck.appname#";
				if (id) {
					url = url + "&label=" + id + "&keywords=#urlEncodedFormat(keywords)#";
				} else {
					url = url + "&label=&keywords=#urlEncodedFormat(keywords)#";
				}
				//if (!id) var id = '';
				//pickerpopup_#stPD.name# = window.open("/speck/admin/admin.cfm?action=add&type=#stPD.contentType#&picker_fieldname=#stPD.name#&app=#request.speck.appname#&label=" + id + "&keywords=#urlEncodedFormat(keywords)#", "pickerpopup_add_#stPD.name#", "menubar=no,scrollbars=yes,resizable=yes,width=600,height=600,screenX=200,screenY=100,left=200,top=100");
				pickerpopup_#stPD.name# = window.open(url, "pickerpopup_add_#stPD.name#", "menubar=no,scrollbars=yes,resizable=yes,width=600,height=600,screenX=200,screenY=100,left=200,top=100");
				pickerpopup_#stPD.name#.focus();
			}
			
			function picker_launch_select_#stPD.name#() {
				pickerpopup_#stPD.name# = window.open("/speck/properties/picker/pickerpopup.cfm?type=#stPD.contentType#&fieldName=#stPD.name#&spView=#stPD.displayMethod#&app=#request.speck.appName#", "pickerpopup_select_#stPD.name#", "menubar=no,scrollbars=yes,resizable=yes,width=450,height=400,screenX=200,screenY=100,left=200,top=100");
				pickerpopup_#stPD.name#.focus();
			}
			
			function picker_launch_edit_#stPD.name#(id,type) {
				pickerpopup_#stPD.name# = window.open("/speck/admin/admin.cfm?action=edit&keywords=#urlEncodedFormat(keywords)#&type=#stPD.contentType#&picker_fieldname=#stPD.name#&id=" + id + "&app=#request.speck.appName#", "pickerpopup_edit_" + id.replace(/-/g, ""), "menubar=no,scrollbars=yes,resizable=yes,width=600,height=600,screenX=200,screenY=100,left=200,top=100");
				pickerpopup_#stPD.name#.focus();
			}
			
			function picker_edit_update_#stPD.name#() {
				// this here is some bad ass hacking to "hide" the edit picked item window behind the main edit window
				// Don't try this at home kids, but if you can figure out some other way around it please tell me how.
				try {
					pickerpopup_#stPD.name#.resizeTo(200, 200);
				} catch(e) { 
					// do nothing 
				}
				if ( !formModified_#stPD.name# || confirm(#request.speck.buildString("A_PICKER_EDIT_UPDATE_CONFIRM","#stType.caption#")#) ) {
					submitForm_#stPD.name#();
				}
				pickerpopup_#stPD.name#.close();
			}
			
			function picker_add_#stPD.name#(ids) {
				try {
					pickerpopup_#stPD.name#.resizeTo(200, 200); // um, this is horrible, but it works
				} catch(e) { 
					// do nothing 
				}
				if ( !formModified_#stPD.name# || confirm(#request.speck.buildString("A_PICKER_ADD_CONFIRM","#stType.caption#,#stPD.caption#")#) ) {
					<cfif stPD.append>
						document.speditform.#stPD.name#.value = <cfif stPD.maxSelect gt 1>document.speditform.#stPD.name#.value + "," + </cfif>ids;
					<cfelse>
						document.speditform.#stPD.name#.value = ids<cfif stPD.maxSelect gt 1> + "," + document.speditform.#stPD.name#.value</cfif>;
					</cfif>
					submitForm_#stPD.name#();
				}
				pickerpopup_#stPD.name#.close();
			}
			
			function picker_move_confirm_#stPD.name#() {
				return ( !formModified_#stPD.name# || confirm(#request.speck.buildString("A_PICKER_MOVE_CONFIRM","#stType.caption#")#) );
			}
			
			function picker_moveUp_#stPD.name#(id) {
				if ( picker_move_confirm_#stPD.name#() ) {
					var currentValue = document.speditform.#stPD.name#.value;
					var currentValueArray = currentValue.split(",");
					var newValueArray = new Array(currentValueArray.length);
					for (i = 0; i < currentValueArray.length; i++) {
						newValueArray[i] = currentValueArray[i];
						if ( currentValueArray[i] == id ) {
							if (i > 0) {
								newValueArray[i] = newValueArray[i-1];
								newValueArray[i-1] = currentValueArray[i];
							}
						}
					}
					document.speditform.#stPD.name#.value = newValueArray.toString();
					submitForm_#stPD.name#();
				}
			}
			
			function picker_moveDown_#stPD.name#(id) {
				if ( picker_move_confirm_#stPD.name#() ) {
					var currentValue = document.speditform.#stPD.name#.value;
					var currentValueArray = currentValue.split(",").reverse();
					var newValueArray = new Array(currentValueArray.length);
					for (i = 0; i < currentValueArray.length; i++) {
						newValueArray[i] = currentValueArray[i];
						if ( currentValueArray[i] == id ) {
							if (i > 0) {
								newValueArray[i] = newValueArray[i-1];
								newValueArray[i-1] = currentValueArray[i];
							}
						}
					}
					document.speditform.#stPD.name#.value = newValueArray.reverse().toString();
					submitForm_#stPD.name#();
				}
			}
			
			function picker_moveTop_#stPD.name#(id) {
				if ( picker_move_confirm_#stPD.name#() ) {
					var currentValue = document.speditform.#stPD.name#.value;
					var idRemovedValue = currentValue.replace(id.replace(/\-/,"\-"),""); // remove id
					idRemovedValue = idRemovedValue.replace(/,,/,","); // remove any double commas left behind
					idRemovedValue = idRemovedValue.replace(/^,/,""); // remove comma at start of string
					idRemovedValue = idRemovedValue.replace(/,$/,""); // remove comma at end of string
					document.speditform.#stPD.name#.value = id + "," + idRemovedValue;
					submitForm_#stPD.name#();
				}
			}
			
			function picker_moveBottom_#stPD.name#(id) {
				if ( picker_move_confirm_#stPD.name#() ) {
					var currentValue = document.speditform.#stPD.name#.value;
					var idRemovedValue = currentValue.replace(id.replace(/\-/,"\-"),""); // remove id
					idRemovedValue = idRemovedValue.replace(/,,/,","); // remove any double commas left behind
					idRemovedValue = idRemovedValue.replace(/^,/,""); // remove comma at start of string
					idRemovedValue = idRemovedValue.replace(/,$/,""); // remove comma at end of string
					document.speditform.#stPD.name#.value = idRemovedValue + "," + id;
					submitForm_#stPD.name#();
				}
			}
		</script>
		</cfoutput>
		
		<cfif stPD.required and listLen(value) eq 1>
		
			<cfoutput>
			<script>
				function picker_remove_#stPD.name#(id) {
					alert(#request.speck.buildString("A_PICKER_CANNOT_REMOVE_ALERT","#stPD.caption#")#);
				}
				
				function picker_delete_#stPD.name#(id) {
					alert(#request.speck.buildString("A_PICKER_CANNOT_DELETE_ALERT","#stPD.caption#")#);
				}
			</script>
			</cfoutput>
			
		<cfelse>
		
			<cfoutput>
			<script>
				function picker_remove_#stPD.name#(id) {
					if ( confirm(#request.speck.buildString("A_PICKER_REMOVE_CONFIRM","#stType.caption#,#stPD.caption#")#) ) {
						var currentValue = document.speditform.#stPD.name#.value;
						// was going to do this with one statement, but ran into trouble so step by step we go...
						var newValue = currentValue.replace(id.replace(/\-/,"\-"),""); // remove id
						newValue = newValue.replace(/,,/,","); // remove any double commas left behind
						newValue = newValue.replace(/^,/,""); // remove comma at start of string
						newValue = newValue.replace(/,$/,""); // remove comma at end of string
						document.speditform.#stPD.name#.value = newValue;
						submitForm_#stPD.name#();
					}
				}
				
				function picker_delete_#stPD.name#(id) {
					if ( confirm(#request.speck.buildString("A_PICKER_DELETE_CONFIRM","#stType.caption#,#stPD.caption#")#) ) {
						var win = window.open("/speck/admin/admin.cfm?action=delete&app=#request.speck.appname#&type=#stType.name#&id=" + id + "&caption=#stType.caption#", "delete" + id.replace(/-/g, ""), "menubar=no,scrollbars=no,resizable=yes,width=150,height=100");
						var currentValue = document.speditform.#stPD.name#.value;
						// was going to do this with one statement, but ran into trouble so step by step we go...
						var newValue = currentValue.replace(id.replace(/\-/,"\-"),""); // remove id
						newValue = newValue.replace(/,,/,","); // remove any double commas left behind
						newValue = newValue.replace(/^,/,""); // remove comma at start of string
						newValue = newValue.replace(/,$/,""); // remove comma at end of string
						document.speditform.#stPD.name#.value = newValue;
						submitForm_#stPD.name#();
					}
				}
			</script>
			</cfoutput>
		
		</cfif>
		
		<cfif len(trim(value)) and stPD.maxSelect eq 1>
		
			<!--- only 1 item allowed and 1 item already selected, only allow change --->
			<cfoutput><input type="button" value="#request.speck.buildString("A_PICKER_CHANGE_CAPTION")# #stType.caption#" onclick="picker_launch_select_#stPD.name#()" /></cfoutput>
			
		<cfelse>
		
			<!---
			Stop users from adding/selecting additonal items if number of selected items is already at max...
			Disabling buttons doesn't grey them out in Firefox/Windows so user has no idea WTF is going on, 
			so we'll lash out a JavaScript alert onclick instead rather than disable the button.
			--->
			<cfscript>
			 if ( stPD.maxSelect eq listLen(value) ) {
			 	addOnClick = "alert('#request.speck.buildString("A_PICKER_MAX_SELECTED_ALERT")#')";
				selectOnClick = addOnClick; // don't need a different warning for adding and selecting
			 } else if (stPD.dependent) {
			 	addOnClick = "picker_launch_add_#stPD.name#('#id#')";
			 } else {
			 	addOnClick = "picker_launch_add_#stPD.name#()";
				selectOnClick = "picker_launch_select_#stPD.name#()";
			 }
			</cfscript>
			
			<cfif stPD.dependent or (bAddEditAccess and stPD.showAdd)>
			
				<cfoutput><input type="button" value="#request.speck.buildString("A_PICKER_ADD_CAPTION")# #stType.caption#" onclick="#addOnClick#" />&nbsp;&nbsp;</cfoutput>
				
			</cfif>
			
			<cfif not stPD.dependent>
			
				<cfoutput><input type="button" value="#request.speck.buildString("A_PICKER_SELECT_CAPTION")# #stType.caption#" onclick="#selectOnClick#" /></cfoutput>
			
			</cfif>
		
		</cfif>

		<cfif len(trim(value))>
			
			<cfoutput><table cellspacing="1" border="0" cellpadding="0" width="100%" style="margin:3px"></cfoutput>
					
			<cfset editCaptionString = request.speck.buildString("T_DEFAULT_PICKER_EDIT_CAPTION")>
			<cfset removeCaptionString = request.speck.buildString("T_DEFAULT_PICKER_REMOVE_CAPTION")>
			<cfset deleteCaptionString = request.speck.buildString("T_DEFAULT_PICKER_DELETE_CAPTION")>
			
			<!--- output each picked item --->
			
			<cf_spContentGet type="#stPD.contentType#" id="#value#" orderByIds="yes" r_qContent="qContent">
			
			<!--- always set value to the list of ids returned from the database - we don't want to include items that have been deleted --->
			<cfset value = valueList(qContent.spId)>
			
			<cfloop query="qContent">
					
				<cfoutput>
				<tr <cfif currentRow mod 2 eq 1>class="alternateRow"</cfif>>
				<td width="30" valign="top" nowrap>
				</cfoutput>
				
				<cfif stPD.showEdit>
			
					<cfoutput><a href="javascript:picker_launch_edit_#stPD.name#('#qContent.spId#','#stPD.contentType#')" title="#editCaptionString#">#left(editCaptionString,1)#</a>&nbsp;</cfoutput>
				
				</cfif>
				
				<cfif stPD.dependent>
				
					<cfoutput>
					<a href="javascript:picker_delete_#stPD.name#('#qContent.spId#')" title="#deleteCaptionString#">#left(deleteCaptionString,1)#</a>
					</cfoutput>
					
				<cfelse>
				
					<cfoutput>
					<a href="javascript:picker_remove_#stPD.name#('#qContent.spId#')" title="#removeCaptionString#">#left(removeCaptionString,1)#</a>
					</cfoutput>
				
				</cfif>
				
				<cfoutput>
				</td>
				<td>
				</cfoutput>
				
				<!--- Use displaymethod to view content item --->
				<cfmodule template=#request.speck.getHandlerTemplate(stType,stPD.displayMethod)#
					qContent=#qContent#
					startRow=#currentRow#
					endRow=#currentRow#
					separator=""
					type=#stPD.contentType#
					method=#stPD.displayMethod#>
				
				<cfoutput>
				</td>
				</cfoutput>

				<cfif stPD.showSort>

					<!--- allow picked items to be sorted --->

					<cfoutput>
					<td valign="top" nowrap align="center">
					<a href="javascript:picker_moveTop_#stPD.name#('#qContent.spId#')" title="#request.speck.buildString("T_DEFAULT_PICKER_MOVE_TOP_CAPTION")#"><img style="vertical-align:middle;" src="/speck/properties/picker/picker_top.gif" width="9" height="9" border="0"></a>
					<a href="javascript:picker_moveUp_#stPD.name#('#qContent.spId#')" title="#request.speck.buildString("T_DEFAULT_PICKER_MOVE_UP_CAPTION")#"><img style="vertical-align:middle;" src="/speck/properties/picker/picker_up.gif" width="9" height="9" border="0"></a>
					<a href="javascript:picker_moveDown_#stPD.name#('#qContent.spId#')" title="#request.speck.buildString("T_DEFAULT_PICKER_MOVE_DOWN_CAPTION")#"><img style="vertical-align:middle;" src="/speck/properties/picker/picker_down.gif" width="9" height="9" border="0"></a>
					<a href="javascript:picker_moveBottom_#stPD.name#('#qContent.spId#')" title="#request.speck.buildString("T_DEFAULT_PICKER_MOVE_BOTTOM_CAPTION")#"><img style="vertical-align:middle;" src="/speck/properties/picker/picker_bottom.gif" width="9" height="9" border="0"></a>
					</td>
					</cfoutput>

				</cfif>

				<cfoutput>
				</tr>
				</cfoutput>
		
			</cfloop>
	
			<cfif stPD.maxSelect gt 1 and stPD.maxSelect eq listLen(value)>
			
				<!--- multiple items allowed, but maximum number of items allowed already selected --->
				<cfoutput>
				<tr>
					<td colspan="3">
					#request.speck.buildString("A_PICKER_MAX_SELECTED")#
					</td>
				</tr>
				</cfoutput>
			
			</cfif>
			
			<cfoutput>
			</table>
			</cfoutput>

		</cfif>

		<cfoutput>
		<input type="Hidden" name="#stPD.name#" value="#value#" />
		</cfoutput>
	
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="readFormField">
	
		<!--- Remove ids checked for deletion from list of ids in the form field --->
		<cfparam name="form.picker_select_#stPD.name#" default="">
		<cfset newValue = "">
		<cfset lDelete = form["picker_select_" & stPD.name]>
		
		<cfloop list="#form[stPD.name]#" index="id">
		
			<cfif listFind(lDelete, id) eq 0>
			
				<cfset newValue = listAppend(newValue, id)>
			
			</cfif>
		
		</cfloop>
	
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="validateValue">
	
		<cfif listLen(newValue) gt stPD.maxSelect>
		
			<cfset lErrors = request.speck.buildString("P_PICKER_TOO_MANY_SELECTED","")>
		
		</cfif>
		
		<cfloop list="#newValue#" index="id">
		
			<cfif not request.speck.isUUID(id)>
			
				<cfset lErrors = listAppend(lErrors, request.speck.buildString("P_PICKER_NOT_UUID", id))>
			
			</cfif>
		
		</cfloop>
		
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="promote">
		
		<cfif stPD.autoPromote or stPD.dependent>
		
			<!--- check if picked type is revisioned --->
			<cfmodule template=#request.speck.getTypeTemplate(stPD.contentType)# r_stType="stType">

			<cfif stType.revisioned>

				<!--- get ids and revisions of picked items at the current level --->
				<cf_spContentGet type="#stPD.contentType#" id="#value#" properties="spId,spRevision" r_qContent="qPicked">
				
				<cfloop query="qPicked">
	
					<!--- check if the revision at this level is different than the revision at the next level --->
					<cf_spRevisionGet
						id="#spId#"
						type="#stPD.contentType#"
						level="#newLevel#"
						r_revision="revisionAtNewLevel">
	
					<cfif spRevision neq revisionAtNewLevel>
						
						<!--- promote current revision of item to next level --->
						<cf_spPromote
							id="#spId#"
							type="#stPD.contentType#"
							revision="#spRevision#"
							newLevel="#newLevel#"
							editor="#request.speck.session.user#">
		
						<cfif newLevel eq "live">
		
							<!--- attempt to flush any content items from the output cache at live level --->
							<cfparam name="url.label" default="">
							<cfparam name="url.keywords" default="">
							<cfmodule template="/speck/api/content/spFlushCache.cfm"
								type="#stPD.contentType#"
								id="#spId#"
								label="#url.label#"
								keywords="#url.keywords#">
	
						</cfif>
	
					</cfif>
	
				</cfloop>
				
			</cfif>
		
		</cfif>
		
	</cf_spPropertyHandlerMethod>
	

	<cf_spPropertyHandlerMethod method="contentPut">

		<!---
		Force picked content items to have the same keywords as the parent.
		In the case of dependent children, the keywords should be the exact 
		same as the parent. Non-dependent children should at least contain
		the keywords of the parent, but may also have other keywords.
		At this stage all children exist in the database. We have the ids 
		available as newValue, so we can just update the database directly.
		Note: not tested with revisioning or promotion enabled (should work tho).
		--->
		
		<cfif len(newValue)>
		
			<cf_spContentGet type="#stPD.contentType#" id="#newValue#" properties="spId,spRevision,spKeywords" r_qContent="qPicked">
			
			<!--- start with the parent keywords, if the child isn't dependent, we'll add any other existing keywords when saving --->
			<cfif isDefined("caller.attributes.stContent.spKeywords")>
				<cfset keywords = caller.attributes.stContent.spKeywords>
			<cfelse>
				<cfset keywords = "">
			</cfif>
			
			<cfloop query="qPicked">
			
				<cfif not stPD.dependent>
				
					<!--- append existing keywords not found in parent keywords before saving --->
					<cfloop list="#qPicked.spkeywords#" index="i">
						<cfif not listFind(keywords,i)>
							<cfset keywords = listAppend(keywords,i)>
						</cfif>
					</cfloop>
				
				</cfif>
				
				<!--- update type table (only the relevant revision) --->
				<cfquery name="qUpdate" datasource="#request.speck.codb#">
					UPDATE #stPD.contentType#
					SET spKeywords = <cfif len(trim(keywords))>'#keywords#'<cfelse>NULL</cfif>
					WHERE spId = '#spId#'
						AND spRevision = #spRevision#
				</cfquery>
				
				<!--- update keywords index table (TODO: make this code into a custom tag, it's now used in three places!) --->
				<cfquery name="qDeleteKeywords" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
					DELETE FROM spKeywordsIndex
					WHERE id = '#spId#'
				</cfquery>
				
				<cfif len(keywords)>
				
					<cfloop list="#keywords#" index="keyword">
						<cfquery name="qInsertKeyword" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
							INSERT INTO spKeywordsIndex (contentType, keyword, id)
							VALUES ('#uCase(stPD.contentType)#', '#uCase(trim(keyword))#', '#spId#' )
						</cfquery>
					</cfloop>
					
				</cfif>
				
			</cfloop>
		
		</cfif>
	
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="delete">
	
		<cfif stPD.dependent and request.speck.isUUID(listFirst(value))>
		
			<!--- delete all picked items --->
			<cf_spContentGet type="#stPD.contentType#" id="#value#" properties="spId" r_qContent="qPicked">
			
			<cfloop query="qPicked">
			
				<cf_spDelete id="#spId#" type="#stPD.contentType#">
				
			</cfloop>
			
		</cfif>
	
	</cf_spPropertyHandlerMethod>
	
	
</cf_spPropertyHandler>
