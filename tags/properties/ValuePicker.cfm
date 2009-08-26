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


	<cf_spPropertyHandlerMethod method="validateAttributes">
	
		<cfparam name="stPD.list" default=""> <!--- deprecated, valueList is clearer --->
		<cfparam name="stPD.valueList" default="#stPD.list#">
		<cfparam name="stPD.optionList" default="#caller.ca.context.capitalize(stPD.valueList)#"> <!--- use to overide the list of options that a user sees when selecting a value --->
		<cfif len(stPD.optionList) and not len(stPD.valueList)>
			<cfset stPD.valueList = stPD.optionList>
		</cfif>
		<cfparam name="stPD.delimiter" default=",">	
		<cfparam name="stPD.maxSelect" default="1">
		
		<cfparam name="stPD.defaultValue" default="">
		
		<cfif not listLen(stPD.valueList)>
		
			<cf_spError error="ATTR_REQ" lParams="valueList" context=#caller.ca.context#>
		
		</cfif>
		
		<cfif listLen(stPD.optionList) neq listLen(stPD.valueList)>
		
			<!--- invalid attribute value - optionList must have the same number of items as valueList --->
			<cf_spError error="ATTR_INV" lParams="#replace(stPD.optionList,",","&##44;","all")#,optionList" context=#caller.ca.context#>
		
		</cfif>
		
		<cfset stPD.maxSelect = int(val(stPD.maxSelect))>
		<cfif stPD.maxSelect eq 0 or stPD.maxSelect lt -1>
		
			<!--- invalid attribute value - maxSelect must be gt 0 --->
			<cf_spError error="ATTR_INV" lParams="#stPD.maxSelect#,maxSelect" context=#caller.ca.context#>
		
		</cfif>
		
		<!--- set the maxLength of the db column to 2000 so we can deal with changes to the maxSelect attribute --->
		<cfset stPD.maxLength = 2000>
			
	</cf_spPropertyHandlerMethod>


	<cf_spPropertyHandlerMethod method="renderFormField">
	
		<cfscript>
			size = int(val(listLast(stPD.displaySize)));
			if ( stPD.maxSelect eq 1 ) {
				size = 1;
			} else {
				if ( size lt 1 or size lt stPD.maxSelect )
					size = stPD.displaySize;
				if ( size gt 10 )
					size = 10;
			}
			
			selectedValues = value;
			if ( not len(selectedValues) and len(stPD.defaultValue) and ( action eq "add" and cgi.request_method neq "post" ) ) {
				selectedValues = stPD.defaultValue;
			}
		</cfscript>
		
		<cfif stPD.maxSelect neq 1>
		
			<cfoutput>
			<script type="text/javascript">
				// Modified versions of selectbox functions by Matt Kruse <matt@mattkruse.com>
				// Check out his JavaScript toolbox at http://www.mattkruse.com/
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
				
				function checkMaxSelect_#stPD.name#() {
					if ( document.speditform.#stPD.name#.options.length == #stPD.maxSelect# ) {
						alert("#jsStringFormat(request.speck.buildString("P_SIMPLEPICKER_MAX_SELECTED","#stPD.caption#"))#");
						return false;
					} else {
						return true;	
					}
				}
				
				// add selectAllOptions() to form onsubmit
				if ( document.speditform.onsubmit ) 
					otherOnSubmit_#stPD.name# = document.speditform.onsubmit;
				else 
					otherOnSubmit_#stPD.name# = new Function;
				document.speditform.onsubmit = function() {
													selectAllOptions_#stPD.name#(document.speditform.#stPD.name#);
													otherOnSubmit_#stPD.name#();
												};
			</script>
			<table border="0" cellpadding="0" cellspacing="0" width="100%">
			<tr>
			<td width="45%">#request.speck.buildString("P_SIMPLEPICKER_AVAILABLE")#<br />
				<select name="#stPD.name#_from" id="#stPD.name#_from" multiple="yes" size="#size#" style="width:100%;">
				</cfoutput>
				
				<cfloop from="1" to="#listLen(stPD.valueList,stPD.delimiter)#" index="i">
				
					<cfset thisValue = listGetAt(stPD.valueList,i,stPD.delimiter)>
					
					<cfif not listFindNoCase(selectedValues,thisValue)>
					
						<cfoutput><option value="#thisValue#">#listGetAt(stPD.optionList,i,stPD.delimiter)#</option></cfoutput>
					
					</cfif>
				
				</cfloop>
						
				<cfoutput>
				</select>
			</td>
			<td width="10%" style="vertical-align:middle;text-align:center;">
				<input name="#stPD.name#_right" id="#stPD.name#_right" value="&gt;&gt;" onclick="if ( checkMaxSelect_#stPD.name#() ) moveSelectedOptions_#stPD.name#(this.form['#stPD.name#_from'],this.form['#stPD.name#'],true);" type="button"><br />
				<input name="#stPD.name#_left" id="#stPD.name#_left" value="&lt;&lt;" onclick="moveSelectedOptions_#stPD.name#(this.form['#stPD.name#'],this.form['#stPD.name#_from'],true)" type="button">
			</td>
			<td width="45%">#request.speck.buildString("P_SIMPLEPICKER_SELECTED")#<br />
				<select name="#stPD.name#" id="#stPD.name#" multiple="yes" size="#size#" style="width:100%;">
				</cfoutput>
				
				<cfloop from="1" to="#listLen(stPD.valueList,stPD.delimiter)#" index="i">
				
					<cfset thisValue = listGetAt(stPD.valueList,i,stPD.delimiter)>
					
					<cfif listFindNoCase(selectedValues,thisValue)>
					
						<cfoutput><option value="#thisValue#">#listGetAt(stPD.optionList,i,stPD.delimiter)#</option></cfoutput>
					
					</cfif>
				
				</cfloop>
						
				<cfoutput>
				</select>
			</td>
			</tr>
			</table>
			<cfif stPD.maxSelect neq -1>
				(#request.speck.buildString("P_SIMPLEPICKER_MAXSELECT_NOTE","#stPD.maxSelect#,#stPD.caption#")#)
			</cfif>
			</cfoutput>
		
		<cfelse>
		
			<cfoutput>
			<select name="#stPD.name#" id="#stPD.name#">
			</cfoutput>
			
			<cfset forceWidth = "">
			<cfif listLen(stPD.displaySize) eq 2>
			
				<cfscript>
					width = int(val(listFirst(stPD.displaySize)));
					forceWidth = "";
					for (i=1; i lte width; i = i+1)
						forceWidth = forceWidth & "&nbsp;";
				</cfscript>
			
			</cfif>
			
			<cfif len(forceWidth) or not stPD.required or ( stPD.required and not len(stPD.defaultValue) )>
			
				<!--- throw in an empty option/value --->
				<cfoutput><option value="">#forceWidth#</option></cfoutput>
			
			</cfif>
			
			<cfloop from="1" to="#listLen(stPD.valueList,stPD.delimiter)#" index="i">
			
				<cfset thisValue = listGetAt(stPD.valueList,i,stPD.delimiter)>
				
				<cfoutput><option value="#thisValue#"<cfif listFind(selectedValues,thisValue)> selected="yes"</cfif>>#listGetAt(stPD.optionList,i,stPD.delimiter)#</option></cfoutput>
			
			</cfloop>
			
			<cfoutput>
			</select>
			</cfoutput>
				
		</cfif>

	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="validateValue">
	
		<cfif stPD.maxSelect neq -1 and listLen(newValue) gt stPD.maxSelect>
			<cfset lErrors = request.speck.buildString("P_SIMPLEPICKER_SELECTED_GT_MAXSELECT", "#stPD.caption#,#listLen(newValue)#,#stPD.maxSelect#")>
		</cfif>
		
	</cf_spPropertyHandlerMethod>	
	
	
</cf_spPropertyHandler>