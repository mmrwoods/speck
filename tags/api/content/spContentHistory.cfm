<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfparam name="attributes.id" default="">
<cfparam name="attributes.type" default="">
<cfparam name="attributes.maxRows" default="-1"> <!--- max rows to show (complete history query is always returned so we can show "more" link if necessary) --->


<!--- get history --->
<cfquery name="qHistory" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
	SELECT *
	FROM spHistory x
	WHERE id = '#attributes.id#'
	ORDER BY ts DESC, revision DESC, promoLevel DESC
</cfquery>
				
<cfif qHistory.recordCount>
		
	<cfparam name="attributes.displayPerPage" default="#qHistory.recordCount#"> <!--- default displayPerPage to all rows --->
		
	<cfset startRow = 1>
	
	<cfif attributes.maxRows neq -1>
	
		<cfset endRow = attributes.maxRows>
		
	<cfelse>
	
		<cfset endRow = qHistory.recordCount>
	
	</cfif>
	
	<cfif attributes.displayPerPage neq qHistory.recordCount>
	
		<cfmodule template="/speck/api/content/spContentPaging.cfm"
			page="#request.speck.buildString("A_PAGING_PAGE_STRING","")#"
			first="#request.speck.buildString("A_PAGING_FIRST_PAGE","")#"
			previous="#request.speck.buildString("A_PAGING_PREV_PAGE","")#"
			next="#request.speck.buildString("A_PAGING_NEXT_PAGE","")#"
			last="#request.speck.buildString("A_PAGING_LAST_PAGE","")#"
			totalRows=#qHistory.recordCount#
			displayPerPage=#attributes.displayPerPage#>
			
		<cfif len(stPaging.menu)>
		
			<cfoutput>#stPaging.menu#<br></cfoutput>
			
			<cfset startRow = stPaging.startRow>
		
			<cfset endRow = stPaging.endRow>
		
		</cfif>
	
	</cfif>
	
	<!--- get promotion level strings... --->
	<cfscript>
		editString = request.speck.buildString("A_PROMOLEVEL_EDIT");
		reviewString = request.speck.buildString("A_PROMOLEVEL_REVIEW");
		liveString = request.speck.buildString("A_PROMOLEVEL_LIVE");
	</cfscript>
	
	<cfoutput>
	<script>
		function historyWarning() {
			if ( document.speditform )
				#request.speck.buildString("A_HISTORY_LOAD_ITEM_ONCLICK")#
			else
				return true;
		}	
	</script>
	<table width="100%">
		<tr>
		<td width="60">#request.speck.buildString("A_HISTORY_CAPTION")#</td>
		<td>
		
			<table width="100%">
				<tr>
				<td>#request.speck.buildString("A_HISTORY_REVISION_CAPTION")#</td>
				<td>#request.speck.buildString("A_HISTORY_LEVEL_CAPTION")#</td>
				<td>#request.speck.buildString("A_HISTORY_EDITOR_CAPTION")#</td>
				<!--- <td>#request.speck.buildString("A_HISTORY_CHANGEID_CAPTION")#</td> --->
				<td>#request.speck.buildString("A_HISTORY_TIMESTAMP_CAPTION")#</td>
				</tr></cfoutput>
				
				<cfscript>
					qsAppend = REReplaceNoCase(cgi.query_string,"&{0,1}action=[^&]*","");
					qsAppend = REReplaceNoCase(qsAppend,"&{0,1}revision=[0-9][^&]*","");
					qsAppend = REReplace(qsAppend,"^&","");
				</cfscript>				
				
				<cfloop query="qHistory" startrow="#startRow#" endrow="#endRow#">

					<cfoutput><tr <cfif qHistory.currentRow mod 2 eq 1>class="alternateRow"</cfif>></cfoutput>
					
					<!--- don't link to revision 0 --->
					<cfif revision eq 0>
					
						<cfoutput><td>#revision#</td></cfoutput>
					
					<cfelse>
					
						<cfoutput><td><a href="#cgi.SCRIPT_NAME#?action=edit&revision=#revision#&#qsAppend#" onclick="return historyWarning();" title="#request.speck.buildString("A_HISTORY_LOAD_ITEM_CAPTION")#">#revision#</a></td></cfoutput>
					
					</cfif>
					
					<cfoutput>
					<td>#replaceList(promoLevel,"1,2,3","#editString#,#reviewString#,#liveString#")#</td>
					<td>#editor#</td>
					<!--- <td>#changeid#</td> --->
					<td>#dateFormat(ts,"yyyy-mm-dd")# #timeFormat(ts,"HH:mm:ss")#</td>
					</tr></cfoutput>
				
				</cfloop>
				
				<cfif attributes.maxRows gt 0 and attributes.maxRows lt qHistory.recordCount>
				
					<cfoutput><tr><td colspan="4" align="right"><a href="#cgi.SCRIPT_NAME#?action=history&previousaction=#url.action#&#qsAppend#" 
						onclick="#request.speck.buildString("A_HISTORY_LOAD_FULL_ONCLICK")#" 
						title="#request.speck.buildString("A_HISTORY_LOAD_FULL_CAPTION","#attributes.maxRows#,#qHistory.recordCount#")#">#request.speck.buildString("A_HISTORY_LOAD_FULL_LINK")#</a></td></tr></cfoutput>
						
				</cfif>
				
			<cfoutput>
			</table>	
		</td>
		</tr>
	</table>
	</cfoutput>
	
</cfif>