<cfsetting enablecfoutputonly="Yes">

<!--- durty hack to group properties together in admin forms --->

<cf_spPropertyHandler>


	<cf_spPropertyHandlerMethod method="validateAttributes">
		
		<cfset stPD.saveToDatabase = "no"> <!--- we just want to output some html, nothing to save --->
					
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="renderFormField">
	
		<cfparam name="request.speck.bFieldsetOpen" default="false">
		
		<cfif request.speck.bFieldsetOpen>
			
			<!--- close the fieldset --->
			<cfoutput>
			</table>
			</fieldset>
			</td></tr>
			</table>
			</td></tr>
			</cfoutput>
			<cfset request.speck.bFieldsetOpen = false>
		
		<cfelse>
		
			<!--- open the fieldset --->
			<cfoutput>
			<tr>
			<td>
			</cfoutput>
			
			<cfif stPD.required><cfoutput><span class="required">*</span></cfoutput></cfif>
			
			<cfoutput>
			#stPD.caption#
			</td>
			<td>
			<table cellpadding="0" cellspacing="0" width="100%"><tr><td>
			<fieldset class="#stPD.class#" style="#stPD.style#" id="#stPD.name#">
			</cfoutput>
			
			<cfif isDefined("stPD.legend") and len(stPD.legend)>
			
				<cfoutput><legend>#stPD.legend#</legend></cfoutput>
			
			</cfif>
			
			<cfif isDefined("stPD.hint") and len(stPD.hint)>
			
				<cfoutput><span class="fieldset_hint">#stPD.hint#</span></cfoutput>
			
			</cfif>
			
			<cfoutput>
			<table>
			</cfoutput>
			<cfset request.speck.bFieldsetOpen = true>
			
		</cfif>
	
	</cf_spPropertyHandlerMethod>
	
	
</cf_spPropertyHandler>
