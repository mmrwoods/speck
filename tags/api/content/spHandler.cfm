<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!---
Description:

	Called by content type method handlers to iterate through content items and set up the "content" structure, which contains
	the following keys:
	
	- spId			UUID
	- spRevision	Revision number
	- spLabel		Label used by site administrators to identify content item
	- spCreated		Date content item (not just the current revision) created
	- spUpdated		Date last updated
	- spUpdatedBy	User who last saved content item
	- spKeywords	"/" separated list of content item keywords, sorted alphabetically ASC
	- spChangeId	Id of change object (if any) this revision is assigned to
	- spFlags		Reserved for future use?
	- spRowNumber	Current row number
	- spType		Content type
	- spSequenceId	An sequence number assigned to the content item when it was created.
	
	and
	
	all content type properties.
	
	If the attribute updateContent is passed to the caller, the closing handler tag will copy any changes made to content
	type properties in the calling tag back into the original query.  This attribute is usually specified in contentGet and
	contentPut methods.

Usage:

	<handler script
		method = "spTypeDefinition|method name"
		r_stType = "variable name"
		qContent=#query#
		type="string"
		separator="string"
		columns=number
		updateContent="yes|no">
	
		<cf_spType
			...>
			
			<cf_spProperty
				...>
				
			<cf_spHandler method="name">
		
				... handler code
			
			</cf_spHandler>
			
		</cf_spType>
	
Attributes:	
	
	Usually passed through to the caller from the content tag.
	
	qContent(query, required):			Query containing content items to iterate over.
	type(string, required):				Content type name.
	separator(string, optional):		Default "<BR>".  HTML string to insert between consecutive content items.
	columns(number,optional):			Default 1.  Arrange content items into this many columns.
	updateContent(boolean,optional):	Default no. Copy any changes made to content type properties in the calling tag back into the original query.

--->

<cfif thisTag.executionMode eq "START">

	<cf_spDebug msg="Caller method #caller.attributes.method#, this handler's method is #attributes.method#">
	
	<!--- Check we are placed inside cf_spType tag --->
	<cfif listFind(getBaseTagList(), "CF_SPTYPE") eq 0>
	
		<cf_spError error="PR_NOT_IN_TYPE" lParams="">	<!--- Must be placed inside cf_spType tag --->
	
	</cfif>
	
	<!--- Only execute if spType method eq attributes.method --->
	<cfparam name="attributes.method" default="">
	
	<cfif caller.attributes.method eq "spTypeDefinition">
		
		<!--- associate method info with content type --->
		<cfassociate basetag="CF_SPTYPE" datacollection="methods">
		<cfexit method="EXITTAG">
	
	<cfelseif caller.attributes.method neq attributes.method>
		
		<!--- skip over any methods that don't match the method name passed when calling the type template --->
		<cf_spDebug msg="Skipping method #attributes.method#">
		<cfexit method="EXITTAG">
	
	</cfif>
	
	<!--- if method is refresh, execute the code in the method body without creating a content structure --->
	<cfif attributes.method eq "refresh">
	
		<!--- request.speck doesn't exist, set up the context for the method... --->
		<cfset caller.context = caller.attributes.context>
		
	<cfelseif attributes.method eq "validate">
	
		<!--- validate method should be passed a single content item --->
		<cfif not isdefined("caller.attributes.content")>
		
			<cf_spError error="ATTR_REQ" lParams="content">	<!--- Missing attribute --->
			
		</cfif>
		
		<!--- make the content available to the method body --->
		<cfset caller.content = caller.attributes.content>
		
		<!--- create an empty errors list, code in validate method should append to this list --->
		<!--- TODO: replace these lists of errors with arrays (in spDefault and all properties types too!) --->
		<cfset caller.lErrors = "">
	
	<cfelse>
	
		<!--- check for required params --->
		
		<cfloop list="qContent,type" index="attribute">
	
			<cfif not isdefined("caller.attributes.#attribute#")>
			
				<cf_spError error="ATTR_REQ" lParams="#attribute#">	<!--- Missing attribute --->
				
			</cfif>
	
		</cfloop>
		
		<cfparam name="caller.attributes.separator" default="<br>">
		<cfparam name="caller.attributes.columns" default="1">
		<cfparam name="caller.attributes.updateContent" default="no">
		<cfparam name="caller.attributes.startRow" default="1">
		<cfparam name="caller.attributes.endRow" default=#caller.attributes.qContent.recordCount#>
		
		<!--- exit if no records --->
		
		<cfif caller.attributes.qContent.recordCount eq 0>
		
			<cfexit method="EXITTAG">
			
		</cfif>
		
		<cfscript>
		
			// set up first row in caller's scope
			caller.content = structNew();
			caller.content.spType = caller.attributes.type;
			caller.content.spRowNumber = caller.attributes.startRow - 1; // getNextRow() will increment the row number
			caller.content.spStartRow = caller.attributes.startRow;
			caller.content.spEndRow = caller.attributes.endRow;
			request.speck.getNextRow();
			
			// we need to know whether admin links are being displayed (variables set here are referenced from spContentAdmin)
			if ( isDefined("caller.caller.bShowEditAdmin") 
				and ( caller.caller.bShowEditAdmin or caller.caller.bShowEditPromoAdmin or caller.caller.bShowReviewAdmin ) ) {
				bRenderAdminLinks = true; 
			} else
				bRenderAdminLinks = false;
			
		</cfscript>
		
		<!--- If more than one column, open table --->
		<cfif caller.attributes.columns gt 1>
		
			<cfset rowNumber = 1>
			<cfset columnNumber = 1>
		
			<cfoutput><table class="spHandler" summary="for layout purposes only"><tr class="spHandlerRow1"><td class="spHandlerColumn1"></cfoutput>
			
		<cfelseif bRenderAdminLinks>
		
			<!--- always wrap content in an admin span that we can use to hightlight the item(s) to be edited etc. --->
			<cfoutput><span style="display:block;" class="spContentAdmin spClearfix"></cfoutput>
		
		</cfif>
		
		<!--- show admin buttons if enabled --->
		<!--- <cfset void = request.speck.renderAdminButtons()> --->
		<!--- temporarily replace function with custom tag call until we mod spContent or spContentGet so qContent has spRemoved and spPromoted columns --->
		<cfif bRenderAdminLinks>
			<!--- only call module if necessary --->
			<cfmodule template="/speck/api/content/spContentAdmin.cfm">
		</cfif>
	
	</cfif>
	
