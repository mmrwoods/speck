<cfparam name="attributes.file">
<cfparam name="attributes.variable">

<!--- possible todo: add context attribute and run code based out outcome of cf version check rather than rely on try/catch --->
<!--- possible todo 2: use FileReader cfc --->

<cftry>
	
	<!--- cfmx --->
	<cffile action="read" file="#attributes.file#" variable="caller.#attributes.variable#" charset="utf-8">

<cfcatch>

	<!--- cf5 --->
	<cffile action="read" file="#attributes.file#" variable="caller.#attributes.variable#">

</cfcatch>
</cftry>