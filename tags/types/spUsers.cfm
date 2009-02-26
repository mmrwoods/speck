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
	
		<!--- do stuff when putting a user --->
	
	</cf_spHandler>
	
	
	<cf_spHandler method="delete">
	
		<!--- do stuff when deleting a user --->
	
	</cf_spHandler>
	
		
</cf_spType>
