<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- Validate attributes --->
<cfloop list="app,type,fieldname" index="attribute">

	<cfif not isdefined("url.#attribute#")>
	
		<cf_spError error="ATTR_REQ" lParams="#attribute#">	<!--- Missing attribute --->
		
	</cfif>

</cfloop>

<cf_spApp name="#url.app#">
	
<cfif not request.speck.userHasPermission("spSuper,spEdit") or request.speck.session.auth neq "logon">

	<cf_spError error="ACCESS_DENIED" throwException="no">

</cfif>

<cfparam name="url.spSelected" default="">
<cfparam name="url.spLabel" default="">
<cfparam name="url.spKeywords" default="">
<cfparam name="url.spOrderby" default="">
<cfparam name="url.spLogicalOperator" default="AND">

<!--- get type info --->
<cfmodule template=#request.speck.getTypeTemplate(url.type)# r_stType="stType">

<!--- build a structure containing form field names and captions of properties we can search --->
<cfset stProps = structNew()>
<cfloop from=1 to="#arrayLen(stType.props)#" index="iProp">
	
	<cfset stPD = stType.props[iProp]>

	<cfif isBoolean(stPD.finder) and stPD.finder>
		
		<cfset "stProps.#stPD.name#" = stPD.caption>

	</cfif>

</cfloop>

<!--- save the list of keys in the form properties structure - this is really just for backwards compatibility with old code --->
<cfset lProps = structKeyList(stProps)>

<cfoutput>
<html>
<head>
<title>#request.speck.buildString("A_PICKER_SELECT_CAPTION")# #stType.caption#</title>
<link rel="stylesheet" href="#request.speck.adminStylesheet#" type="text/css">
<script type="text/javascript">

	// note: these functions are found in spContentPicker.cfm and are called from the spPicker display method of the default type

	// callback to add to selection function in opener when S(elect) clicked
	function picker_select_pickerpopup(id) {
		opener.picker_add_#url.fieldname#(id,'');
	}
	
	// callback to launch edit function in opener when E(dit) clicked
	function picker_launch_edit_pickerpopup(id, type) {
		picker_launch_edit_pickerpopup(id,type);
	}
		
</script>
</head>
<body bgcolor="##C0C0C0">

<form name="pickerpopup" action="#cgi.script_name#" method="get">
<!--- querystring parameters passed to pickerpopup from spContentPicker --->
<input type="hidden" name="app" value="#url.app#" />
<input type="hidden" name="type" value="#url.type#" />
<input type="hidden" name="fieldname" value="#url.fieldname#" />
<input type="hidden" name="spSubmitted" value="yes" />
<input type="Hidden" name="spSelected" value="" />

<script type="text/javascript">
	document.pickerpopup.spSelected.value = opener.document.speditform.#url.fieldname#.value;
</script>

<table cellspacing="0" cellpadding="0" border="0">
</cfoutput>

<cfloop collection="#stProps#" item="key">

	<cfparam name="url.pickerpopup_#key#" default="">
	
	<cfoutput>
	<tr>
		<td colspan="5">#stProps[key]#</td>
	</tr>
	<tr>
		<td colspan="5"><input type="text" name="pickerpopup_#key#" value="#evaluate("url.pickerpopup_#key#")#" size="50" maxlength="50"></td>
	</tr>
	</cfoutput>

</cfloop>

<!--- label and keywords--->
<cfoutput>
<tr>
	<td colspan="5">#request.speck.buildString("A_PICKER_KEYWORDS_CAPTION")#</td>
</tr>
<tr>
	<td colspan="5"><input type="text" name="spKeywords" value="#url.spKeywords#" size="50" maxlength="50"></td>	
</tr>
<tr>
	<td colspan="5">#request.speck.buildString("A_PICKER_LABEL_CAPTION")#</td>
</tr>
<tr>
	<td colspan="5"><input type="text" name="spLabel" value="#url.spLabel#" size="50" maxlength="50"></td>
</tr>
<tr>
	<td>#request.speck.buildString("A_PICKER_MATCH_CAPTION")#</td>
	<td>&nbsp;</td>
	<td>#request.speck.buildString("A_PICKER_ORDERBY_CAPTION")#</td>
	<td>&nbsp;</td>
	<td>&nbsp;</td>
</tr>
<tr>
	<td>
		<input type="Radio" name="spLogicalOperator" value="AND"<cfif url.spLogicalOperator eq "AND"> checked</cfif>> #request.speck.buildString("A_PICKER_ALL_CAPTION")#
		<input type="Radio" name="spLogicalOperator" value="OR"<cfif url.spLogicalOperator eq "OR"> checked</cfif>> #request.speck.buildString("A_PICKER_ANY_CAPTION")#
	</td>
	<td>&nbsp;</td>
	</cfoutput>
	
	<!--- oderby disabled? --->
	<cfif lProps eq "">
		<cfset disabled = "disabled=""true""">
	<cfelse>
		<cfset disabled = "">
	</cfif>
		
	<cfoutput>
	<td>
		<select name="spOrderby" #disabled#>
			<cfloop list="#lProps#" index="propName">
				<option value="#propName#" <cfif url.spOrderby eq propName>selected</cfif>>#propName#
			</cfloop>
			<option value="spLabel">#lCase(request.speck.buildString("A_PICKER_LABEL_CAPTION"))#</option>
		</select>
	</td>
	<td>&nbsp;</td>
	<td align="right"><input type="submit" value="Search"></td>
