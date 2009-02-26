<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!---
	Description:
	
		Targets of links to assets that are secure (including assets of content items that aren't live) or need their mime type specified.

	Usage:
	
		/speck/properties/asset/asset.cfm?type=string&property=string&id=uuid&filename=string&app=string[&mimetype=string]
		
	Attributes:	
		
		type(string, required):				Content type.
		property(string, required):		Property name.
		id(UUID, required):					Content item spId.
		filename(string, required):		Normally will have worked this out in contentGet, pass via url to avoid looking it up a second time.
		app(string, required):				Application name, i.e referrer's request.speck.appName.
		mimeType(string, optional):		Force Content-type header to be set to this mimeType, e.g. application/octect-stream for files to download.
		disposition(string, optional):	Default "inline". Value for type parameter of content-disposition header.
 --->

<!--- Validate attributes --->
<cfloop list="id,property,app,type,filename" index="attribute">

	<cfif not isDefined("url.#attribute#")>
	
		<cf_spError error="ATTR_REQ" lParams="#attribute#">	<!--- Missing attribute --->
	
	</cfif>

</cfloop>

<cfparam name="url.mimetype" default="">
<cfparam name="url.disposition" default="inline">
<cfparam name="url.revision" default="tip">

<cfif not listFindNoCase("inline,attachment",url.disposition)>

	<!--- we don't support any other content-disposition --->
	<cfset url.disposition = "inline">

</cfif>

<!--- Get type info to find out whether property is secure or not --->
<cfmodule template=#request.speck.getTypeTemplate(url.type)# r_stType="stType">

<!--- 	RULE:  The only asset file that can be browsed directly is a live content item's non-secure asset property.  All other asset files
		are stored in the secureasset directory (don't want the public seeing asset files that haven't gone live yet).  The asset
		propertyHandler's promote action will copy (or delete if promoting revision 0) asset files into the asset directory whenever a content
		item goes live, the prime reason being to reduce CF server load caused by this script. --->
		
<cfscript>
	// get secureKeys for this property if exists
	secureKeys = "";
	for(i=1; i le arrayLen(stType.props); i = i + 1)
		if ( stType.props[i].name eq url.property ) {
			if ( structKeyExists(stType.props[i], "secureKeys") )
				secureKeys = stType.props[i].secureKeys;
			break;
		}
		
	// what properties do we need? (we may need more than just the asset property 
	// itself if we are to use the value of a database column to determine access)
	if ( len(secureKeys) and left(secureKeys, 1) eq "$" )
		properties = url.property & "," & listFirst(secureKeys, "$");
	else
		properties = url.property;
</cfscript>

<!--- Get the content item --->
<cf_spContentGet type="#url.type#" id="#url.id#" properties="#properties#" revision="#url.revision#" r_qContent="qContent">

<cfif qContent.recordCount neq 1>

	<cf_spError logOnly="yes" error="P_ASSET_NO_CONTENT" lParams="#url.type#,#url.id#">
	
	<!--- asset not found --->
	<cfheader statuscode="404" statustext="Not Found">
	<cfoutput><h1>Not Found</h1></cfoutput>
	<cfexit>
	
</cfif>

<!--- Reject unauthorised requests for secure content --->
<cfif not len(secureKeys)>

	<cfset bPublicAsset = true>

<cfelse>

	<!--- Secured property --->
	
	<cfset bAssetAccess = false> <!--- set to true if user has access --->
	
	<!--- 
	RULE: 
	If the secure key is set to "inherit" and the application keywords query contains a groups column (as with the portal framework applications), 
	then inherit the access control from the application keywords set for the containing content item. Otherwise, if the secure key starts with 
	a '$', e.g '$PROPERTYNAME' the name of the session variable that must be defined to access the asset is stored in the property PROPERTYNAME.  
	If the secure key doesn't start with a '$' e.g. 'VARIABLENAME' then the name of the session variable is VARIABLENAME. 
	--->
			
	<cfif secureKeys eq "inherit" and isDefined("request.speck.qKeywords.groups")>
	
		<cfif len(qContent.spKeywords)>
		
			<!--- obtain secure keys from keywords for content item --->
			<cfquery name="qKeywords" dbtype="query">
				SELECT groups 
				FROM request.speck.qKeywords
				WHERE keyword IN (#listQualify(qContent.spKeywords,"'")#)
			</cfquery>
			
			<cfscript>
				lAccessGroups = valueList(qKeywords.groups);
				if ( not listLen(lAccessGroups) ) {
					bAssetAccess = true; // no access restrictions
				} else if ( request.speck.session.auth eq "logon" and isDefined("request.speck.session.groups") ) {
					lUserGroups = structKeyList(request.speck.session.groups);
					// loop over groups, if group found in users group list, set access to true
					while (lAccessGroups neq "" and not bAssetAccess) {
						group = listFirst(lAccessGroups);
						lGroups = listRest(lAccessGroups);
						if ( listFindNoCase(lAccessGroups,group) )
							bAssetAccess = true;
					}
				}
			</cfscript>
			
		<cfelse>
		
			<cfset bAssetAccess = true>
		
		</cfif>
	
	<cfelse>
	
		<cfif left(secureKeys, 1) eq "$">
		
			<cfset secureKeys = qContent[listFirst(secureKeys, "$")][1]>
		
		</cfif>
		
		<cflock scope="session" type="readonly" timeout="3">
		<cfloop list="#secureKeys#" index="secureKey">
			<cfif structKeyExists(session,"#secureKey#")>
				<cfset bAssetAccess = true>
				<cfbreak>
			</cfif>
		</cfloop>
		</cflock>
		
	</cfif>
	
	<cfif not bAssetAccess>
	
		<cfset message = request.speck.buildString("P_ASSET_NOT_AUTHORISED", "")>
		
		<cfoutput>
		<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
			"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
		<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
		<head>
		<title>#message#</title>
		</head>
		<body>
		<h1>#message#</h1>
		</body>
		</html>
		</cfoutput>
	
		<cf_spError error="P_ASSET_NOT_AUTHORISED" lParams="#session.speck.user#,#url.property#,#qContent.spLabel[1]#">
	
	</cfif>
	
</cfif>

<cfscript>
	idHash = lsParseNumber("0" & REReplace(left(url.id, 5), "[^0-9]", "", "ALL")) mod 100;
	fs = request.speck.fs;
	revision = qContent.spRevision[1];

	if ( secureKeys eq "" and request.speck.session.viewLevel eq "live" and request.speck.session.viewDate eq "" and url.revision eq "tip" ) {
		// get asset from public assets directory
		assetDir = request.speck.appInstallRoot & fs & "www" & fs & "assets" & fs & idHash & fs & id & "_" & url.property & fs;
	} else {
		// get asset from secure assets directory
		do {
			assetDir = request.speck.appInstallRoot & fs & "secureassets" & fs & idHash & fs & url.id & "_" & revision & "_" & url.property & fs;
			revision = revision - 1;
		} while ((revision ge -1) and not fileExists(assetDir & url.filename));
	}
	
	if ( len(url.mimetype) ) {
		mimeType = url.mimetype;
	} else if ( REFind("\.[A-Za-z]+$", url.filename) ) {
		mimeType = request.speck.getMIMEType(listLast(url.filename,"."));
	} else {
		mimeType = "application/octet-stream";
	}
</cfscript>

<cfif revision eq -1>

	<cfabort>
	
</cfif>

<cfif not fileExists(assetDir & url.filename)>

	<cf_spError logOnly="yes" error="P_ASSET_NOT_FOUND" lParams="#url.type#,#url.property#,#assetDir##url.filename#">

	<!--- asset not found --->
	<cfheader statuscode="404" statustext="Not Found">
	<cfoutput><h1>Not Found</h1></cfoutput>
	<cfexit>
	
<cfelseif isDefined("request.speck.xSendFile") and request.speck.xSendFile>

	<cfheader name="X-SendFile" value="#assetDir##url.filename#">
	<cfheader name="Content-type" value="#mimeType#">
	<cfheader name="Content-disposition" value="#url.disposition#; filename=#replace(url.filename," ","_","all")#">
	<cfheader name="Cache-control" value="must-revalidate">
	
<cfelseif listFirst(request.speck.cfVersion) eq 5>
	
	<cfdirectory action="list" directory="#assetDir#" filter="#url.filename#" name="qAssetDir">
	<cfif qAssetDir.recordCount>
		<cfheader name="Content-length" value="#qAssetDir.size[1]#">
	</cfif>
	<cfheader name="Content-disposition" value="#url.disposition#; filename=#replace(url.filename," ","_","all")#">
	<cfcontent file="#assetDir##url.filename#" type="#mimeType#">

<cfelse>

	<cflock scope="SERVER" type="EXCLUSIVE" timeout="5" throwontimeout="true">
	<cfif not structKeyExists(server.speck,"assetThreadCount")>
		<cfset server.speck.assetThreadCount = 0>
	</cfif>
	<cfset server.speck.assetThreadCount = server.speck.assetThreadCount + 1>
	<cfset assetThreadCount = server.speck.assetThreadCount>
	</cflock>
	
	<cftry>
	
		<cfif assetThreadCount gt 5>

			<cfheader statuscode="503" statustext="Service Unavailable">

			<cfoutput>
			<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
				"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
			<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
			<head>
			<title>Server Too Busy</title>
			</head>
			<body>
			<h1>Server Too Busy</h1>
			<p>Sorry, the file cannot be downloaded at the moment because the server is too busy. 
			Please try again in a few minutes.</p>
			</body>
			</html>
			</cfoutput>
		
			<cfthrow message="Asset download failed. Thread limit reached.">
			
		</cfif>
		
		<cfscript>
			// Use a buffer to read data from the file and write to the output stream, 
			// rather than allow cfcontent read the entire file into memory before 
			// flushing it to the output stream. This wouldn't normally be of any benefit 
			// until you look at downloading fairly large files, but by using java to handle 
			// sending the file, I can run other code like keeping track of the thread count 
			// and aborting requests when the thread count is greater than the thread limit.
			
			// Thanks to Christian Cantrell for blogging about byte arrays and 
			// writing binary data using ColdFusion and to Steve Savage for his 
			// example of how to stream a flash movie in ColdFusion. 
			//
			// Byte Arrays: http://weblogs.macromedia.com/cantrell/archives/2004/01/byte_arrays_and_1.cfm
			// Write Out Binary Data to Browser: http://weblogs.macromedia.com/cantrell/archives/2003/06/using_coldfusio.cfm
			// Streaming FLV files: http://www.realitystorm.com/experiments/flash/streamingFLV/index.cfm
			
			// TODO: allow range requests to support resuming of interrupted downloads
			
			bufferSize = 4096; // 4K buffer
			
			// get PageContext, ServletResponse and ServletOutputStream objects
			context = getPageContext();
			context.setFlushOutput(false);
			response = context.getResponse().getResponse(); // get ServletResponse object
			out = response.getOutputStream(); // get ServletOutputStream object
			
			fileObject = createObject("java","java.io.File").init("#replace(assetDir,"\","\\","all")##url.filename#");
			fileInputStream = createObject("java", "java.io.FileInputStream").init(fileObject);
			bufferedInputStream = createObject("java","java.io.BufferedInputStream").init(fileInputStream);
			
			byteClass = createObject("java", "java.lang.Byte"); //
			buffer = createObject("java","java.lang.reflect.Array").newInstance(byteClass.TYPE, bufferSize); 
			
			response.setContentType(mimeType);
			response.setContentLength(fileObject.length());
			response.setHeader("Content-disposition","#url.disposition#; filename=#replace(url.filename," ","_","all")#");
		    
			do {
				len = bufferedInputStream.read(buffer,0,bufferSize);
				if (len neq -1) {
					out.write(buffer, 0, len);
					out.flush();
				}
			} while (len neq -1); // keep going until there's nothing left to read.
			
		    out.flush();
		    out.close();
		</cfscript>
		
	<cfcatch>
	
		<cflock scope="SERVER" type="EXCLUSIVE" timeout="10" throwontimeout="true">
		<cfset server.speck.assetThreadCount = server.speck.assetThreadCount - 1>
		</cflock>
		
		<cfrethrow>
	
	</cfcatch>
	</cftry>

	<cflock scope="SERVER" type="EXCLUSIVE" timeout="10" throwontimeout="true">
	<cfset server.speck.assetThreadCount = server.speck.assetThreadCount - 1>
	</cflock>

</cfif>