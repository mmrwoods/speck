<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->
		
<cfif not request.speck.userHasPermission("spSuper,spKeywords")>

	<cfheader statuscode="403" statustext="Access Denied">
	<!--- <cf_spError error="ACCESS_DENIED" throwException="no"> --->
		
	<cfoutput>
	<h1>#listFirst(request.speck.buildString("ERR_ACCESS_DENIED"),".")#</h1>
	#listRest(request.speck.buildString("ERR_ACCESS_DENIED"),".")#
	</cfoutput>
	<cfabort>

</cfif>

<!--- Nasty, old skool, slap it all into the one template messing - code behind my arse! ;-) --->
<!--- ooh, this has really gotten messy, need to come back and tidy it up --->
<cfparam name="url.action" default="">
<cfparam name="url.keyword" default="">
<cfif len(url.action) and len(url.keyword)>

	<!--- get current keyword --->
	<cfquery name="qKeyword" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
		SELECT * 
		FROM spKeywords 
		WHERE keyword = '#url.keyword#'
	</cfquery>
	
	<cfif qKeyword.recordCount>
	
		<cfset qKeywords = request.speck.qKeywords> <!--- qKeywords references request.speck.qKeywords, just to unclutter the code a bit --->
		
		<cfswitch expression="#url.action#">
			
			<cfcase value="moveUp">
			
				<cfscript>
					moveTo = 0; // set to a value gt 0 if we find a destination
					if ( listLen(url.keyword,".") eq 1 ) {
						// find the nearest orphan with a lower sortId
						for ( i=1; i lte qKeywords.recordCount; i=i+1 ) {
							if ( qKeywords.keyword[i] eq url.keyword )
								break;
							else if ( listLen(qKeywords.keyword[i],".") eq 1 )
								moveTo = qKeywords.sortId[i];
						}
					} else {
						// find the nearest sibling with a lower sortId
						parent = listDeleteAt(url.keyword,listLen(url.keyword,"."),".");
						for ( i=1; i lte qKeywords.recordCount; i=i+1 ) {
							if ( qKeywords.keyword[i] eq url.keyword )
								break;
							else if ( listDeleteAt(qKeywords.keyword[i],listLen(qKeywords.keyword[i],"."),".") eq parent )
								moveTo = qKeywords.sortId[i];
						}
					}
				</cfscript>
				
				<cfif moveTo gt 0>
				
					<!--- ok, now move the keyword and all it's children (if any) --->
					<cfset distance = qKeyword.sortId - moveTo>
					
					<!--- get keyword family --->
					<cfquery name="qFamily" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
						SELECT sortId, keyword
						FROM spKeywords
						WHERE keyword = '#url.keyword#'
							OR keyword LIKE '#url.keyword#.%'
						ORDER BY sortId, keyword
					</cfquery>
					
					<!--- move keywords occupying destination sortIds --->
					<cfquery name="qMoveFromDestination" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
						UPDATE spKeywords
						SET sortId = sortId + #qFamily.recordCount#
						WHERE sortId >= #moveTo#
							AND sortId < #qFamily.sortId#
					</cfquery>
					
					<!--- move family to destination --->
					<cfquery name="qMoveToDestination" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
						UPDATE spKeywords
						SET sortId = sortId - #distance#
						WHERE keyword = '#url.keyword#'
							OR keyword LIKE '#url.keyword#.%'
					</cfquery>
					 
				</cfif>
				
			</cfcase>
			
			<cfcase value="moveDown">
			
				<!--- 
				Note: to move down, we'll re-use the move up code by getting the 
				move down destination sortId and then calling move up for the 
				keyword currently occupying that position.
				--->					
				<cfscript>
					moveTo = 0; // set to a value gt 0 if we find a destination
					if ( listLen(url.keyword,".") eq 1 ) {
						// find the nearest orphan with a higer sortId
						for ( i=qKeywords.recordCount; i gte 1; i=i-1 ) {
							if ( qKeywords.keyword[i] eq url.keyword )
								break;
							else if ( listLen(qKeywords.keyword[i],".") eq 1 )
								moveTo = qKeywords.sortId[i];
						}
					} else {
						// find the nearest sibling with a higer sortId
						parent = listDeleteAt(url.keyword,listLen(url.keyword,"."),".");
						for ( i=qKeywords.recordCount; i gte 1; i=i-1 ) {
							if ( qKeywords.keyword[i] eq url.keyword )
								break;
							else if ( listDeleteAt(qKeywords.keyword[i],listLen(qKeywords.keyword[i],"."),".") eq parent )
								moveTo = qKeywords.sortId[i];
						}
					}

				</cfscript>
				
				<cfif moveTo gt 0>
					<!--- get the keyword at the destination, and then move that keyword up --->
					<cfquery name="qMoveToKeyword" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
						SELECT keyword
						FROM spKeywords 
						WHERE sortId = #moveTo#
						ORDER BY sortId, keyword
					</cfquery>
					<!--- call move up code using cflocation because we can't use cffunction with CF5 --->
					<cflocation url="#cgi.script_name#?app=#request.speck.appName#&keyword=#qMoveToKeyword.keyword#&action=moveUp" addtoken="no">
					<cfabort>
				</cfif>
				
			</cfcase>					
		
		</cfswitch>
		
		<!--- update request.speck.qKeywords, application.speck.qKeywords and request.speck.keywords --->
		<cfquery name="request.speck.qKeywords" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
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

	<cflocation url="#cgi.script_name#?app=#request.speck.appName#" addtoken="no">
	