</tr>
</table>

</form>
</cfoutput>

<cfif isdefined("url.spSubmitted")>

	<!--- build where attribute for cf_spContent call --->
	<cfscript>
		if ( len(trim(url.spKeywords)) ) {
			if ( request.speck.dbtype eq "access" ) {
				sqlIdentifier = "spKeywords";
			} else {
				sqlIdentifier = "UPPER(spKeywords)";
			}
			where = sqlIdentifier & " LIKE '%#uCase(trim(replace(replace(url.spKeywords," ","%","all"),"'","''","all")))#%'";
		} else {
			where = "1=1";
		}
	
		if ( len(trim(url.spLabel)) ) {
			sqlLiteral = "%#uCase(trim(replace(replace(url.spLabel," ","%","all"),"'","''","all")))#%";
			if ( request.speck.dbtype eq "access" ) {
				sqlIdentifier = "spLabel";
			} else {
				sqlIdentifier = "UPPER(spLabel)";
			}
			if ( len(trim(where)) ) {
				where = where & " #url.spLogicalOperator# #sqlIdentifier# LIKE '#sqlLiteral#'";
			} else {
				where = where & "#sqlIdentifier# LIKE '#sqlLiteral#'";
			}
		}
		
		for ( i=1; i lte listLen(lProps); i=i+1 ) {
			prop = listGetAt(lProps,i);
			if ( len(trim(evaluate("url.pickerpopup_#prop#"))) ) {
				sqlLiteral = "%#uCase(trim(replace(replace(evaluate("url.pickerpopup_#prop#")," ","%","all"),"'","''","all")))#%";
				if ( request.speck.dbtype eq "access" ) {
					sqlIdentifier = prop;
				} else {
					sqlIdentifier = "UPPER(" & prop & ")";
				}
				if ( len(trim(where)) ) {
					where = where & " #url.spLogicalOperator# #sqlIdentifier# LIKE '#sqlLiteral#'";
				} else {
					where = where & "#sqlIdentifier# LIKE '#sqlLiteral#'";
				}
			}
		}
		
		if ( len(trim(url.spSelected)) ) {
			thisCondition = "spId NOT IN ('#replace(url.spSelected,",","','","all")#')";
			if ( len(trim(where)) ) {
				where = "(" & where & ") AND " & thisCondition;
			} else {
				where = where & thisCondition;
			}
		}
		
		// do not retrieve content items dependent on their containing content item (dependent content items store the spId of the container in the label property, yup, it's a hack)
		where = where & " AND ( spLabel IS NULL OR spLabel NOT LIKE '________-____-____-______________')";
	</cfscript>
	
	<!--- just get back the spId values for all matching content items (don't want to run any contentGet handlers at this stage) --->
	<cf_spContentGet type="#url.type#"
		where="#where#"
		properties="spId"
		orderby="#url.spOrderby#"
		r_qContent="qResults">
	
	<cfoutput>
	<hr />
	</cfoutput>
	
	<cfif not qResults.recordCount>
	
		<cfoutput>
		#request.speck.buildString("A_PICKER_NO_RESULTS")#
		</cfoutput>
	
	<cfelse>
		
		<!--- do paging stuff --->
		<cfmodule template="/speck/api/content/spContentPaging.cfm"
			totalRows=#qResults.recordCount#
			displayPerPage="10">
			
		<cfoutput>#stPaging.menu#</cfoutput>
	
		<cfoutput>
		<table cellspacing="1" valign="top" width="100%">
		</cfoutput>

		<cfset selectCaptionString = request.speck.buildString("T_DEFAULT_PICKER_SELECT_CAPTION")>
		
		<cfloop query="qResults" startrow="#stPaging.startRow#" endrow="#stPaging.endRow#">
				
			<cfoutput>
			<tr <cfif currentRow mod 2 eq 1>class="alternateRow"</cfif>>
			<td width="15" valign="top" nowrap>
			<a href="javascript:picker_select_pickerpopup('#spId#')" title="#selectCaptionString#">#left(selectCaptionString,1)#</a>
			</td>
			<td>
			</cfoutput>
			
			<cf_spContent type="#url.type#" method="picker" id="#spId#" enableAdminLinks="no" separator="">
			
			<cfoutput>
			</td>
			</tr>
			</cfoutput>
		
		</cfloop>
		
		<cfoutput>
		</table>
		</cfoutput>
	
	</cfif>
	
</cfif>

<cfoutput>
</body>
</html>
</cfoutput>
