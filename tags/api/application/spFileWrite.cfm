<cfparam name="attributes.file">
<cfparam name="attributes.mode" default="664">
<cfparam name="attributes.output">

<!--- possible todo: add context attribute and run code based out outcome of cf version check rather than rely on try/catch --->
<!--- possible todo 2: use FileWriter cfc --->

<cftry>
	
	<!--- cfmx --->
	<cffile action="write" file="#attributes.file#" mode="#attributes.mode#" output="#attributes.output#" charset="utf-8">

<cfcatch>

	<!--- cf5 --->
	<cffile action="write" file="#attributes.file#" mode="#attributes.mode#" output="#attributes.output#">

</cfcatch>
</cftry>