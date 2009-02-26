<cfsetting enablecfoutputonly="yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!---
Load all information from profile file into structure.  Profile file uses same file format
as getProfileString() and setProfileString() functions:

	; a comment - first character of line is ';'
	[section1]
	key1=value1
	key2=value2
	...
	keyN=valueN
	
	[section2]
	...
	[sectionN]

Blank lines are ignored.  Keys and values are trimmed.
--->

<cfparam name="attributes.context" default="">

<cfscript>
	if ( not isStruct(attributes.context) and isDefined("request.speck") )
		attributes.context = request.speck;
</cfscript>

<!--- Validate attributes --->
<cfloop list="file,variable" index="attribute">

	<cfif not isDefined("attributes.#attribute#")>
	
		<cf_spError error="ATTR_REQ" lParams="#attribute#" context="#attributes.context#">	<!--- Missing attribute --->
	
	</cfif>

</cfloop>

<!--- Try to open the file --->
<cftry>

	<cf_spFileRead file="#attributes.file#" variable="fileContent">
	
<cfcatch type="Any">

	<cf_spError error="FILE_NO_OPEN" lParams="#attributes.file#" context="#attributes.context#"> <!--- Error opening file --->

</cfcatch>
</cftry>

<!--- Filter out comments and empty lines --->
<cfset nl = chr(10) & chr(13)>
<cfset filteredFileContent = "">

<cfloop list="#fileContent#" index="line" delimiters="#nl#">

	<cfset line = trim(line)>
	
	<cfif (line neq "") and (left(line, 1) neq ";")>
	
		<cfset filteredFileContent = filteredFileContent & line & nl>
	
	</cfif>

</cfloop>

<!--- Build structure --->
<cfset st = structNew()>
<cfloop list="#filteredFileContent#" index="section" delimiters="[">

	<!--- Create a key in the structure for each section --->
	<cfset sectionName = spanExcluding(section, "]")>
	
	<cfif REFind("[^a-zA-Z0-9_-]", sectionName)>
	
		<cf_spError error="GPS_IL_SEC_NM" lParams="#attributes.file#,#sectionName#" context="#attributes.context#"> <!--- Illegal section name --->
	
	</cfif>
	
	<cfset "st.#sectionName#" = structNew()>
	
	<cfset lKeys = listRest(section, "]")> <!--- bluedragon 6.1 beta was giving error 'Problem occurred while parsing, "#listRest(section, "]"' when #listRest(section, "]")# was being used as the list attribute in cfloop --->
	
	<cfloop list="#lKeys#" index="line" delimiters="#nl#">
	
		<!--- <cfif ListLen(line, "=") ge 2> --->
		<!--- <cfif find("=",line)> --->
		
			<cfset "st.#sectionName#.#trim(listFirst(line, "="))#" = trim(listRest(line, "="))>
		
		<!--- </cfif> --->
	
	</cfloop>

</cfloop>

<!--- Copy structure into return variable --->
<cfif listLen(attributes.variable, ".") eq 1>

	<cfset "caller.#attributes.variable#" = duplicate(st)>
	
<cfelse>

	<cfset "#attributes.variable#" = duplicate(st)>

</cfif>
