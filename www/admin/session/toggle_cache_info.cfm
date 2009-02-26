<cfsetting enablecfoutputonly="Yes">

<cfheader name="Cache-Control" value="no-cache">
<cfheader name="Pragma" value="no-cache">

<cflock scope="session" type="exclusive" timeout="3" throwontimeout="Yes">
<cfscript>
	if ( session.speck.showCacheInfo ) {
		session.speck.showCacheInfo = false;
	} else {
		session.speck.showCacheInfo = true;
	}
</cfscript>
</cflock>

	