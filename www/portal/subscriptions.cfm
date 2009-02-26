<cfsetting enablecfoutputonly="yes">

<cfquery name="qNewsletterKeywords" dbtype="query">
	SELECT * FROM request.speck.qKeywords
	WHERE template = 'newsletter'
	ORDER BY sortId
</cfquery>

<cfif qNewsletterKeywords.recordCount>

	<cfoutput>
	<fieldset>
	<legend>Subscriptions</legend>
	<table cellpadding="2" cellspacing="2" border="0">
	<tr>
	<td><label for="newsletters">Email Newsletters</label></td>
	<td style="vertical-align:middle">
	</cfoutput>

	<cfif len(url.username)>

		<cfquery name="qSubscriptions" datasource="#request.speck.codb#">
			SELECT keyword 
			FROM NewsletterSubscribers
			WHERE id = '#qUser.spId#'
		</cfquery>
		
		<cfset lSubscriptions = valueList(qSubscriptions.keyword)>
		
		<cfloop query="qNewsletterKeywords">
		
			<cfset elementName = replace(keyword,".","__","all")>
			<cfif cgi.request_method eq "post" or not listFindNoCase(lSubscriptions,keyword)>
				<cfparam name="form.#elementName#" default="off">
			<cfelse>
				<cfparam name="form.#elementName#" default="on">
			</cfif>
			
			<cfoutput>
			<input type="checkbox" name="#elementName#" <cfif evaluate("form.#elementName#") eq "on"> checked="yes"</cfif> />#name#
			</cfoutput>
	
		</cfloop>
		
	<cfelse>
	
		<cfloop query="qNewsletterKeywords">
		
			<cfset elementName = replace(keyword,".","__","all")>
			<cfif cgi.request_method eq "post">
				<cfparam name="form.#elementName#" default="off">
			<cfelse>
				<cfparam name="form.#elementName#" default="on">
			</cfif>
		
			<cfoutput>
			<input type="checkbox" name="#elementName#" <cfif evaluate("form.#elementName#") eq "on"> checked="yes"</cfif> />#name#
			</cfoutput>

		</cfloop>

	</cfif>
	
	<cfoutput>
	</td>
	</tr>
	</table>
	</fieldset>
	</cfoutput>

</cfif>