<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- Validate attributes --->
<cfloop list="r_tidy,html" index="attribute">

	<cfif not isdefined("attributes.#attribute#")>
	
		<cf_spError error="ATTR_REQ" lParams="#attribute#">	<!--- Missing attribute --->
		
	</cfif>

</cfloop>

<cfscript>
	// check if the input includes a body tag, if not we assume we are dealing with a chunk of html rather than 
	// a complete html document and will have to remove html, head, body tags added by JTidy after parsing
	htmlBody = findNoCase("<body",attributes.html);

	// create Tidy instance
	tidy = createObject("java","org.w3c.tidy.Tidy");
	
	// set default tidy properties for Speck apps
	tidy.setDocType("omit");
	tidy.setShowWarnings(false);
	tidy.setTidyMark(false);
	tidy.setMakeClean(true);
	tidy.setMakeBare(true);
	tidy.setQuiet(false);
	tidy.setWord2000(true);
	tidy.setWraplen(1024);
	tidy.setXHTML(true);
	tidy.setLogicalEmphasis(true);
	tidy.setInputEncoding("UTF-16");
	tidy.setOutputEncoding("UTF-16");
	tidy.setDropFontTags(true);

	// TODO: read properties into a Properties object and store in application scope
	if ( fileExists(request.speck.appInstallRoot & "/config/jtidy.properties") ) {
		tidy.setConfigurationFromFile(request.speck.appInstallRoot & "/config/jtidy.properties");
	}

	// create an input stream
	if ( listFirst(request.speck.cfVersion) gte 6 ) {
		inString = attributes.html;
	} else {
		inString = createObject("java","java.lang.String");
		inString.init(attributes.html);
	}
	inBytes = inString.getBytes("UTF-16");
	inStream = createObject("java","java.io.ByteArrayInputStream");
	inStream.init(inBytes);
	
	// create an output stream
	outStream = createObject("java", "java.io.ByteArrayOutputStream");	
	outStream.init();
	
	// tidy the html
	tidy.parse(inStream, outStream);
	
	// convert the output stream to a string
	if ( listFirst(request.speck.cfVersion) gte 6 ) {
		outString = outStream.toString("UTF-16");
	} else {
		outString = outStream.toString("ISO-8859-1");
	}

	// close the streams
	inStream.close();
	outStream.close();
</cfscript>

<cfif trim(outString) eq "">

	<cfthrow message="cf_spTidy error: JTidy has returned an empty string">
	
<cfelseif htmlBody eq 0>

	<!--- 
	No html body element was found in the input, but JTidy always returns a complete html document, with 
	html, body etc. tags added as required. We'll rip out these added elements before returning the output.
	--->
	<cftry>
	
		<cfset startTidyBody = find("<body>", outString) + 6>
		<cfset endTidyBody = find("</body>", outString)>
		<cfset outString = mid(outString, startTidyBody, endTidyBody-startTidyBody)>
		
	<cfcatch><!--- do nothing ---></cfcatch>
	</cftry>

</cfif>

<!--- Return tidy html --->
<cfset "caller.#attributes.r_tidy#" = outString>