<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2005 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfscript>
	// unfortunately, the context isn't always provided as an attribute when this template is called as a module, so...
	if ( structKeyExists(attributes,"context") ) {
		getConfigString = attributes.context.getConfigString;
	} else {
		getConfigString = request.speck.getConfigString;
	}
	// possible TODO: update calls to type handler templates to always pass a context, and update spType to throw an exception if context not found??
</cfscript>

<cf_spType
	name="Event"
	description="Event"
	keywordTemplates="#getConfigString("types","event","keyword_templates")#">
	
 	<cf_spProperty
		name="title"
		caption="Title"
		type="Text"
		required="yes"
		maxlength="250"
		displaySize="75"
		unique="#attributes.context.getConfigString("types","event","title_unique","yes")#"
		index="yes">
	
	<cf_spProperty
		name="startDate"
		caption="Start&nbsp;Date"
		type="Date"
		required="yes"
		richEdit="yes">
	
	<cf_spProperty
		name="endDate"
		caption="End&nbsp;Date"
		type="Date"
		required="no"
		richEdit="yes">
	
	<cf_spProperty
		name="times"
		caption="Time(s)"
		type="Text"
		required="no"
		maxlength="250"
		displaySize="75"
		richEdit="no">
		
	<cf_spProperty
		name="venue"
		caption="Venue"
		type="Text"
		required="yes"
		displaySize="75"
		maxlength="250"
		richEdit="no">	
			
 	<cf_spProperty
		name="summary"
		caption="Summary"
		type="Html"
		required="no"
		displaySize="70,5"
		maxlength="500"
		richEdit="no"
		hint="A summary will generated automatically from the description if you leave this field blank.">		

 	<cf_spProperty
		name="description"
		caption="Description"
		type="Html"
		required="yes"
		displaySize="70,20"
		fckHeight="400"
		fckFontFormats="#attributes.context.getConfigString("types","event","content_fck_font_formats","")#"
		maxlength="32000"
		richEdit="yes"
		safeText="#attributes.context.getConfigString("types","event","content_safe_text","yes")#"
		forceParagraphs="#attributes.context.getConfigString("types","event","content_force_paragraphs","yes")#">
		
	<cf_spProperty
		name = "mainImage"
		caption = "Image"
		type = "Asset"
		extensions="png,gif,jpg,jpeg"
		maxWidth="#attributes.context.getConfigString("types","event","main_image_max_width",300)#">
		
	<!--- hidden property --->
	<cf_spProperty
		name = "mainImageDimensions"
		caption = "Image Dimensions"
		type = "Text"
		required = "no"
		maxlength="10"
		displaySize="0">			
		
	<cf_spProperty
		name = "thumbnailImage"
		caption = "Thumbnail"
		type = "Asset"
		extensions="png,gif,jpg,jpeg"
		source="mainImage"
		hint="A thumbnail will be generated automatically if you add an image and leave this field blank."
		maxWidth="#attributes.context.getConfigString("types","event","thumbnail_image_max_width",100)#">	
	
	<!--- hidden property --->
	<cf_spProperty
		name = "thumbnailImageDimensions"
		caption = "Thumbnail Dimensions"
		type = "Text"
		required = "no"
		maxlength="10"
		displaySize="0">			
				
 	<cf_spProperty
		name="documents"
		caption="Attached Documents"
		type="Picker"
		contentType="Document"
		required="no"
		dependent="yes"
		maxSelect="#attributes.context.getConfigString("types","event","documents_max_select",5)#">
		
		
	<cf_spHandler method="dump">
	
		<cfdump var=#content#>
	
	</cf_spHandler>
	
	
	<cf_spHandler method="picker">
	
		<cfoutput>
		<strong>#content.title#</strong><br />
		#content.startDate# <cfif len(content.endDate)> - #content.endDate#</cfif>, #content.venue#
		</cfoutput>
	
	</cf_spHandler>
	
	
	<cf_spHandler method="print">
	
		<cfparam name="attributes.docHeader" default=""> <!--- deprecated --->
		<cfparam name="attributes.docFooter" default=""> <!--- deprecated --->
		<cfparam name="attributes.header" default="#attributes.docHeader#">
		<cfparam name="attributes.footer" default="#attributes.docFooter#">
		<cfparam name="attributes.stylesheet" default="">
		
		<cfoutput>
		<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
		<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
		<meta name="robots" content="noindex, nofollow">
		<head>
		<title>#content.title#</title>
		</cfoutput>
		
		<cfif len(attributes.stylesheet)>
		
			<cfoutput><link rel="stylesheet" type="text/css" href="#attributes.stylesheet#" /></cfoutput>
		
		</cfif>

		<cfoutput>
		</head>
		<body onload="window.print();">
		<div class="event_print_header">#attributes.header#</div>
		<div style="clear:both;"></div>
		<div class="event_print">
		</cfoutput>	
	
		<cfparam name="attributes.showImage" default="yes" type="boolean">
		<cfparam name="attributes.titleElement" default="h3">
	
		<cfscript>
			// get dates as dates (stored as ISO-8601 date string in db, i.e. YYYY-MM-DD)
			startDate = createDate(listFirst(content.startDate,"-"),listGetAt(content.startDate,2,"-"),listLast(content.startDate,"-"));
			if ( len(content.endDate) )
				endDate = createDate(listFirst(content.endDate,"-"),listGetAt(content.endDate,2,"-"),listLast(content.endDate,"-"));
		</cfscript>	

		<cfoutput>
		<#attributes.titleElement# class="event_print_title">#content.title#</#attributes.titleElement#>
		<div class="event_print_dates">#dateFormat(startDate,"DD MMMM YYYY")#<cfif len(content.endDate)> - #dateFormat(endDate,"DD MMMM YYYY")#</cfif></div>
		</cfoutput>
		
		<cfif len(content.times)>
			
			<cfoutput>
			<div class="event_print_times">#content.times#</div>
			</cfoutput>
		
		</cfif>
		
		<cfif attributes.showImage and len(trim(content.mainImage))>
			<cfscript>
				if ( listLen(content.mainImageDimensions) eq 2  )
					imageDimensions = 'width="#listFirst(content.mainImageDimensions)#" height="#listLast(content.mainImageDimensions)#"';
				else
					imageDimensions = "";						
			</cfscript>
			<cfoutput><img src="#content.mainImage#" class="event_print_image" #imagedimensions# alt="Image for event titled '#content.title#'" /></cfoutput>
		</cfif>
		
		<cfoutput>
		<div class="event_print_description">
		#content.description#
		</div>
		</div> <!--- class="event_print" --->
		<div class="event_print_footer">#attributes.footer#</div>
		</body>
		</html>
		</cfoutput>
	
	</cf_spHandler> <!--- end of print method --->
	
	
	<cf_spHandler method="summary">

		<cfscript>
			cssClass = "event_summary";
			if ( content.spRowNumber eq content.spStartRow ) {
				cssClass = cssClass & " first_row";
			}
			if ( content.spRowNumber eq content.spEndRow ) {
				cssClass = cssClass & " last_row";
			}
			if ( content.spRowNumber mod 2 eq 0 ) {
				cssClass = cssClass & " even_row";
			} else {
				cssClass = cssClass & " odd_row";
			}
		</cfscript>
		
		<cfoutput><div class="#cssClass#"></cfoutput>
	
		<cfparam name="attributes.showImage" default="yes" type="boolean">
		<cfparam name="attributes.linkImage" default="yes" type="boolean">
		<cfparam name="attributes.embedImage" default="no" type="boolean">
		<cfparam name="attributes.readMoreCaption" default="&raquo;&nbsp;more information">
		<cfparam name="attributes.titleElement" default="h3">
		<cfparam name="attributes.viewEventTooltip" default="view event details">
		<cfparam name="attributes.dynamicTooltip" default="yes" type="boolean">
		<cfparam name="attributes.replaceKeywordInUrl" default="no">
		<!--- use label as identifier when generating url to view event (default to value of seoUrls portal setting if exists, otherwise default false) --->
		<cfparam name="attributes.labelIdentifier" default="#request.speck.getConfigString("portal","settings","seoUrls",false)#" type="boolean">
		
		<cfset viewEventTooltip = attributes.viewEventTooltip>
		
		<cfif attributes.dynamicTooltip>
		
			<cfset viewEventTooltip = viewEventTooltip & " '#replace(reReplace(content.title,"<[^>]+>","","all"),"""","","all")#'">
				
		</cfif>
		
		<cfif attributes.labelIdentifier and len(content.spLabel)>
			<cfset urlId = content.spLabel>
		<cfelse>
			<cfset urlId = content.spId>
		</cfif>
		
		<cfif attributes.replaceKeywordInUrl and len(content.spKeywords)>
			
			<!--- replace the keyword in the url with the first valid one from content.spKeywords --->
			<cfset viewEventKeyword = listFirst(content.spKeywords)>

			<cfif structKeyExists(request.speck,"portal") and structKeyExists(request.speck.types.event,"keywordTemplates") and len(request.speck.types.event.keywordTemplates)>
			
				<!--- get a list of keywords where the event templates are used, we should only use these keywords if possible --->
				<cfquery name="qValidKeywords" dbtype="query">
					SELECT keyword 
					FROM request.speck.qKeywords 
					WHERE template IN (#listQualify(request.speck.types.event.keywordTemplates,"'")#)
				</cfquery>
				
				<cfset lValidKeywords = valueList(qValidKeywords.keyword)>
				
				<cfif len(lValidKeywords) and not listFind(lValidKeywords,viewEventKeyword) and listLen(content.spKeywords) gt 1>
				
					<!--- first keyword in spKeywords doesn't look like it can display an article, try and find the first one that can --->
					<cfloop list="#listRest(content.spKeywords)#" index="keyword">
						
						<cfif listFind(lValidKeywords,keyword)>
						
							<cfset viewEventKeyword = keyword>
							<cfbreak>
						
						</cfif>
						
					</cfloop>
					
				</cfif>

			</cfif>
			
			<cfset viewEventUrl = request.speck.getDisplayMethodUrl(urlId,content.title,viewEventKeyword)>
		
		<cfelse>
			
			<cfset viewEventUrl = request.speck.getDisplayMethodUrl(urlId,content.title)>
		
		</cfif>

		<cfif attributes.showImage and len(trim(content.thumbnailImage))>
		
			<cfscript>
				if ( listLen(content.thumbnailImageDimensions) eq 2 )
					imageDimensions = 'width="#listFirst(content.thumbnailImageDimensions)#" height="#listLast(content.thumbnailImageDimensions)#"';
				else
					imageDimensions = "";						
			</cfscript>
			
			<cfif attributes.linkImage>
				<cfoutput><a href="#viewEventURL#" title="#viewEventTooltip#"></cfoutput>
			</cfif>
			
			<cfoutput><img src="#content.thumbnailImage#" class="event_summary_image" #imagedimensions# alt="'#content.title#' image" border="0" /></cfoutput>
			
			<cfif attributes.linkImage>
				<cfoutput></a></cfoutput>
			</cfif>
			
		</cfif>
		
		<cfscript>
			// get dates as dates (stored as ISO-8601 date string in db, i.e. YYYY-MM-DD)
			startDate = createDate(listFirst(content.startDate,"-"),listGetAt(content.startDate,2,"-"),listLast(content.startDate,"-"));
			if ( len(content.endDate) )
				endDate = createDate(listFirst(content.endDate,"-"),listGetAt(content.endDate,2,"-"),listLast(content.endDate,"-"));
		</cfscript>	
		
		<cfoutput>
		<div class="event_summary_text">
		<#attributes.titleElement# class="event_summary_title"><a href="#viewEventURL#" title="#viewEventTooltip#">#content.title#</a></#attributes.titleElement#>
		</cfoutput>
		
		<cfoutput><div class="event_summary_info">#dateFormat(startDate,"DD MMMM YYYY")#</cfoutput>
		
		<cfif len(content.endDate)>
			
			<cfoutput> - #dateFormat(endDate,"DD MMMM YYYY")#</cfoutput>
			
		</cfif>
		
		<cfif len(content.venue)>
		
			<cfoutput>, #content.venue#</cfoutput>
			
		</cfif>
		
		<cfif len(content.times)>
			
			<cfoutput>, #content.times#</cfoutput>
		
		</cfif>
			
		<cfoutput>
		</div>
		<p class="event_summary_summary">
		#content.summary#
		<cfif len(attributes.readMoreCaption)><span class="event_summary_more"><a href="#viewEventURL#" title="#viewEventTooltip#">#attributes.readMoreCaption#</a></span></cfif>
		</p>

		</div>
		<span style='display:block;clear:both;height:0;font:0/0;'>&nbsp;</span>
		</div>
		</cfoutput>
	
	</cf_spHandler> <!--- end of summary method --->
	
	
	<cf_spHandler method="display">
	
		<cfoutput><div class="event_display"></cfoutput>
	
		<cfparam name="attributes.printCaption" default="print&nbsp;version"> <!--- set to empty string to avoid outputting link to print version --->
		<cfparam name="attributes.printUrl" default="/speck/types/event/print.cfm">
		<cfparam name="attributes.emailNoun" default="friend">
		<cfparam name="attributes.emailCaption" default="send&nbsp;to&nbsp;a&nbsp;#attributes.emailNoun#"> <!--- set to empty string to avoid outputting link --->
		<cfparam name="attributes.emailUrl" default="/speck/types/event/email.cfm">
		<cfparam name="attributes.showTitle" default="yes" type="boolean">
		<cfparam name="attributes.showImage" default="yes" type="boolean">
		<cfparam name="attributes.showDate" default="yes" type="boolean">
		<cfparam name="attributes.titleElement" default="h3">
		<cfparam name="attributes.relatedDocumentsCaption" default="Attached Documents">
		<cfparam name="attributes.relatedDocumentsElement" default="h4">
		<cfparam name="attributes.insertContent" default=""> <!--- use to insert into content after paragraph numbered below --->
		<cfparam name="attributes.insertAfterParagraph" default="3">
		
		<cfif attributes.showTitle>

			<cfoutput>
			<#attributes.titleElement# class="event_display_title">#content.title#</#attributes.titleElement#>
			</cfoutput>
		
		</cfif>
			
		<cfscript>
			// get dates as dates (stored as ISO-8601 date string in db, i.e. YYYY-MM-DD)
			startDate = createDate(listFirst(content.startDate,"-"),listGetAt(content.startDate,2,"-"),listLast(content.startDate,"-"));
			if ( len(content.endDate) )
				endDate = createDate(listFirst(content.endDate,"-"),listGetAt(content.endDate,2,"-"),listLast(content.endDate,"-"));
		</cfscript>
			
		<cfoutput>
		<div class="event_display_dates"><strong>Date<cfif len(content.endDate)>s</cfif>:</strong> #dateFormat(startDate,"DD MMMM YYYY")#<cfif len(content.endDate)> - #dateFormat(endDate,"DD MMMM YYYY")#</cfif></div>
		</cfoutput>
		
		<cfif len(content.times)>
			
			<cfoutput>
			<div class="event_display_times"><strong>Time(s):</strong> #content.times#</div>
			</cfoutput>
		
		</cfif>
		
		<cfoutput>
		<div class="event_display_venue"><strong>Venue:</strong> #content.venue#</div>
		</cfoutput>

		<cfif attributes.showImage and len(trim(content.mainImage))>
			<cfscript>
				if ( listLen(content.mainImageDimensions) eq 2  )
					imageDimensions = 'width="#listFirst(content.mainImageDimensions)#" height="#listLast(content.mainImageDimensions)#"';
				else
					imageDimensions = "";						
			</cfscript>
			<cfoutput><img src="#content.mainImage#" class="article_display_image" #imagedimensions# alt="Image for article titled '#content.title#'" /></cfoutput>
		</cfif>

		<cfscript>
			if ( len(attributes.insertContent) ) {
				currentParagraph = 0;
				stringPosition = 1;
				nl = chr(13) & chr(10);
				do {
					insertPosition = stringPosition - 1;
					stringPosition = find("</p>", content.content, stringPosition + 1);
					currentParagraph = currentParagraph + 1;
				} while ( stringPosition gt 0 and currentParagraph lte attributes.insertAfterParagraph);
				if ( insertPosition neq 0 ) {
					content.content = insert(nl & attributes.insertContent & nl,content.content,insertPosition+4);
				}
			}
		</cfscript>
		
		<cfoutput>
		<div class="event_display_description">
		#content.description#
		</div>
		</cfoutput>	

		<!--- list related documents if any --->
		<cfif len(trim(content.documents))>
			
			<cf_spContentGet type="Document" id="#content.documents#" r_qContent="qDocuments">
			
			<cfif qDocuments.recordCount>
			
				<cfoutput>
				<div class="event_display_documents">
				<#attributes.relatedDocumentsElement#>#attributes.relatedDocumentsCaption#</#attributes.relatedDocumentsElement#>
				</cfoutput>
				
				<cf_spContent type="Document" enableAdminLinks="no" enableAddLink="no" qContent="#qDocuments#">
				
				<cfoutput>
				</div>
				</cfoutput>
				
			</cfif>
		
		</cfif>	
		<!--- end of related documents --->	
		
		<!--- TODO: re-write article cache stuff to a generic meta cache which is generic enough to apply to content items of any type --->
		<!--- TODO2: need to decide what to do when the output is pulled from a persistent cache after 
				a CF restart - in that case the meta cache will have gone from application scope --->
		<cfscript>
			// cache meta data about this content in application scope (can be then used to write 
			// to html head even when output from this method has been cached using spCacheThis)
			stCache = structNew();
			stCache.title = content.title;
			stCache.description = content.summary;
			stCache.date = content.startDate;
			stCache.endDate = content.endDate;
			stCache.times = content.times;
			stCache.venue = content.venue;
			
			// unique cache name based on spId
			cacheName = "c" & replace(content.spId,"-","_","all");
		</cfscript>
		
		<cftry>
			<cflock scope="application" type="exclusive" timeout="3">
			<cfscript>
				if ( not isDefined("application.eventCache") )
					application.metaCache = structNew();
				application.metaCache[cacheName] = duplicate(stCache);
			</cfscript>
			</cflock>
		<cfcatch><!--- do nothing ---></cfcatch>
		</cftry>

		<cfoutput></div></cfoutput>
		
	</cf_spHandler> <!--- end of display method --->
	

	<cf_spHandler method="contentPut">

		<cfscript>
			if ( not len(content.summary) ) {
				content.summary = left(trim(reReplace(content.description,"<[^>]+>","","all")),500);
				if ( reFind("\.[[:space:]]+",content.summary & " ") ) {
					content.summary = left(content.summary,reFind("\.[[:space:]]+",content.summary & " "));
				} else if ( len(content.summary) gt 100 ) {
					content.summary = reReplace(left(content.summary,100),"[[:space:]]+[a-zA-Z0-9\-]+$","...");	
				}
			}
			if ( not len(content.spLabel) ) {
				content.spLabel = lCase(trim(content.title));
				content.spLabel = replace(content.spLabel,"&amp;","&","all");
				content.spLabel = replace(content.spLabel,"&euro;","euro","all");
				content.spLabel = reReplace(content.spLabel,"&([a-zA-Z])acute;","\1","all");
				content.spLabel = reReplace(content.spLabel,"&(##)?[a-zA-Z0-9]+;","","all");
				content.spLabel = reReplace(content.spLabel,"[^A-Za-z0-9\-]+","-","all");
				content.spLabel = reReplace(content.spLabel,"[\-]+","-","all");
				content.spLabel = replace(urlEncodedFormat(content.spLabel),"%2D","-","all");
			}
		</cfscript>
	
		<cfif structKeyExists(request.speck,"portal")>
		
			<!--- update the content index --->
			
			<cfif len(content.startDate)>
				<cfset indexDate = createDate(listFirst(content.startDate,"-"),listGetAt(content.startDate,2,"-"),listLast(content.startDate,"-"))>
			<cfelse>
				<cfset indexDate = content.spCreated>
			</cfif>
				
			<cf_spContentIndex type="#content.spType#"
				id="#content.spId#"
				keyword="#listFirst(content.spKeywords)#"
				title="#content.title#"
				description="#content.summary#"
				body="#content.title# #content.summary# #content.description#"
				date="#indexDate#">
				
		</cfif>
	
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
				<cfset "content.#propertyName#Dimensions" = stImageInfo.width & "," & stImageInfo.height>
				
			<cfcatch>
			
				<cf_spDebug msg="Failed to obtain image dimensions<br>#cfcatch.message#<br>#cfcatch.detail#">
			
			</cfcatch>
			</cftry>
	
		</cfloop>

	</cf_spHandler>
	
	
</cf_spType>
