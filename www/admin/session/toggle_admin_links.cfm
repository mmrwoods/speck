<cfsetting enablecfoutputonly="Yes">

<cfheader name="Cache-Control" value="no-cache">
<cfheader name="Pragma" value="no-cache">

<cflock scope="session" type="exclusive" timeout="3" throwontimeout="Yes">
<cfscript>
	if ( session.speck.showAdminLinks ) {
		session.speck.showAdminLinks = false;
	} else {
		session.speck.showAdminLinks = true;
	}
</cfscript>
</cflock>
	