<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spType
	name="Image"
	description="Image">
	
	<cf_spProperty
		name="caption"
		caption="Caption"
		type="Text"
		required="#attributes.context.getConfigString("types","image","caption_required","yes")#"
		displaySize="#attributes.context.getConfigString("types","image","caption_display_size","70")#"
		maxlength="250"
		finder="yes">
			
	<cf_spProperty
		name="original"
		caption="Original"
		type="Asset"
		extensions="png,gif,jpg,jpeg"
		required="yes"
		maxWidth="#attributes.context.getConfigString("types","image","original_max_width",600)#">
		
	<cf_spProperty
		name="originalWidth"
		caption="original width"
		type="Number"
		required="no"
		displaySize="0">
		
	<cf_spProperty
		name="originalHeight"
		caption="original height"
		type="Number"
		required="no"
		displaySize="0">		
		
	<cf_spProperty
		name="thumbnail"
		caption="Thumbnail"
		type="Asset"
		extensions="png,gif,jpg,jpeg"
		required="no"
		source="original"
		hint="A thumbnail will be generated automatically if you leave this field blank."
		maxWidth="#attributes.context.getConfigString("types","image","thumbnail_max_width",100)#">
			
	<cf_spProperty
		name="thumbnailWidth"
		caption="thumbnail width"
		type="Number"
		required="no"
		displaySize="0">
		
	<cf_spProperty
		name="thumbnailHeight"
		caption="thumbnailHeight"
		type="Number"
		required="no"
		displaySize="0">
		
		
	<cf_spHandler method="display">
	
		<cfparam name="attributes.thumbnail" default="no">
		<cfparam name="attributes.showCaption" default="yes">
		
		<cfoutput>
		<div class="image_display">
		</cfoutput>
	
		<cfif attributes.thumbnail>
		
			<cfoutput><img src="#content.thumbnail#" class="image_display_thumbnail" border="0" alt="#content.caption#" <cfif len(trim(content.thumbnailWidth))>width="#content.thumbnailWidth#" height="#content.thumbnailHeight#"</cfif> /></cfoutput>
		
		<cfelse>
		
			<cfoutput><img src="#content.original#" class="image_display_original" border="0" alt="#content.caption#" <cfif len(trim(content.originalWidth))>width="#content.originalWidth#" height="#content.originalHeight#"</cfif> /></cfoutput>
		
		</cfif>
		
		<cfif attributes.showCaption>

			<cfoutput><div class="image_display_caption">#content.caption#</div></cfoutput>

		</cfif>
		
		<cfoutput>
		</div>
		</cfoutput>
		
	</cf_spHandler>
			
		
	<cf_spHandler method="picker">
	
		<cfoutput><img src="#content.thumbnail#" border="0" alt="#content.caption#" <cfif len(trim(content.thumbnailWidth))>width="#content.thumbnailWidth#" height="#content.thumbnailHeight#"</cfif> /></cfoutput>
		
	</cf_spHandler>
	
	
	<cf_spHandler method="thumbnail">
	
		<cfparam name="attributes.showCaption" default="yes">
		<cfparam name="attributes.popup" default="yes">
		<cfparam name="attributes.gallery" default="yes">
		<cfparam name="attributes.target" default="_blank">
		<cfif isDefined("request.speck.portal.lightbox") and request.speck.portal.lightbox>
			<cfparam name="attributes.lightbox" default="true">
		<cfelse>
			<cfparam name="attributes.lightbox" default="false">
		</cfif>
		
		<cfif not isDefined("request.speck.spHandlerImageThumbnailPopup")> <!--- only write out the JS function once --->
			<cfoutput><script type="text/javascript">
				<!--
				//<![CDATA[
				function image_thumbnail_popup(id) {
					if (typeof Lightbox == "undefined") {
						var imageWindow = window.open("/speck/types/image/popup.cfm?app=#request.speck.appName#&id=" + id,"image_popup","menubar=no,scrollbars=yes,resizable=yes,width=10,height=10,screenX=150,screenY=100,left=150,top=100");
						imageWindow.focus();
					}
				}
				function image_gallery_popup(ids,index) {
					if (typeof Lightbox == "undefined") {
						var imageWindow = window.open("/speck/types/image/gallery.cfm?app=#request.speck.appName#&ids=" + ids + "&index=" + index,"image_popup","menubar=no,scrollbars=yes,resizable=yes,width=10,height=10,screenX=150,screenY=100,left=150,top=100");
						imageWindow.focus();
					}
				}
				//]]>
				//-->
			</script></cfoutput>
			<cfset request.speck.spHandlerImageThumbnailPopup = true>
		</cfif>
		
		<cfoutput>
		<div class="image_thumbnail">
		</cfoutput>
		
		<cfif len(content.original)>

			<cfscript>
				
				onclick = "";
				rel = "";
				
				if ( attributes.lightbox ) {
					rel = "lightbox";
					if ( attributes.gallery ) {
						// generate a unique lightbox group name from spContent attributes
						// note: spContent passes its attribute collection to spHandler
						groupName = "";
						for ( key in caller.attributes ) {
							if ( isSimpleValue(caller.attributes[key]) ) {
								groupName = groupName & key & "_" & caller.attributes[key] & "_";
							}
						}
						rel = rel & "[" & hash(groupName) & "]";
					} 
				}
				
				if ( attributes.popup ) {
					if ( attributes.gallery and caller.content.recordCount gt 1 ) { 
						// get a list of ids to pass to the gallery script
						// note: caller.content is the entire content query for the current spContent call
						ids = valueList(caller.content.spId);
						onclick = "image_gallery_popup('#ids#','#content.spRowNumber#');return false;";
					} else {
						// simple popup window, no gallery
						onclick = "image_thumbnail_popup('#content.spId#');return false;";
					}
				}
				
			</cfscript>
		
			<cfoutput><a <cfif len(onclick)>onclick="#onclick#"</cfif> <cfif len(rel)>rel="#rel#"</cfif> href="#content.original#" target="#attributes.target#" <cfif len(content.caption)>title="#content.caption#"</cfif>><img src="#content.thumbnail#" class="image_thumbnail_thumbnail" border="0" alt="#content.caption#" title="view larger image (opens in new window)" <cfif len(trim(content.thumbnailWidth))>width="#content.thumbnailWidth#" height="#content.thumbnailHeight#"</cfif> /></a></cfoutput>
		
		<cfelse>
		
			<cfoutput><img src="#content.thumbnail#" class="image_thumbnail_thumbnail" border="0" alt="#content.caption#" <cfif len(trim(content.thumbnailWidth))>width="#content.thumbnailWidth#" height="#content.thumbnailHeight#"</cfif> /></cfoutput>
		
		</cfif>
		
		<cfif attributes.showCaption>

			<cfoutput><div class="image_thumbnail_caption">#content.caption#</div></cfoutput>

		</cfif>
		
		<cfoutput>
		</div>
		</cfoutput>
		
	</cf_spHandler>
	
	
	<cf_spHandler method="popup">
	
		<cfparam name="attributes.showCaption" default="yes">
		<cfparam name="attributes.stylesheet" default="">
		
		<cfif isNumeric(content.originalWidth)>
			
			<cfset windowWidth = content.originalWidth + 50>
			<cfset windowHeight = content.originalHeight + 50>
			
			<cfif attributes.showCaption>
				<cfset windowHeight = windowHeight + 50>
			</cfif>
			
			<cfif windowHeight gt 600>
				<cfset windowHeight = 600>
			</cfif>
			
			<cfif windowHeight gt 750>
				<cfset windowHeight = 750>
			</cfif>
		
		<cfelse>
			
			<cfset windowWidth = 600>
			<cfset windowHeight = 750>
			
		</cfif>

		<cfoutput>
		<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
			"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
		<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
		<head>
		<title>#content.caption#</title>
		<script type="text/javascript">
			window.resizeTo(#windowWidth#,#windowHeight#);
		</script>
		</cfoutput>
		
		<cfif len(attributes.stylesheet)>

			<cfoutput><link rel="stylesheet" type="text/css" href="#attributes.stylesheet#" /></cfoutput>

		</cfif>
		
		<cfoutput>
		</head>
		<body style="background: ##ffffff; margin: 10px; text-align:center;">
		<div class="image_popup">
		<img src="#content.original#" class="image_popup_original" border="0" alt="#content.caption#" <cfif isNumeric(content.originalWidth)>width="#content.originalWidth#" height="#content.originalHeight#"</cfif> />
		</cfoutput>
		
		<cfif attributes.showCaption>

			<cfoutput><div class="image_popup_caption">#content.caption#</div></cfoutput>

		</cfif>
		
		<cfoutput>
		</div>
		</cfoutput>
		
		<cfoutput>
		</body>
		</html>
		</cfoutput>
		
	</cf_spHandler>
	
	
	<cf_spHandler method="contentPut">
	
		<!--- get image dimensions --->
	
		<cfset fs = request.speck.fs>
			
		<!--- assets are uploaded to a temp directory before being copied to either the secureassets or assets directory --->
		<cfdirectory action="LIST" 
			directory="#request.speck.appInstallRoot##fs#tmp" 
			filter="#content.spId#*" 
			sort="type DESC" 
			name="qTmpFiles">
		
		<cfloop query="qTmpFiles">
			
			<cfset filePath = request.speck.appInstallRoot & fs & "tmp" & fs & name>
			<cfset propertyName = listGetAt(listLast(filePath,fs),2,"_")>
			
			<cftry>

				<cf_spImageInfo file="#filePath#" r_stImageInfo="stImageInfo">
				
				<cfset "content.#propertyName#Width" = stImageInfo.width>
				<cfset "content.#propertyName#Height" = stImageInfo.height>
				
			<cfcatch>
			
				<cf_spDebug msg="Failed to obtain image dimensions<br>#cfcatch.message#<br>#cfcatch.detail#">
			
			</cfcatch>
			</cftry>
	
		</cfloop>

	</cf_spHandler>
	
		
</cf_spType>