</cfif>
		
<cfoutput>
<!--- note: DOCTYPE required to force IE to render in standards mode and allow the use of tr:hover --->
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>#request.speck.buildString("A_TOOLBAR_MANAGE_KEYWORDS")#</title>
<link rel="stylesheet" href="#request.speck.adminStylesheet#" type="text/css">
<script src="/speck/javascripts/prototype.js" type="text/javascript"></script>
<script src="/speck/javascripts/scriptaculous.js" type="text/javascript"></script>
<!--- 
ae prompt - replacement for standard javascript prompt (IE7 default security settings disable javascript prompt) 
For more info see http://www.anyexample.com/webdev/javascript/ie7_javascript_prompt()_alternative.xml
--->
<script type="text/javascript">
// This is variable for storing callback function
var ae_cb = null;
 
// this is a simple function-shortcut
// to avoid using lengthy document.getElementById
function ae$(a) { return document.getElementById(a); }
 
// This is a main ae_prompt function
// it saves function callback 
// and sets up dialog
function ae_prompt(cb, q, a) {
	ae_cb = cb;
	//ae$('aep_t').innerHTML = document.domain + ' question:';
	ae$('aep_prompt').innerHTML = q;
	ae$('aep_text').value = a;
	ae$('aep_ovrl').style.display = ae$('aep_ww').style.display = '';
	ae$('aep_text').focus();
	ae$('aep_text').select();
}
 
