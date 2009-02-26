<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfparam name="attributes.error" default="NO_ERR_DESC">
<cfparam name="attributes.lParams" default="">
<cfparam name="attributes.logOnly" default="no">
<cfparam name="attributes.throwException" default="yes"> <!--- throw an exception using cfthrow? --->
<cfparam name="attributes.context" default="">

<cfscript>
	if ( not isStruct(attributes.context) )
		if ( isDefined("request.speck") )
			attributes.context = request.speck;
		else
			attributes.context = structNew();
			
	if ( not isDefined("attributes.context.appName") ) {
		// see if we can get appName from cf_spApp tag data
		if ( findNoCase("CF_SPAPP",getBaseTagList()) ) {
			appTagData = getBaseTagData("CF_SPAPP"); // I know this isn't necessary in cfmx, but it might be in CF5 and I haven't got a copy installed for testing at the mo
			if ( isDefined("appTagData.stApp.appName") ) { // bad bad boy, slap on the wrist for this one, we really shouldn't know about structures inside an ancestor tag ;-)
				attributes.context.appName = appTagData.stApp.appName;
			} else {
				attributes.context.appName = "unknownSpeckApp"; // an error has occurred in spApp before stApp has been created
			}
		} else {
			attributes.context.appName = "unknownSpeckApp";
		}
	}

	callerTag = cgi.script_name; // default caller to script name
	for (i=1; i le listLen(getBaseTagList()); i=i+1 ) {
		thisTag = listGetAt(getBaseTagList(),i);
		if ( thisTag neq "CF_SPERROR" and left(thisTag,3) eq "CF_" ) {
			callerTag = thisTag;
			break;
		}
	}
</cfscript>

<cftry>

	<cfif not isDefined("attributes.context.buildString") or not isDefined("attributes.context.strings")>
	
		<!--- better nab the buildString function and default strings from server.speck --->
		<cflock scope="SERVER" type="READONLY" timeout="3">
		<cfset attributes.context.buildString = duplicate(server.speck.buildString)>
		<cfset attributes.context.strings = duplicate(server.speck.strings)>
		</cflock>
		
	</cfif>
	
	<cfset message = attributes.context.buildString("ERR_GEN_MESSAGE", callerTag, attributes.context)>

	<cfset description = attributes.context.buildString("ERR_" & attributes.error, attributes.lParams, attributes.context)>

	<cfset logText = callerTag & ": " & description>

<cfcatch type="ANY">

	<cfset message = "Sorry, spError encountered an error while trying to report a previous error">

	<cfsavecontent variable="description"><cfoutput><b>spError Attributes:</b><br></cfoutput><cfdump var=#attributes#><cfoutput><p><b>Error:</b><br></cfoutput><cfdump var=#cfcatch#></cfsavecontent>

	<cfset logText = callerTag & ": " & message>
	
</cfcatch>
</cftry>

<cflog text = "#logText#"
	file = "#attributes.context.appName#"
	type = "error"
	application = "no"> 

<cfif not attributes.logOnly>

	<cfif attributes.throwException>
	
		<!--- 
		note: coldfusion seems to convert & to &amp; in messages and detail when throwing exceptions, except when the & is at the start of a named html entity reference.
		We need to use &#44; to send commas as part of a parameter in the lParams attribute, so we'll go through the rigmarole of un-escaping &#44; here before calling cfthrow.
		--->
		<cfset message = replace(message,"&##44;",",","all")>
		<cfset description = replace(description,"&##44;",",","all")>
	
		<cfthrow errorcode="#attributes.error#" message="#message#" detail="#description#" type="speckError">
		
	<cfelse>
		
		<cfoutput><h3>#message#</h3>#description#</cfoutput>
		<cfabort>
	
	</cfif>

</cfif>
