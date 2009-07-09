<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2005 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- make sure the context is always available as an attribute, whether it was explicitly provided or not --->
<!--- note: attributes.context is always available within cf_spType tags, but we need it when calling cf_spType itself --->
<cfparam name="attributes.context" default="#iif( structKeyExists(request,"speck"), "request.speck", "attributes.context" )#">

<cf_spType
	name="Event"
	description="Event"
	keywordTemplates="#attributes.context.getConfigString("types","event","keyword_templates")#">
	
 	<cf_spProperty
		name="title"
		caption="Title"
		type="Text"
		required="yes"
		maxlength="250"
		displaySize="75"
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
		caption="#attributes.context.getConfigString("types","event","documents_caption","Attached Documents")#"
		type="Picker"
		contentType="Document"
		required="no"
		dependent="yes"
		maxSelect="#attributes.context.getConfigString("types","event","documents_max_select",5)#">
		
	<cf_spIndex
		title="title"
		description="summary"
		body="title,venue,summary,description"
		date="startDate">
		
		
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
		<cfparam name="attributes.titleElement" default="h1">
	
		<cfscript>
			// get dates as dates (stored as ISO-8601 date string in db, i.e. YYYY-MM-DD)
			startDate = createDate(listFirst(content.startDate,"-"),listGetAt(content.startDate,2,"-"),listLast(content.startDate,"-"));
			if ( len(content.endDate) )
				endDate = createDate(listFirst(content.endDate,"-"),listGetAt(content.endDate,2,"-"),listLast(content.endDate,"-"));
		</cfscript>	

		<cfoutput>
		<#attributes.titleElement# class="event_print_title">#content.title#</#attributes.titleElement#>
		</cfoutput>
			
		<!--- use paragraph tags for dates, times and venue in print version to pick up some default styles - should normally mean these items are well spaced out without any additional styling required --->
		
		<cfoutput>
		<p class="event_display_dates"><strong>Date<cfif len(content.endDate)>s</cfif>:</strong> #dateFormat(startDate,"DD MMMM YYYY")#<cfif len(content.endDate)> - #dateFormat(endDate,"DD MMMM YYYY")#</cfif></p>
		</cfoutput>
		
		<cfif len(content.times)>
			
			<cfoutput>
			<p class="event_display_times"><strong>Time(s):</strong> #content.times#</p>
			</cfoutput>
		
		</cfif>
		
		<cfoutput>
		<p class="event_display_venue"><strong>Venue:</strong> #content.venue#</p>
		</cfoutput>
		
		<cfif attributes.showImage and len(trim(content.mainImage))>
			<cfscript>
				if ( listLen(content.mainImageDimensions) eq 2  )
					imageDimensions = 'width="#listFirst(content.mainImageDimensions)#" height="#listLast(content.mainImageDimensions)#"';
				else
					imageDimensions = "";						
			</cfscript>
			<cfoutput><img src="#content.mainImage#" class="event_print_image" #imagedimensions# alt="'#content.title#' image" /></cfoutput>
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
	
	
	<cf_spHandler method="email">

		<cfparam name="attributes.header" default="">
		<cfparam name="attributes.footer" default="">
		<cfparam name="attributes.stylesheet" default="">
		<cfparam name="attributes.noun" default="friend">

		<cfparam name="form.email_to" default="">
		<cfparam name="form.personal_message" default="">
		<cfparam name="form.email_from" default="">
		
		<cfparam name="form.eventUrl" default="#cgi.http_referer#">
	
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
		<div class="event_email_header">#attributes.header#</div>
		<div style="clear:both;"></div>
		<div class="event_email">
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
			
				<cfset void = arrayAppend(aErrors,"Your #attributes.noun#'s email address is a required field.")>
			
			<cfelseif not isEmail(form.email_to)>
			
				<cfset void = arrayAppend(aErrors,"Your #attributes.noun#'s email address does not appear to be a valid email address.")>
			
			</cfif>
			
			<cfif trim(form.email_from) eq "">
			
				<cfset void = arrayAppend(aErrors,"Your email address is a required field.")>
			
			<cfelseif not isEmail(form.email_from)>
			
				<cfset void = arrayAppend(aErrors,"Your email address does not appear to be a valid email address.")>
			
			</cfif>
			
			<cfif arrayIsEmpty(aErrors)>
			
				<!--- no errors, send the story --->
				<cfset nl = chr(13) & chr(10)>
				
				<cfset subject = content.title>
		
				<cfset message = nl & "This event has been sent to you by " & form.email_from & nl>
				<cfif trim(form.personal_message) neq "">
					<cfset message = message & nl & "Message from sender:" & nl & form.personal_message & nl>
				</cfif>
				<cfset message = message & nl & content.title & nl & dateFormat(content.startDate,"DD MMMM YYYY")>
				<cfif len(content.endDate)>
					<cfset message = message & " - " & dateFormat(content.endDate,"DD MMMM YYYY") & nl>
				</cfif>
				<cfif len(content.venue)>
					<cfset message = message & ", " & content.venue>
				</cfif>
				<cfif len(content.times)>
					<cfset message = message & ", " & content.times>
				</cfif>
				<cfset message = message & nl & nl & "View the full event details at:" & nl & form.eventUrl & nl>
				
				<cfset domain = request.speck.getDomainFromHostName()>
				
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
			<p style="color:red;"><strong>Event has been sent</strong></p>
			<p style="font-weight:bold;">
			<a id="exitlink" href="#form.eventUrl#">Return to event</a>
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
				<input type="hidden" name="eventUrl" value="#form.eventUrl#" />
				<script type="text/javascript">
					<!--
					//<![CDATA[
					if ( window.opener ) {
						document.forms[0].eventUrl.value = window.opener.location.href;
					}
					//]]>
					//-->
				</script>
				
				<fieldset>
				<legend>Send this event to a #attributes.noun#</legend>
				</cfoutput>
				
				<cfif not arrayIsEmpty(aErrors)>
				
					<cfoutput>
					<p style="color:red;">
					Sorry, the event could not be sent due to the following issues...
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
				<table cellpadding="3" cellspacing="0" border="0">
					<tr>
						<td colspan="2">Enter your #attributes.noun#'s email address, your email address and, optionally, a personal message, then click "Send".</td>
					</tr>
					<tr>
						<td nowrap="yes"><label for="email_to"><strong>Your #attributes.noun#'s email address:<span style="color:red;">*</span></strong></label></td>
						<td><input type="text" name="email_to" id="email_to" value="#form.email_to#" size="35" maxlength="100" style="width:350px;" /></td>
					</tr>
					<tr>
						<td nowrap="yes"><label for="personal_message"><strong>Add a personal message:</strong></label></td>
						<td><textarea name="personal_message" id="personal_message" wrap="virtual" rows="3" cols="27" style="width:350px;">#form.personal_message#</textarea></td>
					</tr>
					<tr>
						<td nowrap="yes"><label for="email_from"><strong>Your email address:<span style="color:red;">*</span></strong></label></td>
						<td><input type="text" name="email_from" id="email_from" value="#form.email_from#" size="35" maxlength="100" style="width:350px;" /></td>
					</tr>
					<tr>
						<td colspan="2">
						<span style="color:red;">Note:</span> Your email address is <em>only</em> used to let the recipient know who sent the mail.
						Neither your address or your #attributes.noun#'s address will be used for any other purpose.
						</td>
					</tr>
					<tr>
						<td colspan="2" align="center" style="text-align:center;">
						<input type="submit" value=" Send " />
						<input type="button" value=" Cancel " id="exitbutton" onclick="window.location.href='#form.eventUrl#';" />
						</td>
					</tr>
				</table>
				</fieldset>
			</form>
			</cfoutput>
			
		</cfif>

		<cfoutput>
		</div> <!--- class="event_email" --->
		<div class="event_email_footer">#attributes.footer#</div>
		</body>
		</html>
		</cfoutput>
	
	</cf_spHandler> <!--- end of email method --->
	
	
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
				
					<!--- first keyword in spKeywords doesn't look like it can display an event, try and find the first one that can --->
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
			// parse date strings (Speck dates are stored in the db as YYYY-MM-DD format strings)
			startDate = parseDateTime(content.startDate);
			if ( len(content.endDate) )
				endDate = parseDateTime(content.endDate);
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

		<cfif attributes.showTitle>

			<cfoutput>
			<#attributes.titleElement# class="event_display_title">#content.title#</#attributes.titleElement#>
			</cfoutput>
		
		</cfif>
		
		<cfsavecontent variable="widgets">
		
			<cfif len(attributes.printCaption)>
			
				<cfif not isDefined("request.speck.spHandlerEventPrintPopup")> <!--- only write out the JS function once --->
					<cfoutput><script type="text/javascript">
						<!--
						//<![CDATA[
						function event_print_popup(id) {
							var printWindow = window.open("#attributes.printUrl#?app=#request.speck.appName#&id=" + id,"event_print","menubar=yes,resizable=yes,scrollbars=yes,toolbar=yes,status=yes,width=650,height=450,screenX=50,screenY=50,left=50,top=50");
							printWindow.focus();
						}
						//]]>
						//-->
					</script></cfoutput>
					<cfset request.speck.spHandlerEventPrintPopup = true>
				</cfif>		
				
				<cfoutput>
				<span class="event_display_print">
				<a href="#attributes.printUrl#?app=#request.speck.appName#&id=#content.spId#" title="printer friendly version (opens in new window)" onclick="event_print_popup('#content.spId#');return false;">#attributes.printCaption#</a>
				</span>
				</cfoutput>
					
			</cfif>
	
			<cfif len(attributes.emailCaption)>
			
				<cfif not isDefined("request.speck.spHandlerEmailPrintPopup")> <!--- only write out the JS function once --->
					<cfoutput><script type="text/javascript">
						<!--
						//<![CDATA[
						function event_email_popup(id,url) {
							var emailWindow = window.open("#attributes.emailUrl#?app=#request.speck.appName#&id=" + id + "&noun=#attributes.emailNoun#","event_email","menubar=yes,resizable=yes,scrollbars=yes,toolbar=yes,status=yes,width=650,height=450,screenX=50,screenY=50,left=50,top=50");
							emailWindow.focus();
						}
						//]]>
						//-->
					</script></cfoutput>
					<cfset request.speck.spHandlerEmailPrintPopup = true>
				</cfif>		
				
				<cfoutput>
				<span class="event_display_email">
				<a href="#attributes.emailUrl#?app=#request.speck.appName#&id=#content.spId#" title="email event to a #attributes.emailNoun# (opens in new window)" onclick="event_email_popup('#content.spId#');return false;">#attributes.emailCaption#</a>
				</span>
				</cfoutput>
					
			</cfif>
		
		</cfsavecontent>
		
		<cfif len(trim(widgets))>
		
			<cfoutput>
			<div class="event_display_widgets">
			#widgets#
			</div>
			</cfoutput>
		
		</cfif>
			
		<cfscript>
			// parse date strings (Speck dates are stored in the db as YYYY-MM-DD format strings)
			startDate = parseDateTime(content.startDate);
			if ( len(content.endDate) )
				endDate = parseDateTime(content.endDate);
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
			<cfoutput><img src="#content.mainImage#" class="event_display_image" #imagedimensions# alt="'#content.title#' image" /></cfoutput>
		</cfif>
		
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
		
		<!--- TODO: re-write cache stuff to a generic meta cache which is generic enough to apply to content items of any type --->
		<!--- Note: when caching the output of this method, set persistent="no" - if the application is refreshed due to a cfserver restart, caches are rebuilt from the persistent cache, but this meta cache won't be rebuilt --->
		<!--- TODO2: some kind of standard meta cache tag and storage area --->
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
		
		<!--- check if label is unique and append sequence id if not --->
		<cfquery name="qCheckLabel" datasource="#request.speck.codb#">
			SELECT spId 
			FROM #content.spType# 
			WHERE spLabelIndex = '#uCase(content.spLabel)#' 
				AND spArchived IS NULL
				AND spId <> '#content.spId#'
		</cfquery>
		
		<cfif qCheckLabel.recordCount>
		
			<cfset content.spLabel = content.spLabel & "-" & content.spSequenceId>
		
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
