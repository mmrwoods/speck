<cfsetting enablecfoutputonly="Yes">

<cfheader name="Cache-Control" value="no-cache">
<cfheader name="Pragma" value="no-cache">

<cfparam name="url.viewDate" default=""> <!--- pass date in "YYYY:MM:DD HH:MM:SS" format, empty string means now --->

<cfif request.speck.enableRevisions>

	<cflock scope="session" type="exclusive" timeout="3" throwontimeout="Yes">
	<cfscript>
		if ( lsIsDate(url.viewDate) ) {
			session.speck.viewDate = lsParseDateTime(url.viewDate);
			session.speck.showAdminLinks = false;
			session.speck.showCacheInfo = false;
		} else {
			session.speck.viewDate = "";
		}
	</cfscript>
	</cflock>

</cfif>


	