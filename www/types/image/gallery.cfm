<cfsetting enablecfoutputonly="Yes">

<cfparam name="url.ids" default="">
<cfparam name="url.index" default="1">

<!--- validate input --->
<cfif not isNumeric(url.index)>

	<cfoutput>
	<h1>Error: invalid input</h1>
	<p>Index is not a number</p>
	</cfoutput>
	<cfabort>
	
<cfelseif not len(url.ids)>

	<cfoutput>
	<h1>Error: missing input</h1>
	<p>No image ids provided</p>
	</cfoutput>
	<cfabort>

<cfelse>
	
	<cfloop list="#url.ids#" index="i">
	
		<cfif not request.speck.isUUID(i)>
		
			<cfoutput>
			<h1>Error: invalid input</h1>
			<p>One or more id is not valid</p>
			</cfoutput>
			<cfabort>
		
		</cfif>
	
	</cfloop>

</cfif>

<cfset currentId = listGetAt(url.ids,url.index)>
<cfset noOfImages = listLen(url.ids)>

<!--- default window width and height --->
<cfset windowWidth = 600>
<cfset windowHeight = 600>

<cfscript>
	// see if we can find a stylesheet
	defaultStylesheet = "";
	fs = request.speck.fs;
	if ( structKeyExists(request.speck,"portal") and len(request.speck.portal.popupStylesheet) ) {
		defaultStylesheet = request.speck.portal.popupStylesheet;
	} else if ( fileExists(request.speck.appInstallRoot & fs & "www" & fs & "stylesheets" & fs & "popup.css") ) {
		defaultStylesheet = "/stylesheets/popup.css";
	} else if ( fileExists(request.speck.appInstallRoot & fs & "www" & fs & "styles" & fs & "popup.css") ) {
		defaultStylesheet = "/styles/popup.css";
	}
</cfscript>

<cfparam name="request.speck.config.types.image.gallery_stylesheet" default="#defaultStylesheet#">
<cfparam name="request.speck.config.types.image.gallery_header" default="">
<cfparam name="request.speck.config.types.image.gallery_footer" default="">

<cfset stylesheet = request.speck.config.types.image.gallery_stylesheet>
<cfset header = request.speck.config.types.image.gallery_header>
<cfset footer = request.speck.config.types.image.gallery_footer>


<!--- calculate required dimensions --->
<cf_spContentGet 
	type="Image" 
	id="#url.ids#" 
	properties="originalWidth,originalHeight"
	r_qContent="qImages">
	
<cfset maxWidth = 400>
<cfset maxHeight = 400>
<cfloop query="qImages">
	
	<cfif originalWidth gt maxWidth>
		<cfset maxWidth = originalWidth>
	</cfif>
	
	<cfif originalHeight gt maxHeight>
		<cfset maxHeight = originalHeight>
	</cfif>
	
</cfloop>

<cfif ( maxWidth + 50 ) gt windowWidth>
	<cfset windowWidth = maxWidth + 50>
</cfif>

<cfset headerImgHeight = 0>
<cfset footerImgHeight = 0>
<cftry>
	<cfif len(header) and reFindNoCase("height=\""[0-9]+\""",header)>
		<cfset start = findNoCase("height=",header)>
		<cfset heightHtml = mid(header,start,findNoCase("""",header,start+9))>
		<cfset headerImgHeight = reReplace(heightHtml,"[^0-9]","","all")>
	</cfif>
<cfcatch><!--- do nothing ---></cfcatch>
</cftry>
<cftry>
	<cfif len(footer) and reFindNoCase("height=\""[0-9]+\""",footer)>
		<cfset start = findNoCase("height=",header)>
		<cfset heightHtml = mid(header,start,findNoCase("""",footer,start+9))>
		<cfset footerImgHeight = reReplace(heightHtml,"[^0-9]","","all")>
	</cfif>
<cfcatch><!--- do nothing ---></cfcatch>
</cftry>

<cfif ( maxHeight + 130 + headerImgHeight + footerImgHeight) gt windowHeight>
	<cfset windowHeight = maxHeight + 130 + headerImgHeight + footerImgHeight>
</cfif>

<!--- quick hack, TODO: come back and tidy up the code to determine the window dimensions --->
<cfif windowHeight gt 600>
	<cfset windowHeight = 600>
</cfif>

<cfif windowHeight gt 750>
	<cfset windowHeight = 750>
</cfif>
		
<cfoutput>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>
<title>Image Gallery</title>
<script type="text/javascript">
	window.resizeTo(#windowWidth#,#windowHeight#);
</script>
</cfoutput>

<cfif len(stylesheet)>

	<cfoutput><link rel="stylesheet" type="text/css" href="#stylesheet#" /></cfoutput>

</cfif>
		
<cfoutput>
</head>
<body style="background: ##ffffff; margin: 10px; text-align:center;">
<div class="image_gallery_header" align="center">#header#</div>
<div style="clear:both;"></div>
<div class="image_gallery" align="center">
<div class="image_gallery_pageinfo">
<div style="width:20%;float:left;text-align:left;">
</cfoutput>

<cfif url.index gt 1>
	<cfoutput><a href="#cgi.script_name#?app=#request.speck.appName#&ids=#url.ids#&index=#evaluate("#url.index#-1")#">&laquo; previous</a></cfoutput>
<cfelse>
	<cfoutput><del>&laquo; previous</del></cfoutput>
</cfif>

<cfoutput>
</div>
<div style="width:60%;float:left;text-align:center;">
[Image #url.index# of #noOfImages#]
</div>
<div style="width:20%;float:left;text-align:right;">
</cfoutput>

<cfif url.index lt noOfImages>
	<cfoutput><a href="#cgi.script_name#?app=#request.speck.appName#&ids=#url.ids#&index=#evaluate("#url.index#+1")#">next &raquo;</a></cfoutput>
<cfelse>
	<cfoutput><del>next &raquo;</del></cfoutput>
</cfif>

<cfoutput>
</div>
</div>
</cfoutput>

<cf_spCacheThis cacheName = "image_gallery_#replace(currentId, "-", "", "all")#">

	<cf_spContent
		id="#currentId#"
		type="Image"
		method="display"
		enableAdminLinks="no">
	
</cf_spCacheThis>

<cfoutput>
<div class="image_gallery_paging">
</cfoutput>

<cfloop from="1" to="#noOfImages#" index="i">

	<cfif url.index eq i>
	
		<cfoutput>
		#i#
		</cfoutput>
	
	<cfelse>
	
		<cfoutput>
		<a href="#cgi.script_name#?app=#request.speck.appName#&ids=#url.ids#&index=#i#">[#i#]</a>
		</cfoutput>
	
	</cfif>

</cfloop>

<cfoutput>
</div> <!--- image_gallery_paging --->
</div> <!--- image_gallery --->
<div class="image_gallery_footer" align="center">#footer#</div>
</body>
</html>
</cfoutput>