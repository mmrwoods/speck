<cfsetting enablecfoutputonly="Yes">

<cfheader name="Cache-Control" value="no-cache">
<cfheader name="Pragma" value="no-cache">

<cfparam name="url.viewLevel" default=""> <!--- one of edit, review, live --->

<cfif request.speck.enablePromotion and listFindNoCase("Edit,Review,Live",url.viewLevel)>

	<cflock scope="session" type="exclusive" timeout="3" throwontimeout="Yes">
	<cfscript>
		// automatically toggle the admin links if we're moving to/from live level
		if ( session.speck.viewLevel eq "live" and url.viewLevel neq "live" ) {
			session.speck.showAdminLinks = true;
		} else if ( session.speck.viewLevel neq "live" and url.viewLevel eq "live" ) {
			session.speck.showAdminLinks = false;
		}
		session.speck.viewLevel = url.viewLevel;
	</cfscript>
	</cflock>

</cfif>