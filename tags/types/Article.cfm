<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
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
	name="Article"
	description="Article"
	keywordTemplates="#getConfigString("types","article","keyword_templates")#">

 	<cf_spProperty
		name="title"
		caption="Title"
		type="Text"
		required="yes"
		maxlength="250"
		displaySize="70"
		unique="yes"
		finder="yes">
	
 	<cf_spProperty
		name="pubDate"
		caption="Pub.&nbsp;Date"
		type="Date"
		required="#attributes.context.getConfigString("types","article","pub_date_required","yes")#"
		defaultCurrent="yes"
		richEdit="yes">
		
 	<cf_spProperty
		name="updatedDate"
		caption="Updated&nbsp;Date"
		type="Date"
		required="no"
		richEdit="yes"
		displaySize="#attributes.context.getConfigString("types","article","updated_date_display_size",0)#">
		
 	<cf_spProperty
		name="archiveDate"
		caption="Archive&nbsp;Date"
		type="Date"
		required="no"
		richEdit="yes"
		displaySize="#attributes.context.getConfigString("types","article","archive_date_display_size",0)#">
		
 	<cf_spProperty
		name="creator"
		caption="Creator"
		type="Text"
		required="#attributes.context.getConfigString("types","article","creator_required","no")#"
		maxlength="100"
		displaySize="#attributes.context.getConfigString("types","article","creator_display_size",0)#">	
	
 	<cf_spProperty
		name="copyright"
		caption="Copyright"
		type="Text"
		required="#attributes.context.getConfigString("types","article","copyright_required","no")#"
		maxlength="250"
		richEdit="no"
		displaySize="#attributes.context.getConfigString("types","article","copyright_display_size",0)#">
			
 	<cf_spProperty
		name="summary"
		caption="Summary"
		type="Html"
		required="no"
		displaySize="70,5"
		maxlength="500"
		richEdit="no"
		hint="A summary will generated automatically from the content if you leave this field blank.">		

 	<cf_spProperty
		name="content"
		caption="Content"
		type="Html"
		required="yes"
		displaySize="70,20"
		fckHeight="400"
		fckFontFormats="#attributes.context.getConfigString("types","article","content_fck_font_formats","")#"
		maxlength="32000"
		richEdit="yes"
		safeText="#attributes.context.getConfigString("types","article","content_safe_text","yes")#"
		forceParagraphs="#attributes.context.getConfigString("types","article","content_force_paragraphs","yes")#">
		
	<cf_spProperty
		name = "mainImage"
		caption = "Image"
		type = "Asset"
		extensions="png,gif,jpg,jpeg"
		maxWidth="#attributes.context.getConfigString("types","article","main_image_max_width",300)#">
		
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
		maxWidth="#attributes.context.getConfigString("types","article","thumbnail_image_max_width",100)#">	
	
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
		caption="Related Documents"
		type="Picker"
		contentType="Document"
		required="no"
		dependent="yes"
		maxSelect="#attributes.context.getConfigString("types","article","documents_max_select",5)#">
		
	<cf_spProperty
		name="azIndex"
		caption="First character for A-Z index, obtained automagically."
		type="Text"
		required="no"
		maxlength="1"
		displaySize="0"
		index="yes">
		
	
	<cf_spHandler method="dump">
	
		<cfdump var=#content#>
	
	</cf_spHandler>
	
	
	<cf_spHandler method="picker">
	
		<cfoutput>
		<strong>#content.title#</strong><br />
		#content.summary#
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
		<div class="article_print_header">#attributes.header#</div>
		<div style="clear:both;"></div>
		<div class="article_print">
		</cfoutput>
	
		<cfparam name="attributes.showImage" default="yes" type="boolean">
		<cfparam name="attributes.titleElement" default="h1">

		<cfoutput>
		<#attributes.titleElement# class="article_print_title">#content.title#</#attributes.titleElement#>
		</cfoutput>
		
		<!---
		<cfif len(content.pubdate)>
		
			<cfoutput><div class="article_print_pubdate"></cfoutput>
			
			<!--- get publication date as date (stored as ISO-8601 date string in db, i.e. YYYY-MM-DD) --->
			<cfset pubdate = createDate(listFirst(content.pubdate,"-"),listGetAt(content.pubdate,2,"-"),listLast(content.pubdate,"-"))>
		
			<cfoutput>
			#lsDateFormat(pubdate,"DD MMMM YYYY")#
			</cfoutput>
			
			<cfif structKeyExists(content,"updatedDate") and len(content.updatedDate) and content.updatedDate gt content.pubdate>
			
				<cfset updatedDate = createDate(listFirst(content.updatedDate,"-"),listGetAt(content.updatedDate,2,"-"),listLast(content.updatedDate,"-"))>
			
				<cfoutput>
				<em>(updated: #lsDateFormat(updatedDate,"DD MMMM YYYY")#)</em>
				</cfoutput>
				
			</cfif>
			
			<cfoutput>
			</div>
			</cfoutput>
			
		</cfif>
		--->
		
		<cfif attributes.showImage and len(trim(content.mainImage))>
			<cfscript>
				if ( listLen(content.mainImageDimensions) eq 2  )
					imageDimensions = 'width="#listFirst(content.mainImageDimensions)#" height="#listLast(content.mainImageDimensions)#"';
				else
					imageDimensions = "";						
			</cfscript>
			<cfoutput><img src="#content.mainImage#" class="article_print_image" #imagedimensions# alt="Image for article titled '#content.title#'" /></cfoutput>
		</cfif>
		
		<cfoutput>
		<div class="article_print_content">
		#content.content#
		</div>
		</div> <!--- class="article_print" --->
		<div class="article_print_footer">#attributes.footer#</div>
		</body>
		</html>
		</cfoutput>
	
	</cf_spHandler> <!--- end of print method --->


	<cf_spHandler method="email">

		<cfparam name="attributes.docHeader" default=""> <!--- deprecated --->
		<cfparam name="attributes.docFooter" default=""> <!--- deprecated --->
		<cfparam name="attributes.header" default="#attributes.docHeader#">
		<cfparam name="attributes.footer" default="#attributes.docFooter#">
		<cfparam name="attributes.stylesheet" default="">
		<cfparam name="attributes.noun" default="friend">

		<cfparam name="form.email_to" default="">
		<cfparam name="form.personal_message" default="">
		<cfparam name="form.email_from" default="">
		
		<cfparam name="form.articleUrl" default="#cgi.http_referer#">
	
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
		<body>
		<div class="article_email_header">#attributes.header#</div>
		<div style="clear:both;"></div>
		<div class="article_email">
		<h3>#content.title#</h3>
		<p>#content.summary#</p>
		</cfoutput>
		
		<cfset bSent = false>
		<cfset aErrors = arrayNew(1)>
		
		<cfif cgi.request_method eq "post">
		
			<cfscript>
			function isEmail(str) {
				if ( not refind("^([a-zA-Z0-9][-a-zA-Z0-9_%\.']*)?[a-zA-Z0-9]@[a-zA-Z0-9][-a-zA-Z0-9%\>.]*\.[a-zA-Z]{2,}$", str) ) 
					return false;
				else 
					return true;
			}
			</cfscript>
		
			<cfif trim(form.email_to) eq "">
			
				<cfset void = arrayAppend(aErrors,"You did not enter your #attributes.noun#'s email address.")>
			
			<cfelseif not isEmail(form.email_to)>
			
				<cfset void = arrayAppend(aErrors,"Your #attributes.noun#'s email address does not appear to be a valid email address.")>
			
			</cfif>
			
			<cfif trim(form.email_from) eq "">
			
				<cfset void = arrayAppend(aErrors,"You did not enter your email address.")>
			
			<cfelseif not isEmail(form.email_from)>
			
				<cfset void = arrayAppend(aErrors,"Your email address does not appear to be a valid email address.")>
			
			</cfif>
			
			<cfif arrayIsEmpty(aErrors)>
			
				<!--- no errors, send the story --->
				<cfset nl = chr(13) & chr(10)>
				
				<cfset subject = content.title>
				<cfset message = nl & "This message has been sent to you from " & form.email_from & nl>
				<cfif trim(form.personal_message) neq "">
					<cfset message = message & nl & "Message from sender:" & nl & form.personal_message & nl>
				</cfif>
				<cfset message = message & nl & content.title & nl & content.summary & nl>
				<cfset message = message & nl & "Read the full article at:" & nl & form.articleUrl & nl>
				
				<cfset domain = lCase(reReplaceNoCase(cgi.HTTP_HOST,"^(www|dev|test)\.",""))>
				<cfif listLen(domain,".") gt 2 and not reFind("\.[a-z]{2,3}\.[a-z]{2}$",domain)>
					<cfset domain = listDeleteAt(domain,1,".")>
				</cfif>
				
				<cfmail to="#form.email_to#" from="#form.email_from#" failto="bounce@#domain#" subject="#subject#" spoolenable="no">#message#</cfmail>
				
				<cfset bSent = true>
				
			</cfif>
		
		</cfif>
		
		<cfif bSent>
		
			<cfoutput>
			<script type="text/javascript">
				window.onload = function () {
										if ( window.opener ) {
											document.getElementById("exitlink").onclick = function () { window.close();return false; };
											document.getElementById("exitlink").innerHTML = "Close window";
										}
									}
			</script>
			<div align="center">
			<p style="color:red;"><strong>Article has been sent</strong></p>
			<p style="font-weight:bold;">
			<a id="exitlink" href="#form.articleUrl#">Return to article</a>
			</p>
			</div>
			</cfoutput>
		
		<cfelse>
		
			<cfoutput>
			<script type="text/javascript">
				window.onload = function () {
										if ( window.opener ) {
											document.getElementById("exitbutton").onclick = function () { window.close();return false; };
										}
									}
			</script>
			<form action="#cgi.script_name#?#cgi.query_string#" method="post">
				<input type="hidden" name="articleUrl" value="#form.articleUrl#" />
				<script type="text/javascript">
					<!--
					//<![CDATA[
					if ( window.opener ) {
						document.forms[0].articleUrl.value = window.opener.location.href;
					}
					//]]>
					//-->
				</script>
				
				<fieldset>
				<legend>Send this article to a #attributes.noun#</legend>
				</cfoutput>
				
				<cfif not arrayIsEmpty(aErrors)>
				
					<cfoutput>
					<p style="color:red;">
					Oops, one or more errors occured while trying to send the story to your #attributes.noun#.<br />
					Please correct the errors listed below and try again.
					</p>
					<ul style="color:red;">
					</cfoutput>
					
					<cfloop from="1" to="#arrayLen(aErrors)#" index="i">
						
						<cfoutput><li>#aErrors[i]#</li></cfoutput>
						
					</cfloop>
					
					<cfoutput>
					</ul>
					</cfoutput>
				
				</cfif>
				
				<cfoutput>
				<table cellpadding="0" cellspacing="0" border="0">
					<tr>
						<td colspan="2">Enter your #attributes.noun#'s email address, your email address and, optionally, a personal message, then click "Send".</td>
					</tr>
					<tr>
						<td nowrap="yes"><label for="email_to"><strong>Your #attributes.noun#'s email address:<span style="color:red;">*</span></strong></label></td>
						<td><input type="text" name="email_to" id="email_to" value="#form.email_to#" size="35" maxlength="100" /></td>
					</tr>
					<tr>
						<td nowrap="yes"><label for="personal_message"><strong>Add a personal message:</strong></label></td>
						<td><textarea name="personal_message" id="personal_message" wrap="virtual" rows="3" cols="27">#form.personal_message#</textarea></td>
					</tr>
					<tr>
						<td nowrap="yes"><label for="email_from"><strong>Your email address:<span style="color:red;">*</span></strong></label></td>
						<td><input type="text" name="email_from" id="email_from" value="#form.email_from#" size="35" maxlength="100" /></td>
					</tr>
					<tr>
						<td colspan="2">
						<span style="color:red;">Note:</span> Your email address is <em>only</em> used to let the recipient know who sent the mail.
						Neither your address or your #attributes.noun#'s address will be used for any other purpose.
						</td>
					</tr>
					<tr>
						<td colspan="2" align="center">
						<input type="submit" value=" Send " />
						<input type="button" value=" Cancel " id="exitbutton" onclick="window.location.href='#form.articleUrl#';" />
						</td>
					</tr>
				</table>
				</fieldset>
			</form>
			</cfoutput>
			
		</cfif>

		<cfoutput>
		</div> <!--- class="article_email" --->
		<div class="article_email_footer">#attributes.footer#</div>
		</body>
		</html>
		</cfoutput>
	
	</cf_spHandler> <!--- end of email method --->
	 
	
	<cf_spHandler method="summary">

		<cfscript>
			cssClass = "article_summary";
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
		<cfparam name="attributes.readMoreCaption" default="&raquo;&nbsp;read more">
		<cfparam name="attributes.titleElement" default="h3">
		<cfparam name="attributes.fullArticleTooltip" default="view article">
		<cfparam name="attributes.dynamicTooltip" default="yes" type="boolean">
		<cfparam name="attributes.replaceKeywordInUrl" default="no">
		<cfparam name="attributes.labelIdentifier" default="no" type="boolean">
		<cfparam name="attributes.sequenceIdUrlPrefix" default="no" type="boolean">
		
		<cfset fullArticleTooltip = attributes.fullArticleTooltip>
		
		<cfif attributes.dynamicTooltip>
		
			<cfset fullArticleTooltip = fullArticleTooltip & " '#replace(reReplace(content.title,"<[^>]+>","","all"),"""","","all")#'">
				
		</cfif>
		
		<cfif attributes.labelIdentifier and len(content.spLabel)>
			<cfset urlId = content.spLabel>
		<cfelse>
			<cfset urlId = content.spId>
		</cfif>
		
		<cfif attributes.sequenceIdUrlPrefix>
			<cfif structKeyExists(content,"spSequenceId") and isNumeric(content.spSequenceId)>
				<cfset urlId = numberFormat(content.spSequenceId,"0000") & "-" & urlId>
			<cfelse>
				<cfset urlId = "0000-" & urlId> <!--- this shouldn't happen, but just in case it does, we have to prefix the id if the display template expects a prefix --->
			</cfif>
		</cfif>
		
		<cfif attributes.replaceKeywordInUrl and len(content.spKeywords)>
			
			<!--- replace the keyword in the url with the first valid one from content.spKeywords --->
			<cfset fullArticleKeyword = listFirst(content.spKeywords)>

			<cfif structKeyExists(request.speck,"portal") and structKeyExists(request.speck.types.article,"keywordTemplates") and len(request.speck.types.article.keywordTemplates)>
			
				<!--- get a list of keywords where the article templates are used, we should only use these keywords if possible --->
				<cfquery name="qValidKeywords" dbtype="query">
					SELECT keyword 
					FROM request.speck.qKeywords 
					WHERE template IN (#listQualify(request.speck.types.article.keywordTemplates,"'")#)
				</cfquery>
				
				<cfset lValidKeywords = valueList(qValidKeywords.keyword)>
				
				<cfif len(lValidKeywords) and not listFind(lValidKeywords,fullArticleKeyword) and listLen(content.spKeywords) gt 1>
				
					<!--- first keyword in spKeywords doesn't look like it can display an article, try and find the first one that can --->
					<cfloop list="#listRest(content.spKeywords)#" index="keyword">
						
						<cfif listFind(lValidKeywords,keyword)>
						
							<cfset fullArticleKeyword = keyword>
							<cfbreak>
						
						</cfif>
						
					</cfloop>
					
				</cfif>

			</cfif>
			
			<cfset fullArticleUrl = request.speck.getDisplayMethodUrl(urlId,content.title,fullArticleKeyword)>
		
		<cfelse>
			
			<cfset fullArticleUrl = request.speck.getDisplayMethodUrl(urlId,content.title)>
		
		</cfif>

		<cfset thumbnailHtml = "">
		<cfif attributes.showImage and len(trim(content.thumbnailImage))>
		
			<cfscript>
				if ( listLen(content.thumbnailImageDimensions) eq 2 )
					imageDimensions = 'width="#listFirst(content.thumbnailImageDimensions)#" height="#listLast(content.thumbnailImageDimensions)#"';
				else
					imageDimensions = "";						
			</cfscript>
			
			<cfsavecontent variable="thumbnailHtml">
				
				<cfif attributes.linkImage>
					<cfoutput><a href="#fullArticleURL#" title="#fullArticleTooltip#"></cfoutput>
				</cfif>
				
				<cfoutput><img src="#content.thumbnailImage#" class="article_summary_image" #imagedimensions# alt="Image for article titled '#content.title#'" border="0" /></cfoutput>
				
				<cfif attributes.linkImage>
					<cfoutput></a></cfoutput>
				</cfif>
				
			</cfsavecontent>
			
			<cfset thumbnailHtml = trim(thumbnailHtml)>
			
		</cfif>
		
		<cfif not attributes.embedImage>
			<cfoutput>#thumbnailHtml#</cfoutput>
		</cfif>
		
		<cfoutput>
		<div class="article_summary_text">
		<#attributes.titleElement# class="article_summary_title"><a href="#fullArticleURL#" title="#fullArticleTooltip#">#content.title#</a></#attributes.titleElement#>
		<p class="article_summary_summary">
		</cfoutput>
		
		<cfif attributes.embedImage>
			<cfoutput>#thumbnailHtml#</cfoutput>
		</cfif>
		
		<cfoutput>
		#content.summary# <cfif len(attributes.readMoreCaption)><span class="article_summary_more"><a href="#fullArticleURL#" title="#fullArticleTooltip#">#attributes.readMoreCaption#</a></span></cfif>
		</p>
		</cfoutput>
		
		<cfoutput>
		</div>
		<span style='display:block;clear:both;height:0;font:0/0;'>&nbsp;</span>
		</div>
		</cfoutput>
	
	</cf_spHandler> <!--- end of summary method --->
	
	
	<cf_spHandler method="display">
	
		<cfoutput><div class="article_display"></cfoutput>
	
		<cfparam name="attributes.printCaption" default="print&nbsp;version"> <!--- set to empty string to avoid outputting link to print version --->
		<cfparam name="attributes.printUrl" default="/speck/types/article/print.cfm">
		<cfparam name="attributes.emailNoun" default="friend">
		<cfparam name="attributes.emailCaption" default="send&nbsp;to&nbsp;a&nbsp;#attributes.emailNoun#"> <!--- set to empty string to avoid outputting link --->
		<cfparam name="attributes.emailUrl" default="/speck/types/article/email.cfm">
		<cfparam name="attributes.showTitle" default="yes" type="boolean">
		<cfparam name="attributes.showImage" default="yes" type="boolean">
		<cfparam name="attributes.showDate" default="yes" type="boolean">
		<cfparam name="attributes.titleElement" default="h3">
		<cfparam name="attributes.relatedDocumentsCaption" default="Related Documents">
		<cfparam name="attributes.relatedDocumentsElement" default="h4">
		<cfparam name="attributes.insertContent" default=""> <!--- use to insert into content after paragraph numbered below --->
		<cfparam name="attributes.insertAfterParagraph" default="3">
		
		<cfif attributes.showTitle>

			<cfoutput>
			<#attributes.titleElement# class="article_display_title">#content.title#</#attributes.titleElement#>
			</cfoutput>
		
		</cfif>
		
		<cfif len(content.pubdate) and attributes.showDate>
		
			<cfoutput><div class="article_display_pubdate"></cfoutput>
			
			<!--- get publication date as date (stored as ISO-8601 date string in db, i.e. YYYY-MM-DD) --->
			<cfset pubdate = createDate(listFirst(content.pubdate,"-"),listGetAt(content.pubdate,2,"-"),listLast(content.pubdate,"-"))>
		
			<cfoutput>
			#lsDateFormat(pubdate,"DD MMMM YYYY")#
			</cfoutput>
			
			<cfif structKeyExists(content,"updatedDate") and len(content.updatedDate) and content.updatedDate gt content.pubdate>
			
				<cfset updatedDate = createDate(listFirst(content.updatedDate,"-"),listGetAt(content.updatedDate,2,"-"),listLast(content.updatedDate,"-"))>
			
				<cfoutput>
				<em>(updated: #lsDateFormat(updatedDate,"DD MMMM YYYY")#)</em>
				</cfoutput>
				
			</cfif>
			
			<cfoutput>
			</div>
			</cfoutput>
			
		</cfif>
		
		<cfsavecontent variable="widgets">
		
			<cfif len(attributes.printCaption)>
			
				<cfif not isDefined("request.speck.spHandlerArticlePrintPopup")> <!--- only write out the JS function once --->
					<cfoutput><script type="text/javascript">
						<!--
						//<![CDATA[
						function article_print_popup(id) {
							var printWindow = window.open("#attributes.printUrl#?app=#request.speck.appName#&id=" + id,"article_print","menubar=yes,resizable=yes,scrollbars=yes,toolbar=yes,status=yes,width=650,height=450,screenX=50,screenY=50,left=50,top=50");
							printWindow.focus();
						}
						//]]>
						//-->
					</script></cfoutput>
					<cfset request.speck.spHandlerArticlePrintPopup = true>
				</cfif>		
				
				<cfoutput>
				<span class="article_display_print">
				<a href="#attributes.printUrl#?app=#request.speck.appName#&id=#content.spId#" title="printer friendly version (opens in new window)" onclick="article_print_popup('#content.spId#');return false;">#attributes.printCaption#</a>
				</span>
				</cfoutput>
					
			</cfif>
	
			<cfif len(attributes.emailCaption)>
			
				<cfif not isDefined("request.speck.spHandlerEmailPrintPopup")> <!--- only write out the JS function once --->
					<cfoutput><script type="text/javascript">
						<!--
						//<![CDATA[
						function article_email_popup(id,url) {
							var emailWindow = window.open("#attributes.emailUrl#?app=#request.speck.appName#&id=" + id + "&noun=#attributes.emailNoun#","article_email","menubar=yes,resizable=yes,scrollbars=yes,toolbar=yes,status=yes,width=650,height=450,screenX=50,screenY=50,left=50,top=50");
							emailWindow.focus();
						}
						//]]>
						//-->
					</script></cfoutput>
					<cfset request.speck.spHandlerEmailPrintPopup = true>
				</cfif>		
				
				<cfoutput>
				<span class="article_display_email">
				<a href="#attributes.emailUrl#?app=#request.speck.appName#&id=#content.spId#" title="email article to a #attributes.emailNoun# (opens in new window)" onclick="article_email_popup('#content.spId#');return false;">#attributes.emailCaption#</a>
				</span>
				</cfoutput>
					
			</cfif>
		
		</cfsavecontent>
		
		<cfif len(trim(widgets))>
		
			<cfoutput>
			<div class="article_display_widgets">
			#widgets#
			</div>
			</cfoutput>
		
		</cfif>

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
		<div class="article_display_content">
		#content.content#
		</div>
		</cfoutput>	
		
		<!--- list related documents if any --->
		<cfif len(trim(content.documents))>
			
			<cf_spContentGet type="Document" id="#content.documents#" r_qContent="qDocuments">
			
			<cfif qDocuments.recordCount>
			
				<cfoutput>
				<div class="article_display_documents">
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
			stCache.creator = content.creator;
			stCache.summary = content.summary;
			stCache.pubDate = content.pubDate;
			stCache.spUpdated = content.spUpdated;
			stCache.copyright = content.copyright;
			
			// unique cache name based on spId
			cacheName = "c" & replace(content.spId,"-","_","all");
		</cfscript>
		
		<cftry>
			<cflock scope="application" type="exclusive" timeout="3">
			<cfscript>
				if ( not isDefined("application.articleCache") )
					application.articleCache = structNew();
				application.articleCache[cacheName] = duplicate(stCache);
			</cfscript>
			</cflock>
		<cfcatch><!--- do nothing ---></cfcatch>
		</cftry>

		<cfoutput></div></cfoutput>
		
	</cf_spHandler> <!--- end of display method --->

	
	<cf_spHandler method="contentPut">
	
		<cfset content.azIndex = left(reReplace(uCase(content.title),"[^A-Z]","","all"),1)>
		
		<cfscript>
			if ( not len(content.summary) ) {
				content.summary = left(trim(reReplace(content.content,"<[^>]+>","","all")),500);
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
			
			<cfif len(content.pubdate)>
				<cfset indexDate = createDate(listFirst(content.pubdate,"-"),listGetAt(content.pubdate,2,"-"),listLast(content.pubdate,"-"))>
			<cfelse>
				<cfset indexDate = content.spCreated>
			</cfif>
				
			<cf_spContentIndex type="#content.spType#"
				id="#content.spId#"
				keyword="#listFirst(content.spKeywords)#"
				title="#content.title#"
				description="#content.summary#"
				body="#content.title# #content.summary# #content.content#"
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
	
	
	<cf_spHandler method="promote">
	
		<cfif structKeyExists(request.speck,"portal") and attributes.newLevel eq "live">
		
			<cfif content.spRevision eq 0>
			
				<!--- removal --->
				<cfquery name="qDelete" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
					DELETE FROM spContentIndex WHERE id = '#content.spId#'
				</cfquery>
			
			<cfelse>
				
				<!--- update the content index --->
				
				<cfif len(content.pubdate)>
					<cfset indexDate = createDate(listFirst(content.pubdate,"-"),listGetAt(content.pubdate,2,"-"),listLast(content.pubdate,"-"))>
				<cfelse>
					<cfset indexDate = content.spCreated>
				</cfif>
				
				<cf_spContentIndex type="#content.spType#"
					id="#content.spId#"
					keyword="#listFirst(content.spKeywords)#"
					title="#content.title#"
					description="#content.summary#"
					body="#content.title# #content.summary# #content.content#"
					date="#indexDate#">
			
			</cfif>
		
		</cfif>

	</cf_spHandler>
	
	
	<cf_spHandler method="delete">
	
		<cfif structKeyExists(request.speck,"portal")>
		
			<!--- delete from content index --->
			<cfquery name="qDelete"datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
				DELETE FROM spContentIndex WHERE id = '#content.spId#'
			</cfquery>
			
		</cfif>

	</cf_spHandler>
	
	
	<cf_spHandler method="refresh">
	
		<!--- set the label for all articles that don't have one, so we can use the label as an identifier in the URL (rather than the spId) --->
		<cfquery name="qArticles" datasource="#context.codb#">
			SELECT title, spId, spLabel FROM Article WHERE spLabel IS NULL
		</cfquery>
		
		<cfloop query="qArticles">
		
			<cfscript>
				if ( not len(spLabel) ) {
					newLabel = lCase(trim(title));
					newLabel = replace(newLabel,"&amp;","&","all");
					newLabel = replace(newLabel,"&euro;","euro","all");
					newLabel = reReplace(newLabel,"&([a-zA-Z])acute;","\1","all");
					newLabel = reReplace(newLabel,"&(##)?[a-zA-Z0-9]+;","","all");
					newLabel = reReplace(newLabel,"[^A-Za-z0-9\-]+","-","all");
					newLabel = reReplace(newLabel,"[\-]+","-","all");
					newLabel = replace(urlEncodedFormat(newLabel),"%2D","-","all");
				}
			</cfscript>
			
			<cfquery name="qUpdate" datasource="#context.codb#">
				UPDATE Article 
				SET spLabel = '#newLabel#', 
					spLabelIndex = '#uCase(newLabel)#'
				WHERE spId = '#spId#'
			</cfquery>
		
		</cfloop>
		
	</cf_spHandler>
	
		
</cf_spType>
