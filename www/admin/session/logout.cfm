<cfsetting enablecfoutputonly="Yes" showdebugoutput="No">

<cflock scope="session" type="exclusive" timeout="3" throwontimeout="Yes">
<cfset void = structDelete(session,"speck")>
</cflock>