<cfelse>
	
	<!--- close tag --->
	<cfif attributes.method eq "refresh">
	
		<cfexit method="exittag">
		
	<cfelseif attributes.method eq "validate">

		<cfif isDefined("caller.attributes.r_lErrors")>
	
			<cfset "caller.caller.#caller.attributes.r_lErrors#" = caller.lErrors>
	
		</cfif>
		
		<cfexit method="exittag">
	
	</cfif>
	
	<cfif caller.attributes.updateContent>
	
		<cfscript>
		
			lCols = caller.attributes.qContent.columnList;
			while (lCols neq "") {
				col = listFirst(lCols); lCols = listRest(lCols);
				// if (left(col,2) neq "sp") // old condition
				// note: spLabel and spKeywords can now be updated
				if ( not listFindNoCase("spId,spRevision,spCreated,spCreatedBy,spUpdated,spUpdatedBy",col) )
					void = querySetCell(caller.attributes.qContent, col, caller.content[col], caller.content.spRowNumber);
			}
		
		</cfscript>
	
	</cfif>
	
	<cfif caller.content.spRowNumber lt caller.attributes.endRow>
	
		<!--- set up next row in caller's scope --->
		<cfset void = request.speck.getNextRow()>
		
		<!--- If more than one column, set up next table data or row --->
		<cfif caller.attributes.columns gt 1>
		
			<cfset columnNumber = columnNumber + 1>
		
			<cfoutput></td></cfoutput>
			
			<cfset checkValue = (caller.content.spRowNumber - caller.attributes.startRow) + 1>
			<cfif checkValue mod caller.attributes.columns eq 1>
			
				<!--- End of row, increment row number, set column nnumber back to 1, close tr element, open new tr element--->
				<cfset rowNumber = rowNumber + 1>
				<cfset columnNumber = 1>
				<cfoutput></tr><tr class="spHandlerRow#rowNumber#"></cfoutput>
			
			</cfif>
			
			<cfoutput><td class="spHandlerColumn#columnNumber#"></cfoutput>
		
		<cfelse>
		
			<!--- insert separator --->
			<cfoutput>#caller.attributes.separator#</cfoutput>
			
			<cfif bRenderAdminLinks>
			
				<!--- close admin span and open new one if admin links are on --->
				<cfoutput></span></cfoutput>
				<cfoutput><span style="display:block;" class="spContentAdmin spClearfix"></cfoutput>			

			</cfif>
		
		</cfif>
		
		<!--- show admin buttons if enabled --->
		<!--- <cfset void = request.speck.renderAdminButtons()> --->
		<cfif bRenderAdminLinks>
			<!--- only call module if necessary --->
			<cfmodule template="/speck/api/content/spContentAdmin.cfm">			
		</cfif>
		
		<!--- repeat tag body --->
		<cfexit method="LOOP">
		
	<cfelse>
	
		<!--- If more than one column, close off table data and last row --->
		<cfif caller.attributes.columns gt 1>
		
			<!--- close current table data --->
			<cfoutput></td></cfoutput>
			
			<cfset remainder = caller.attributes.endRow mod caller.attributes.columns>
			
			<cfif remainder neq 0>
			
				<!--- add extra <td></td> pairs to finish off row --->
				<cfloop from="1" to="#remainder#" index="i">
				
					<!--- we still need to increment the column number --->
					<cfset columnNumber = columnNumber + 1>				
				
					<cfoutput><td class="spHandlerColumn#columnNumber#">&nbsp;</td></cfoutput>

				</cfloop>
			
			</cfif>
			
			<!--- End of row and table --->
			<cfoutput></tr></table></cfoutput>
			
		<cfelseif bRenderAdminLinks>
		
			<!--- close the admin span --->
			<cfoutput></span></cfoutput>
		
		</cfif>
		
		<cfexit>
		
	</cfif>
	
</cfif>

