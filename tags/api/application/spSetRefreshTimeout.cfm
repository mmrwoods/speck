<!--- 
This tag is only called from CFMX and exists because CF5 barfs when it tries 
to parse a template with a cfsetting call containing a requesttimeout attribute 
--->

<!--- Check we are placed inside cf_spApp tag - this tag is only to be used when setting a timeout while an application is initialising --->
<cfset lBaseTags = getBaseTagList()>
<cfif listFind(lBaseTags, "CF_SPAPP") eq 0>

	<cfthrow message="cf_spSetRefreshTimeout can only be called from within cf_spApp - do not use this tag in your own applications">

</cfif>

<cfsetting requesttimeout="300">