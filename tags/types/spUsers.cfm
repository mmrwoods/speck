<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!---
Base content type for portal application users - can be extended to add extra properties per application.
This is a work in progress - it's not pretty and is subject to change.
--->

<cf_spType
	name="spUsers"
	caption="User"
	description="Portal Application Users"
	revisioned="no"
	labelRequired="no">
	
	<cf_spProperty
		name="username"
		caption="Username"
		type="Text"
		required="yes"
		unique="yes"
		match="^[A-Za-z0-9_\.]+$"
		displaySize="35"
		maxlength="50"
		index="yes"
		finder="yes">
	
	<cf_spProperty
		name="fullname"
		caption="Full&nbsp;Name"
		type="Text"
		required="yes"
		displaySize="35"
		maxlength="100"
		finder="yes">

	<cf_spProperty
		name="email"
		caption="Email"
		type="Text"
		email="yes"
		required="yes"
		displaySize="35"
		maxlength="100"
		index="yes"
		finder="yes">
		
	<cf_spProperty
		name="password"
		caption="Password"
		type="Text"
		required="yes"
		displaySize="35"
		maxlength="100">
		
	<cf_spProperty
		name="newsletter"
		caption="Newsletter"
		type="Boolean"
		required="no"
		defaultValue="1"
		inputType="checkbox"
		register="yes"
		hint="Subcribe to email newsletter. You can unsubscribe at any time.">

	<cf_spProperty
		name="notes"
		caption="Notes"
		type="Html"
		required="no"
		displaySize="30,3"
		maxlength="4000"
		roles="spSuper,spUsers">
		
	
	<cf_spHandler method="display">
	
		<cfoutput>#content.username#</cfoutput>
		
	</cf_spHandler>
	
	
	<cf_spHandler method="contentPut">
	
		<!--- update newsletter subscribers table (note: we have a newsletter subscribers table to allow non-users subscribe) --->
		
		<!--- always start by removing any existing subscription with either the email address of this user before or after update --->
		
		<cfset lDeleteSubscribers = content.email>
		
		<!--- get user before update - note: contentPut method always called before actual update/insert happens in spContentPut --->
		<cfquery name="qUserBeforePut" datasource="#request.speck.codb#">
			SELECT email FROM spUsers WHERE spId = '#content.spId#'
		</cfquery>
		
		<cfif qUserBeforePut.recordCount and qUserBeforePut.email neq content.email>
			<cfset lDeleteSubscribers = listAppend(lDeleteSubscribers,qUserBeforePut.email)>
		</cfif>
		
		<cfif len(lDeleteSubscribers)>
	
			<!--- delete existing email address from newsletter subscribers table --->
			<cfquery name="qDeleteNewsletterSubscriber" datasource="#request.speck.codb#">
				DELETE FROM spNewsletterSubscribers WHERE email IN (#listQualify(lDeleteSubscribers,"'")#)
			</cfquery>
			
		</cfif>
		
		<cfif content.newsletter and len(content.email)>
		
			<!--- subscribe user to newsletter --->
			<cfquery name="qInsertNewsletterSubscriber" datasource="#request.speck.codb#">
				INSERT INTO spNewsletterSubscribers (fullname, email) VALUES ('#content.fullname#','#content.email#')
			</cfquery>
			
		</cfif>
		
		<cfif request.speck.session.user eq content.username>
			
			<!--- update pre-defined speck session keys if session user matches this user --->
			<cflock scope="session" type="exclusive" throwontimeout="false" timeout="5">
			<cfset session.speck.fullName = content.fullName>
			<cfset session.speck.email = content.email>
			<cfset session.speck.password = content.password>
			</cflock>
		
		</cfif>
	
	</cf_spHandler>
	
	
	<cf_spHandler method="delete">
	
		<cfif len(content.email)>
		
			<!--- delete from newsletter subscribers table --->
			<cfquery name="qDeleteNewsletterSubscriber" datasource="#request.speck.codb#">
				DELETE FROM spNewsletterSubscribers WHERE email = '#content.email#'
			</cfquery>
		
		</cfif>
	
	</cf_spHandler>
	
		
</cf_spType>
