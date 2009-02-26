<cfsetting enablecfoutputonly="yes">

<cfquery name="qNewsletterKeywords" dbtype="query">
	SELECT * FROM request.speck.qKeywords
	WHERE template = 'newsletter'
	ORDER BY sortId
</cfquery>

<cfif cgi.request_method eq "post" and not isDefined("actionErrors") and qNewsletterKeywords.recordCount>

	<cfif isDefined("url.username") and len(url.username)>
		
		<cfset variables.username = url.username>
	
	<cfelse>
	
		<cfset variables.username = form.username>
	
	</cfif>

	<cfquery name="qUser" datasource="#request.speck.codb#">
		SELECT spId 
		FROM spUsers
		WHERE username = '#lCase(variables.username)#'
	</cfquery>

	<cfquery name="qInsertSubscription" datasource="#request.speck.codb#">
		DELETE FROM NewsletterSubscribers
		WHERE id = '#qUser.spId#'
	</cfquery>

	<cfloop query="qNewsletterKeywords">
			
		<cfset elementName = replace(keyword,".","__","all")>

		<cfif isDefined("form.#elementName#") and evaluate("form.#elementName#") eq "on">
			
			<cfquery name="qInsertSubscription" datasource="#request.speck.codb#">
				INSERT INTO NewsletterSubscribers (id, keyword,confirmedAt)
				VALUES ('#qUser.spId#','#keyword#',#createODBCDateTime(now())#)
			</cfquery>
		
		</cfif>
		
	</cfloop>
	
</cfif>