// This function is called when user presses OK(m=0) or Cancel(m=1) button
// in the dialog. You should not call this function directly.
function ae_clk(m) {
	// hide dialog layers 
	ae$('aep_ovrl').style.display = ae$('aep_ww').style.display = 'none';
	if (!m)  
		ae_cb(null);  // user pressed cancel, call callback with null
	else
		ae_cb(ae$('aep_text').value); // user pressed OK 
}
</script>
<style type="text/css">
##aep_ovrl {
background-color: black;
-moz-opacity: 0.5; opacity: 0.5;
-ms-filter: "progid:DXImageTransform.Microsoft.Alpha(Opacity=50)";
filter: progid:DXImageTransform.Microsoft.Alpha(Opacity=50);
top: 0; left: 0; position: fixed;
width: 100%; height:100%; z-index: 99;
}
##aep_ww { position: fixed; z-index: 100; top: 0; left: 0; width: 100%; height: 100%; text-align: center;}
##aep_win { margin: 20% auto 0 auto; width: 400px; text-align: left;}
##aep_w {background-color: white; padding: 5px; border: 1px solid black; background-color: ##EEE;}
##aep_t {color: white; margin: 0 0 2px 3px; font-family: Arial, sans-serif; font-size: 10pt;}
##aep_text {width: 100%;margin: 5px 0;}
/*
##aep_w span {font-family: Arial, sans-serif; font-size: 10pt;}
##aep_w div {text-align: right; margin-top: 5px;}
*/
##aep_prompt {text-align:left;}
##aep_buttons {text-align:right;}
</style>
<!-- IE specific code: -->
<!--[if lte IE 7]> 
<style type="text/css"> 
##aep_ovrl { 
position: absolute; 
filter:alpha(opacity=50); 
top: expression(eval(document.body.scrollTop)); 
width: expression(eval(document.body.clientWidth)); 
} 
##aep_ww {  
position: absolute;  
top: expression(eval(document.body.scrollTop));  
} 
</style> 
<![endif]-->
<style type="text/css">
table.data_table tbody tr:hover { background: ##F2F5A9; }
</style>
</head>

<body>
<!-- ae_prompt HTML code -->
<div id="aep_ovrl" style="display: none;">&nbsp;</div>
<div id="aep_ww" style="display: none;">
<div id="aep_win"><div id="aep_t"></div>
<div id="aep_w"><div id="aep_prompt"></div>
<input type="text" id="aep_text" onKeyPress="if((event.keyCode==10)||(event.keyCode==13)) ae_clk(1); if (event.keyCode==27) ae_clk(0);">
<div id="aep_buttons"><input type="button" id="aep_ok" onclick="ae_clk(1);" value="OK"><input type="button" id="aep_cancel" onclick="ae_clk(0);" value="Cancel">
</div></div>
</div>
</div>
<!-- ae_prompt HTML code -->	
<h1>#request.speck.buildString("A_TOOLBAR_MANAGE_KEYWORDS")#</h1>
</cfoutput>

<!--- this little hack forces spContent to output all the admin functions, but without returning any content or outputting any links --->
<cf_spContent type="spKeywords" enableAdminLinks="yes" enableAddLink="no" maxRows="0">

<cfset bUserHasEditRole = request.speck.userHasPermission("spSuper,spEdit")>

<cfif bUserHasEditRole>
	
	<!--- now output the add keyword link - without the normal admin links styles --->
	<cfoutput>
	<a href="javascript:launch_add_keyword();">Add Section</a>
	</cfoutput>
	
</cfif>

<!--- now get the content query using spContentGet and we'll do a customised output with admin links where we want 'em --->
<!--- <cf_spContentGet type="spKeywords" orderby="sortId" r_qContent="qContent"> --->
<cf_spKeywordsGet source="spKeywords" r_qKeywords="qKeywords">

<!--- this is a hack to handle CF5's refusal to sort new keywords when we add them. In addition to adding a keyword to the
database, we also append it to the existing application.speck.qKeywords, but when we try and sort on that CF5 barfs and removes 
some added column values. Seems to be a CF5 problem with QofQ on queries that do not come directly from a cfquery resultset --->
<cflock scope="application" type="exclusive" timeout="5">
<cfset application.speck.qKeywords = duplicate(qKeywords)>
</cflock>

<cfoutput>
<script>
	function launch_add_keyword() {
		ae_prompt(callback_add_keyword,"Enter name for new section.", "");
	}
	function callback_add_keyword(child) {
		if ( child != null ) {
			var win = window.open("/speck/admin/admin.cfm?action=add&app=#request.speck.appName#&type=spKeywords&caption=Section&parent=&child=" + encodeURIComponent(child), "add_keyword", "status=yes,menubar=no,scrollbars=yes,resizable=yes,width=600,height=600,screenX=150,screenY=50,left=150,top=50");
			win.focus();
		}
	}
	function launch_add_child(parentKeyword,parentName) {
		parentArgument = parentKeyword;
		ae_prompt(callback_add_child,"Enter name for sub-section of '" + parentName + "'.", "");
	}
	function callback_add_child(child) {
		if ( child != null ) {
			var win = window.open("/speck/admin/admin.cfm?action=add&app=#request.speck.appName#&type=spKeywords&caption=Section&parent=" + parentArgument + "&child=" + encodeURIComponent(child), "add_keyword", "status=yes,menubar=no,scrollbars=yes,resizable=yes,width=600,height=600,screenX=150,screenY=50,left=150,top=50");
			win.focus();
		}
	}
	function load_keyword(keyword) {
		if ( window.opener && !window.opener.closed ) {
			window.opener.location.href = "#request.speck.appWebRoot#/?spKey=" + keyword;
			window.opener.focus();
		} else {
			alert("Failed to load page - main window has been closed.");
		}
		return false;
	}
</script>
<table cellpadding="1" cellspacing="1" border="0" width="100%" class="data_table">
<!--- <caption>Existing Keywords</caption> --->
<thead>
	<tr>
		<th>Name</th>
		<cfif isDefined("request.speck.portal")>
			<!--- <th>Layout</th> --->
			<th>Template</th>
			<th>Menu</th>
			<th>Sitemap</th>
			<th>Public</th>
			<th>&nbsp;</th>
		</cfif>
		<th>&nbsp;</th>
		<th>&nbsp;</th>
		<th>&nbsp;</th>
		<th>&nbsp</th>
	</tr>
</thead>
<tbody>
</cfoutput>

<cfif qKeywords.recordCount>

	<cfloop query="qKeywords">
	
		<cfset currentLevel = listLen(keyword,".")>
		
		<cfset bEditAccess = ( bUserHasEditRole or ( len(roles) and request.speck.userHasPermission(roles) ) )>
		
		<cfif currentLevel gt 1>
			<cfset keywordIndent = 25 * ( listLen(keyword,".") - 1) + 5>
		<cfelse>
			<cfset keywordIndent = 5>
		</cfif>

		<cfoutput>
		<tr <cfif currentRow mod 2 eq 1>class="alternateRow"</cfif>>
		</cfoutput>
		
			<cfif isDefined("request.speck.portal")> 
			
				<cfoutput>
				<td nowrap="yes" style="padding-left:#keywordIndent#px;" title="#keyword#">#name#</td>
				<!--- <td nowrap="yes" style="text-align:center"><cfif len(layout)>#layout#<cfelse>-- default --</cfif></td> --->
				<td nowrap="yes" style="text-align:center"><cfif len(template)>#template#<cfelseif isDefined("request.speck.portal.template") and len(request.speck.portal.template)>#request.speck.portal.template#<cfelse>text</cfif></td>
				<td nowrap="yes" style="text-align:center">#yesNoFormat(spMenu)#</td>
				<td nowrap="yes" style="text-align:center">#yesNoFormat(spSitemap)#</td>
				<td nowrap="yes" style="text-align:center"><cfif len(groups)>No<cfelse>Yes</cfif></td>
				<td nowrap="yes" style="text-align:center"><a href="javascript:return false;" onclick="load_keyword('#keyword#');return false;" title="View page #keyword# in main window">view</a></td>
				</cfoutput>
				
			<cfelse>
			
				<cfoutput>
				<td nowrap="yes" style="padding-left:#keywordIndent#px;" title="#keyword#">#name#</td>
				</cfoutput>
				
			</cfif>
			
			<cfif bEditAccess>
			
				<cfoutput>
				<td style="text-align:center"><cfif currentLevel lt request.speck.maxKeywordLevels><a href="javascript:launch_add_child('#keyword#','#jsStringFormat(name)#')" title="Add Sub-section">add</a><cfelse>&nbsp;</cfif></td>
				<td style="text-align:center"><a href="javascript:launch_edit('spKeywords','#spId#', '', '','Navigation Section')">edit</a></td>
				<td style="text-align:center"><a href="javascript:launch_delete('spKeywords','#spId#', '#jsStringFormat(name)#', '', '', 'Navigation Section');">delete</a></td>
				<td nowrap="yes" style="text-align:center">
					<a href="#cgi.script_name#?app=#request.speck.appName#&amp;keyword=#qKeywords.keyword#&amp;action=moveUp" title="Move Section Up"><img style="vertical-align:middle" src="/speck/admin/images/move_up.gif" width="9" height="9" border="0" /></a>
					<a href="#cgi.script_name#?app=#request.speck.appName#&amp;keyword=#qKeywords.keyword#&amp;action=moveDown" title="Move Section Down"><img style="vertical-align:middle" src="/speck/admin/images/move_down.gif" width="9" height="9" border="0" /></a>
				</td>
				</cfoutput>
				
			<cfelse>
			
				<cfoutput>
				<td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>
				</cfoutput>
				
			</cfif>
				
		<cfoutput>
		</tr>
		</cfoutput>
		
	</cfloop>
	
<cfelse>

	<cfif isDefined("request.speck.portal")>
		<cfset colspan = 8>
	<cfelse>
		<cfset colspan = 5>
	</cfif>
	
	<cfoutput><tr><td colspan="#colspan#" class="alternateRow" style="text-align:center"><em>No Keywords Found</em></td></tr></cfoutput>

</cfif>

<cfoutput>
</tbody>
</table>
</cfoutput>

<cfoutput>
</body>
</html>
</cfoutput>
