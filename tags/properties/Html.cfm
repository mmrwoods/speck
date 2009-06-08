<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spPropertyHandler>


	<cf_spPropertyHandlerMethod method="validateAttributes">
	
		<!--- Check format of displaySize attribute, allowed formats are "N" or "N,M" --->
		<cfset ds = stPD.displaySize>
		<cfif not (((listLen(ds) eq 1) and isNumeric(ds)) or ((listLen(ds) eq 2) and (isNumeric(listFirst(ds)) and isNumeric(listLast(ds)))))>
		
			<cf_spError error="PH_TEXT_DS" lParams="#ds#" context=#caller.ca.context#>	<!--- Invalid displaySize format --->
		
		</cfif>
		
		<cfparam name="stPD.escapeHTML" type="boolean" default="true">
		<cfparam name="stPD.convertLatin1" type="boolean" default="false">
		<cfparam name="stPD.safeText" type="boolean" default="true">
		<cfparam name="stPD.tidyWordHTML" type="boolean" default="true">
		<cfparam name="stPD.allowFont" type="boolean" default="false"> <!--- allow font tags? --->
		<cfparam name="stPD.allowStyle" type="boolean" default="true"> <!--- allow style attributes? --->
		<cfparam name="stPD.allowClass" type="boolean" default="true"> <!--- allow class attributes? --->
		<cfparam name="stPD.allowSpan" type="boolean" default="true"> <!--- allow span tags? --->
		<cfparam name="stPD.allowDiv" type="boolean" default="true"> <!--- allow div tags? --->
		<cfparam name="stPD.allowBr" type="boolean" default="true"> <!--- allow br tags? --->
		<cfparam name="stPD.tidy" type="boolean" default="true"> <!--- attempt to use JTidy to clean html / convert to xhtml --->
		<cfparam name="stPD.forceParagraphs" type="boolean" default="false"> <!--- force html to be wrapped in paragraph tags --->
		<cfparam name="stPD.replaceParagraphs" type="boolean" default="false">
		<cfparam name="stPD.allowTarget" type="boolean" default="true"> <!--- allow target attributes? --->
		<cfparam name="stPD.forceRelativeLinks" default="true" type="boolean">
		<cfparam name="stPD.forceTarget" default="true" type="boolean">
		
		<!--- use rich text editor? --->
		<cfparam name="stPD.richEdit" default="false" type="boolean"> 

		<!--- optional attributes for re-sizing images uploaded using FCK editor --->
		<cfparam name="stPD.imageWidth" default="">
		<cfparam name="stPD.imageHeight" default="">
		<cfparam name="stPD.imageMaxWidth" default="">
		<cfparam name="stPD.imageMaxHeight" default="">
		<cfparam name="stPD.imageCropToExact" default="yes" type="boolean">
		<cfparam name="stPD.imageJpegCompression" default="90">
		
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="readFormField">

		<cfset newValue = trim(value)>
		
		<!--- new property definition attribute - this line can be removed once all apps have been refreshed --->
		<cfparam name="stPD.convertLatin1" type="boolean" default="false">
		
		<!--- 
		hack to deal with FCKeditor stupidity.
		FCKeditor inserts empty p and br tags at the start of an empty value. None of the 
		supposed fixes that appear in the fckeditor trac fix it imo - an empty br or p is 
		significant, it screws up formatting and makes us think the form field has some 
		content. Remove brs and empty paragraphs at the beginning of the value...
		--->
		<cfset newValue = reReplaceNoCase(newValue, "^<(br)[^>]*>", "", "all")>
		<cfset newValue = reReplaceNoCase(newValue, "^<p>(&nbsp;|&##160;)?</p>", "", "all")>
		
		<cfif len(newValue)>
		
			<cfif not stPD.allowFont>
			
				<cfset newValue = reReplaceNoCase(newValue, "</?(font)[^>]*>", "", "all")>
			
			</cfif>
			
			<cfif not stPD.allowSpan>
			
				<cfset newValue = reReplaceNoCase(newValue, "</?(span)[^>]*>", "", "all")>
			
			</cfif>
			
			<cfif not stPD.allowDiv>
			
				<cfset newValue = reReplaceNoCase(newValue, "</?(div)[^>]*>", "", "all")>
			
			</cfif>
			
			<cfif not stPD.allowBr>
		
				<cfset newValue = reReplaceNoCase(newValue, "</?(br)[^>]*>", " ", "all")>
			
			</cfif>
			
			<cfif stPD.safeText>
			
				<!--- remove dodgy tags from HTML --->
					
				<!--- #################### safeText() function #################### --->
				<!---
					
					This library is part of the Common Function Library Project. An open source
					collection of UDF libraries designed for ColdFusion 5.0. For more information,
					please see the web site at:
						
						http://www.cflib.org
						
					Warning:
					You may not need all the functions in this library. If speed
					is _extremely_ important, you may want to consider deleting
					functions you do not plan on using. Normally you should not
					have to worry about the size of the library.
						
					License:
					This code may be used freely. 
					You may modify this code as you see fit, however, this header, and the header
					for the functions must remain intact.
					
					This code is provided as is.  We make no warranty or guarantee.  Use of this code is at your own risk.
				--->				
				<cfscript>
				/**
				 * Removes potentially nasty HTML text.
				 * Version 2 by Lena Aleksandrova - changes include fixing a bug w/ arguments and use of REreplace where REreplaceNoCase should have been used.
				 * version 4 fix by Javier Julio - when a bad event is removed, remove the arg too, ie, remove onclick=&quot;foo&quot;, not just onclick.
				 * 
				 * @param text 	 String to be modified. (Required)
				 * @param strip 	 Boolean value (defaults to false) that determines if HTML should be stripped or just escaped out. (Optional)
				 * @param badTags 	 A list of bad tags. Has a long default list. Consult source. (Optional)
				 * @param badEvents 	 A list of bad HTML events. Has a long default list. Consult source. (Optional)
				 * @return Returns a string. 
				 * @author Nathan Dintenfass (&#110;&#97;&#116;&#104;&#97;&#110;&#64;&#99;&#104;&#97;&#110;&#103;&#101;&#109;&#101;&#100;&#105;&#97;&#46;&#99;&#111;&#109;) 
				 * @version 4, October 16, 2006 
				 */
				function safetext(text) {
					//default mode is "escape"
					var mode = "escape";
					//the things to strip out (badTags are HTML tags to strip and badEvents are intra-tag stuff to kill)
					//you can change this list to suit your needs
					var badTags = "SCRIPT,OBJECT,APPLET,EMBED,FORM,LAYER,ILAYER,FRAME,IFRAME,FRAMESET,PARAM,META";
					var badEvents = "onClick,onDblClick,onKeyDown,onKeyPress,onKeyUp,onMouseDown,onMouseOut,onMouseUp,onMouseOver,onBlur,onChange,onFocus,onSelect,javascript:";
					var stripperRE = "";
					
					//set up variable to parse and while we're at it trim white space 
					var theText = trim(text);
					//find the first open bracket to start parsing
					var obracket = find("<",theText);		
					//var for badTag
					var badTag = "";
					//var for the next start in the parse loop
					var nextStart = "";
					//if there is more than one argument and the second argument is boolean TRUE, we are stripping
					if(arraylen(arguments) GT 1 AND isBoolean(arguments[2]) AND arguments[2]) mode = "strip";
					if(arraylen(arguments) GT 2 and len(arguments[3])) badTags = arguments[3];
					if(arraylen(arguments) GT 3 and len(arguments[4])) badEvents = arguments[4];
					//the regular expression used to stip tags
					stripperRE = "</?(" & listChangeDelims(badTags,"|") & ")[^>]*>";	
					//Deal with "smart quotes" and other "special" chars from MS Word
					theText = replaceList(theText,chr(8216) & "," & chr(8217) & "," & chr(8220) & "," & chr(8221) & "," & chr(8212) & "," & chr(8213) & "," & chr(8230),"',',"","",--,--,...");
					//if escaping, run through the code bracket by bracket and escape the bad tags.
					if(mode is "escape"){
						//go until no more open brackets to find
						while(obracket){
							//find the next instance of one of the bad tags
							badTag = REFindNoCase(stripperRE,theText,obracket,1);
							//if a bad tag is found, escape it
							if(badTag.pos[1]){
								theText = replace(theText,mid(TheText,badtag.pos[1],badtag.len[1]),HTMLEditFormat(mid(TheText,badtag.pos[1],badtag.len[1])),"ALL");
								nextStart = badTag.pos[1] + badTag.len[1];
							}
							//if no bad tag is found, move on
							else{
								nextStart = obracket + 1;
							}
							//find the next open bracket
							obracket = find("<",theText,nextStart);
						}
					}
					//if not escaping, assume stripping
					else{
						theText = REReplaceNoCase(theText,stripperRE,"","ALL");
					}
					//now kill the bad "events" (intra tag text)
					theText = REReplaceNoCase(theText,'(#ListChangeDelims(badEvents,"|")#)[^ >]*',"","ALL");
					//return theText
					return theText;
				}
				</cfscript>
				<!--- #################### end safeText() function #################### --->	
	
				<cfset newValue = safeText(newValue,true)>
				
			</cfif>
			
			<cfif stPD.tidyWordHTML>
			
				<cfscript>
					function tidyWordHTML(html) {
						var foundAt = 0;
						html = replaceNoCase(html," class=MsoNormalTable","","all");
						html = replaceNoCase(html," class=""MsoNormalTable""","","all");
						html = replaceNoCase(html," class=MsoNormal","","all");
						html = replaceNoCase(html," class=""MsoNormal""","","all");	
						html = reReplace(html,"[[:space:]]+lang=""{0,1}[A-Z]{2}\-[A-Z]{2}""{0,1}","","all");	
						html = reReplaceNoCase(html,"[[:space:]]+class=("")?mso[^[:space:]\>]*","","all");
						html = reReplaceNoCase(html,"\<\?xml[^\>]+\>","","all");
						html = reReplaceNoCase(html, "</?[A-Za-z0-9]+:[A-Za-z0-9]+[^>]*>", "", "all");
						do {
							html = reReplaceNoCase(html, "<span>([^<]*)?</span>", "\1", "all");
						} while ( reFindNoCase("<span>([^<]*)?</span>",html) );
						return html;
					}
				</cfscript>
				
				<cfset newValue = tidyWordHTML(newValue)>
			
			</cfif>
			
			<cfif isDefined("stPD.replaceParagraphs") and stPD.replaceParagraphs>
			
				<cfscript>
					// remove attributes
					newValue = reReplaceNoCase(newValue,"<p[^>]*>","<p>","all");
					// remove first tag
					newValue = reReplace(newValue,"^[[:space:]]*<p>","");
					// remove all closing tags
					newValue = replaceNoCase(newValue,"</p>","","all");
					// replace remaining p tags with two br tags
					newValue = replace(newValue,"<p>","<br/><br/>","all");
				</cfscript>
					
			<cfelseif stPD.forceParagraphs>
				
				<cfset newValue = request.speck.forceParagraphs(newValue)>
			
			</cfif>
			
			<cfif stPD.tidy>
				
				<cftry>
				
					<cf_spTidy html="#newValue#" r_tidy="newValue">
					
					<!--- remove empty attributes from HTML tags --->
					<cfscript>
						do {
							newValue = reReplaceNoCase(newValue, "(<[a-z]+[^>]*)[[:space:]]+([a-z]+="""")([^>]*>)", "\1\3", "all");
						} while ( reFindNoCase("(<[a-z]+[^>]*)[[:space:]]+([a-z]+="""")([^>]*>)",newValue) );
					</cfscript>
					
				<cfcatch><!--- do nothing, add some debugging code here ---></cfcatch>
				</cftry>			
			
			</cfif>
			
			<cfif not stPD.allowStyle>
		
				<!--- remove style attributes from HTML tags --->
				<cfset newValue = reReplaceNoCase(newValue, "(<[A-Za-z]+[^>]*)[[:space:]]+(style=""[^"">]*"")([^>]*>)", "\1\3", "all")>

			</cfif>			
			
			<cfif not stPD.allowClass>
		
				<!--- remove class attributes from HTML tags --->
				<cfset newValue = reReplaceNoCase(newValue, "(<[A-Za-z]+[^>]*)[[:space:]]+(class=""[^"">]*"")([^>]*>)", "\1\3", "all")>

			</cfif>
			
			<cfif not stPD.allowTarget>
		
				<!--- remove target attributes --->
				<cfset newValue = reReplaceNoCase(newValue, "(<[A-Za-z]+[^>]*)[[:space:]]+(target=""[^"">]*"")([^>]*>)", "\1\3", "all")>

			</cfif>
			
			<!--- replace ISO-Latin-1 currency character and ISO-Latin-9 euro character with euro HTML entity --->
			<cfset newValue = replace(newValue,chr(164),"&euro;","ALL")>
			
			<!--- automatically obfuscate email addresses to try and prevent harvesting --->
			<!---
				
				This library is part of the Common Function Library Project. An open source
				collection of UDF libraries designed for ColdFusion 5.0. For more information,
				please see the web site at:
					
					http://www.cflib.org
					
				Warning:
				You may not need all the functions in this library. If speed
				is _extremely_ important, you may want to consider deleting
				functions you do not plan on using. Normally you should not
				have to worry about the size of the library.
					
				License:
				This code may be used freely. 
				You may modify this code as you see fit, however, this header, and the header
				for the functions must remain intact.
				
				This code is provided as is.  We make no warranty or guarantee.  Use of this code is at your own risk.
			--->
			<cfscript>
				/**
				 * When given an email address this function will return the address in a format safe from email harvesters.
				 * Minor edit by Rob Brooks-Bilson (rbils@amkor.com)
				 * Update now converts all characters in the email address to unicode, not just the @ symbol. (by author)
				 * 
				 * @param EmailAddress 	 Email address you want to make safe. (Required)
				 * @param Mailto 	 Boolean (Yes/No). Indicates whether to return formatted email address as a mailto link.  Default is No. (Optional)
				 * @return Returns a string 
				 * @author Seth Duffey (rbils@amkor.comsduffey@ci.davis.ca.us) 
				 * @version 2, May 2, 2002 
				 */
				function EmailAntiSpam(EmailAddress) {
					var i = 1;
					var antiSpam = "";
					for (i=1; i LTE len(EmailAddress); i=i+1) {
						antiSpam = antiSpam & "&##" & asc(mid(EmailAddress,i,1)) & ";";
					}
					if ((ArrayLen(Arguments) eq 2) AND (Arguments[2] is "Yes")) return "<a href=" & "mailto:" & antiSpam & ">" & antiSpam & "</a>"; 
					else return antiSpam;
				}
				
				while ( reFind("([a-zA-Z0-9][-a-zA-Z0-9_%\.']*)?[a-zA-Z0-9]@[a-zA-Z0-9][-a-zA-Z0-9%\>.]*\.[a-zA-Z]{2,}",newValue) ) {
					stMatch = reFind("([a-zA-Z0-9][-a-zA-Z0-9_%\.']*)?[a-zA-Z0-9]@[a-zA-Z0-9][-a-zA-Z0-9%\>.]*\.[a-zA-Z]{2,}",newValue,1,true);
					newValue = left(newValue,stMatch.pos[1] - 1) & emailAntiSpam(mid(newValue,stMatch.pos[1],stMatch.len[1])) & mid(newValue,stMatch.pos[1] + stMatch.len[1],len(newValue));
				}
			</cfscript>
			
			<!--- automatically add http protocol to links that look like they are external http links --->
			<cfset newValue = reReplaceNoCase(newValue,"href=""([A-Za-z]+\.[A-Za-z]+)","href=""http://\1","all")>
			
		
			<cfif stPD.forceRelativeLinks>
			
				<!--- remove protocol and host name from hrefs that look like they should be relative --->
				<cfset newValue = reReplaceNoCase(newValue,"href=""(http(s)?://)?#cgi.HTTP_HOST#(/)?","href=""/","all")>
				
			</cfif>
			
			<cfif stPD.forceTarget>
			
				<!--- remove target for local links and force target="_blank" for external links --->
				<cfset newValue = reReplaceNoCase(newValue,"(<[A-Za-z]+[^>]*)[[:space:]]+(target=(""|')[^""'>]*(""|'))([^>]*>)", "\1\5", "all")>
				<cfset newValue = reReplaceNoCase(newValue,"(href=""http(s)?://[^>]*)","\1 target=""_blank""","all")>
				
			</cfif>
			
			<cfif stPD.escapeHTML>
			
				<cfscript>	
					function escapeHTML(inHTML) {
					
						// * Returns input with all non-latin1 characters html escaped, 
						//   or all non-ascii characters if second argument is true.
						// * Code points 128-159 inclusive are assumed to be Windows 1252.
						// * Code points above 255 only escaped if CF version gte 6.
						
						var lFind = "";
						var lReplace = "";
						// vars used when creating numerical html character references (only used when no matching entity name found)
						var outHTML = "";
						var x = 1; 
						var y = 1;
						var convertLatin1 = ( arrayLen(arguments) gt 1 and isBoolean(arguments[2]) and arguments[2] );
						
						// convert windows 1252 chars to nearest equivalent html entity
						lFind = "#chr(128)#,#chr(130)#,#chr(131)#,#chr(132)#,#chr(133)#,#chr(134)#,#chr(135)#,#chr(136)#,#chr(137)#,#chr(138)#,#chr(139)#,#chr(140)#,#chr(142)#,#chr(145)#,#chr(146)#,#chr(147)#,#chr(148)#,#chr(149)#,#chr(150)#,#chr(151)#,#chr(152)#,#chr(153)#,#chr(154)#,#chr(155)#,#chr(156)#,#chr(158)#,#chr(159)#";
						lReplace = "&euro;,&sbquo;,&fnof;,&bdquo;,&hellip;,&dagger;,&Dagger;,&circ;,&permil;,&Scaron;,&lsaquo;,&OElig;,&##381;,&lsquo;,&rsquo;,&ldquo;,&rdquo;,&bull;,&ndash;,&mdash;,#chr(126)#,&trade;,&scaron;,&rsaquo;,&oelig;,&##382;,&Yuml;";
						inHTML = replaceList(inHTML, lFind, lReplace);
						
						if ( convertLatin1 ) {
							
							// replace latin1 chars not in ascii with matching html entities (latin1 code points are same as unicode)		
							lFind = "#chr(160)#,#chr(161)#,#chr(162)#,#chr(163)#,#chr(164)#,#chr(165)#,#chr(166)#,#chr(167)#,#chr(168)#,#chr(169)#,#chr(170)#,#chr(171)#,#chr(172)#,#chr(173)#,#chr(174)#,#chr(175)#,#chr(176)#,#chr(177)#,#chr(178)#,#chr(179)#,#chr(180)#,#chr(181)#,#chr(182)#,#chr(183)#,#chr(184)#,#chr(185)#,#chr(186)#,#chr(187)#,#chr(188)#,#chr(189)#,#chr(190)#,#chr(191)#,#chr(192)#,#chr(193)#,#chr(194)#,#chr(195)#,#chr(196)#,#chr(197)#,#chr(198)#,#chr(199)#,#chr(200)#,#chr(201)#,#chr(202)#,#chr(203)#,#chr(204)#,#chr(205)#,#chr(206)#,#chr(207)#,#chr(208)#,#chr(209)#,#chr(210)#,#chr(211)#,#chr(212)#,#chr(213)#,#chr(214)#,#chr(215)#,#chr(216)#,#chr(217)#,#chr(218)#,#chr(219)#,#chr(220)#,#chr(221)#,#chr(222)#,#chr(223)#,#chr(224)#,#chr(225)#,#chr(226)#,#chr(227)#,#chr(228)#,#chr(229)#,#chr(230)#,#chr(231)#,#chr(232)#,#chr(233)#,#chr(234)#,#chr(235)#,#chr(236)#,#chr(237)#,#chr(238)#,#chr(239)#,#chr(240)#,#chr(241)#,#chr(242)#,#chr(243)#,#chr(244)#,#chr(245)#,#chr(246)#,#chr(247)#,#chr(248)#,#chr(249)#,#chr(250)#,#chr(251)#,#chr(252)#,#chr(253)#,#chr(254)#,#chr(255)#";			
							lReplace = "&nbsp;,&iexcl;,&cent;,&pound;,&curren;,&yen;,&brvbar;,&sect;,&uml;,&copy;,&ordf;,&laquo;,&not;,&shy;,&reg;,&macr;,&deg;,&plusmn;,&sup2;,&sup3;,&acute;,&micro;,&para;,&middot;,&cedil;,&sup1;,&ordm;,&raquo;,&frac14;,&frac12;,&frac34;,&iquest;,&Agrave;,&Aacute;,&Acirc;,&Atilde;,&Auml;,&Aring;,&AElig;,&Ccedil;,&Egrave;,&Eacute;,&Ecirc;,&Euml;,&Igrave;,&Iacute;,&Icirc;,&Iuml;,&ETH;,&Ntilde;,&Ograve;,&Oacute;,&Ocirc;,&Otilde;,&Ouml;,&times;,&Oslash;,&Ugrave;,&Uacute;,&Ucirc;,&Uuml;,&Yacute;,&THORN;,&szlig;,&agrave;,&aacute;,&acirc;,&atilde;,&auml;,&aring;,&aelig;,&ccedil;,&egrave;,&eacute;,&ecirc;,&euml;,&igrave;,&iacute;,&icirc;,&iuml;,&eth;,&ntilde;,&ograve;,&oacute;,&ocirc;,&otilde;,&ouml;,&divide;,&oslash;,&ugrave;,&uacute;,&ucirc;,&uuml;,&yacute;,&thorn;,&yuml";
							inHTML = replaceList(inHTML, lFind, lReplace);
						
						}
						
						if ( listFirst(request.speck.cfVersion) gte 6 ) {
						
							// replace unicode characters with html entities
							// special characters first
							lFind = "#chr(338)#,#chr(339)#,#chr(352)#,#chr(353)#,#chr(376)#,#chr(710)#,#chr(732)#,#chr(8194)#,#chr(8195)#,#chr(8201)#,#chr(8204)#,#chr(8205)#,#chr(8206)#,#chr(8207)#,#chr(8211)#,#chr(8212)#,#chr(8216)#,#chr(8217)#,#chr(8218)#,#chr(8220)#,#chr(8221)#,#chr(8222)#,#chr(8224)#,#chr(8225)#,#chr(8240)#,#chr(8249)#,#chr(8250)#,#chr(8364)#";
							lReplace = "&OElig;,&oelig;,&Scaron;,&scaron;,&Yuml;,&circ;,&tilde;,&ensp;,&emsp;,&thinsp;,&zwnj;,&zwj;,&lrm;,&rlm;,&ndash;,&mdash;,&lsquo;,&rsquo;,&sbquo;,&ldquo;,&rdquo;,&bdquo;,&dagger;,&Dagger;,&permil;,&lsaquo;,&rsaquo;,&euro;";
							inHTML = replaceList(inHTML, lFind, lReplace);
							// and now symbols
							lFind = "#chr(402)#,#chr(913)#,#chr(914)#,#chr(915)#,#chr(916)#,#chr(917)#,#chr(918)#,#chr(919)#,#chr(920)#,#chr(921)#,#chr(922)#,#chr(923)#,#chr(924)#,#chr(925)#,#chr(926)#,#chr(927)#,#chr(928)#,#chr(929)#,#chr(931)#,#chr(932)#,#chr(933)#,#chr(934)#,#chr(935)#,#chr(936)#,#chr(937)#,#chr(945)#,#chr(946)#,#chr(947)#,#chr(948)#,#chr(949)#,#chr(950)#,#chr(951)#,#chr(952)#,#chr(953)#,#chr(954)#,#chr(955)#,#chr(956)#,#chr(957)#,#chr(958)#,#chr(959)#,#chr(960)#,#chr(961)#,#chr(962)#,#chr(963)#,#chr(964)#,#chr(965)#,#chr(966)#,#chr(967)#,#chr(968)#,#chr(969)#,#chr(977)#,#chr(978)#,#chr(982)#,#chr(8226)#,#chr(8230)#,#chr(8242)#,#chr(8243)#,#chr(8254)#,#chr(8260)#,#chr(8472)#,#chr(8465)#,#chr(8476)#,#chr(8482)#,#chr(8501)#,#chr(8592)#,#chr(8593)#,#chr(8594)#,#chr(8595)#,#chr(8596)#,#chr(8629)#,#chr(8656)#,#chr(8657)#,#chr(8658)#,#chr(8659)#,#chr(8660)#,#chr(8704)#,#chr(8706)#,#chr(8707)#,#chr(8709)#,#chr(8711)#,#chr(8712)#,#chr(8713)#,#chr(8715)#,#chr(8719)#,#chr(8721)#,#chr(8722)#,#chr(8727)#,#chr(8730)#,#chr(8733)#,#chr(8734)#,#chr(8736)#,#chr(8743)#,#chr(8744)#,#chr(8745)#,#chr(8746)#,#chr(8747)#,#chr(8756)#,#chr(8764)#,#chr(8773)#,#chr(8776)#,#chr(8800)#,#chr(8801)#,#chr(8804)#,#chr(8805)#,#chr(8834)#,#chr(8835)#,#chr(8836)#,#chr(8838)#,#chr(8839)#,#chr(8853)#,#chr(8855)#,#chr(8869)#,#chr(8901)#,#chr(8968)#,#chr(8969)#,#chr(8970)#,#chr(8971)#,#chr(9001)#,#chr(9002)#,#chr(9674)#,#chr(9824)#,#chr(9827)#,#chr(9829)#,#chr(9830)#";
							lReplace = "&fnof;,&Alpha;,&Beta;,&Gamma;,&Delta;,&Epsilon;,&Zeta;,&Eta;,&Theta;,&Iota;,&Kappa;,&Lambda;,&Mu;,&Nu;,&Xi;,&Omicron;,&Pi;,&Rho;,&Sigma;,&Tau;,&Upsilon;,&Phi;,&Chi;,&Psi;,&Omega;,&alpha;,&beta;,&gamma;,&delta;,&epsilon;,&zeta;,&eta;,&theta;,&iota;,&kappa;,&lambda;,&mu;,&nu;,&xi;,&omicron;,&pi;,&rho;,&sigmaf;,&sigma;,&tau;,&upsilon;,&phi;,&chi;,&psi;,&omega;,&thetasym;,&upsih;,&piv;,&bull;,&hellip;,&prime;,&Prime;,&oline;,&frasl;,&weierp;,&image;,&real;,&trade;,&alefsym;,&larr;,&uarr;,&rarr;,&darr;,&harr;,&crarr;,&lArr;,&uArr;,&rArr;,&dArr;,&hArr;,&forall;,&part;,&exist;,&empty;,&nabla;,&isin;,&notin;,&ni;,&prod;,&sum;,&minus;,&lowast;,&radic;,&prop;,&infin;,&ang;,&and;,&or;,&cap;,&cup;,&int;,&there4;,&sim;,&cong;,&asymp;,&ne;,&equiv;,&le;,&ge;,&sub;,&sup;,&nsub;,&sube;,&supe;,&oplus;,&otimes;,&perp;,&sdot;,&lceil;,&rceil;,&lfloor;,&rfloor;,&lang;,&rang;,&loz;,&spades;,&clubs;,&hearts;,&diams;";
							inHTML = replaceList(inHTML, lFind, lReplace);

							// catch all to replace other characters with numerical html character references as required...
							x = reFind("[^#chr(1)#-#chr(255)#]",inHTML); // x marks the spot
							if ( x eq 0 ) // nothing to escape
								return inHTML;
							while ( x neq 0 ) {	
								outHTML = outHTML & mid(inHTML,y,x-y) & "&##" & asc(mid(inHTML,x,1)) & ";";
								y = x + 1;
								x = reFind("[^#chr(1)#-#chr(255)#]",inHTML,y);
							}
							// get the rest of the string if a special character wasn't found at the end of the string
							if ( (len(inHTML)+1) neq y )
								outHTML = outHTML & mid(inHTML,y,(len(inHTML)+1)-y);

							return outHTML;

						} else {
						
							return inHTML;
						}
					}
				</cfscript>
				
				<cfset newValue = escapeHTML(newValue)>

			</cfif>
		
		</cfif>

	</cf_spPropertyHandlerMethod>	

	
	<cf_spPropertyHandlerMethod method="renderFormField">
	
		<cfif listLen(stPD.displaySize) eq 2>
		
			<cfif stPD.richEdit>
					
				<!---
				The editor can be customised per application in a number of ways:
				[1] FCKeditor configuration settings that take simple values can be added to an fckeditor
					configuration file for the application, i.e. <appInstallRoot>/fckeditor.cfg. The file 
					should have one section named [settings]. This method of configuration only allows for 
					simple name/value pairs, so it can't be used to change key bindings or toolbars. It's 
					still the recommended method of configuring FCKeditor per application though.
				[2] The toolbar, width, height, editor area css, options for the format drop down in 
					the toolbar and even a custom configuration path can be set using attributes of 
					cf_spProperty. These attribtues are the FCKEditor config setting, prefixed with "fck", 
					e.g. fckToolbarSet="Basic". The toolbar set and height are typically the only things 
					that need to be changed using an attribute of cf_spProperty.
				[3] Speck will automatically set the EditorAreaCSS, StylesXmlPath and TemplatesXmlPath 
					if you put matching files into the stylesheets directory (fckeditor.css, fckstyles.xml 
					and fcktemplates.xml respectively) and these settings have not already been configured.
				[4]	You can also tell Speck to load your own FCKeditor CustomConfigurationsPath rather 
					then the default Speck one by simply dropping a file called fckconfig.js into a 
					<appInstallRoot>/www/javascripts directory. You should really only need to do this 
					if you need to change key bindings or add/modify toolbars.
				Note that the ImageBrowserURL and SpellerPagesServerScript settings cannot be customised.
				--->
				<cfscript>
					// build a single config struct from the config file and cf_spProperty attributes
					if ( isDefined("request.speck.config.fckeditor.settings") ) {
						stConfig = duplicate(request.speck.config.fckeditor.settings);
					} else {
						stConfig = structNew();
					}
					// optional cf_spProperty attributes (some have default values, some don't)...
					// ToolbarSet
					if ( isDefined("stPD.fckToolbarSet") ) { 
						stConfig.ToolbarSet = stPD.fckToolbarSet;
					} else if ( not isDefined("stConfig.ToolbarSet") ) {
						// default toolbar
						stConfig.ToolbarSet = "Default"; 
					}
					// CustomConfigurationsPath
					if ( isDefined("stPD.fckCustomConfigurationsPath") and len(stPD.fckCustomConfigurationsPath) ) { 
						stConfig.CustomConfigurationsPath = stPD.fckCustomConfigurationsPath;
					}
					// Width
					if ( isDefined("stPD.fckWidth") ) { 
						stConfig.Width = stPD.fckWidth;
					} else if ( not isDefined("stConfig.Width") ) {
						// default width
						stConfig.Width = "100%"; 
					}
					// Height
					if ( isDefined("stPD.fckHeight") ) { 
						stConfig.Height = stPD.fckHeight;
					} else if ( not isDefined("stConfig.Height") ) {
						// default height
						stConfig.Height = "250"; 
					}
					// EditorAreaCSS (note: no default value)
					if ( isDefined("stPD.fckEditorAreaCSS") and len(stPD.fckEditorAreaCSS) ) { 
						stConfig.EditorAreaCSS = stPD.fckEditorAreaCSS; 
					}
					// FontFormats (note: no default value)
					if ( isDefined("stPD.fckFontFormats") and len(stPD.fckFontFormats) ) { 
						stConfig.FontFormats = stPD.fckFontFormats; 
					}
					
					fs = request.speck.fs;
					// automatically set EditorAreaCSS, StylesXmlPath and TemplatesXmlPath if settings not found in config struct
					if ( ( not structKeyExists(stConfig,"EditorAreaCSS") or not len(stConfig.EditorAreaCSS) ) and fileExists(request.speck.appInstallRoot & fs & "www" & fs & "stylesheets" & fs & "fckeditor.css") ) {
						stConfig.EditorAreaCSS = "/stylesheets/fckeditor.css";
					}
					if ( not structKeyExists(stConfig,"StylesXmlPath") or not len(stConfig.StylesXmlPath) ) {
						if ( fileExists(request.speck.appInstallRoot & fs & "www" & fs & "stylesheets" & fs & "fckstyles.xml") ) {
							stConfig.StylesXmlPath = "/stylesheets/fckstyles.xml";
						} else {
							stConfig.StylesXmlPath = "/speck/properties/html/editors/fckeditor/speckstyles.xml";
						}
					}
					if ( not structKeyExists(stConfig,"TemplatesXmlPath") or not len(stConfig.TemplatesXmlPath) ) {
						if ( fileExists(request.speck.appInstallRoot & fs & "www" & fs & "stylesheets" & fs & "fcktemplates.xml") ) {
							stConfig.TemplatesXmlPath = "/stylesheets/fcktemplates.xml";
						} else {
							stConfig.TemplatesXmlPath = "/speck/properties/html/editors/fckeditor/specktemplates.xml";
						}
					}
					// if CustomConfigurationsPath not set in config struct, set to app specific fckconfig.js if exists, otherwise default speck configuration
					if ( not structKeyExists(stConfig,"CustomConfigurationsPath") or not len(stConfig.CustomConfigurationsPath) ) {
						if ( fileExists(request.speck.appInstallRoot & fs & "www" & fs & "javascripts" & fs & "fckconfig.js") ) {
							stConfig.CustomConfigurationsPath = "/javascripts/fckconfig.js";
						} else {
							stConfig.CustomConfigurationsPath = "/speck/properties/html/editors/fckeditor/speckconfig.js";
						}
					}
					stConfig.CustomConfigurationsPath = stConfig.CustomConfigurationsPath & "?" & getTickCount();			
					
					// hide the target option from the link dialog window when either target aren't allowed or are forced by readFormField
					if ( not stPD.allowTarget or stPD.forceTarget) { stConfig.LinkDlgHideTarget = true; }
					
					// force built-in Speck connector as ImageBrowserURL
					connectorURL = "/speck/properties/html/editors/fckeditor/speckconnector.cfm?app=" & request.speck.appName;
					// append optional attributes for image re-sizing to connector url
					connectorURL = connectorURL & "&width=" & stPD.imageWidth;
					connectorURL = connectorURL & "&height=" & stPD.imageHeight;
					connectorURL = connectorURL & "&maxWidth=" & stPD.imageMaxWidth;
					connectorURL = connectorURL & "&maxHeight=" & stPD.imageMaxHeight;
					connectorURL = connectorURL & "&cropToExact=" & stPD.imageCropToExact;
					connectorURL = connectorURL & "&jpegCompression=" & stPD.imageJpegCompression;
					stConfig.ImageBrowserURL = "/speck/properties/html/editors/fckeditor/editor/filemanager/browser/default/browser.html?Type=Image&Connector=" & urlEncodedFormat(connectorURL);
					
					// force use of Speck spellerpages script (the one included with FCKeditor still hasn't been updated to work with *nix)
					stConfig.SpellerPagesServerScript = '/speck/properties/html/editors/fckeditor/speckspellchecker.cfm';
			
					// if forceParagraphs set to true, then force UseBROnCarriageReturn to false (Speck defaults to true) and switch enter modes around
					if ( stPD.forceParagraphs ) {
						stConfig.UseBROnCarriageReturn = false;
						stConfig.EnterMode = "p";
						stConfig.ShiftEnterMode = "br";
					}
				</cfscript>
				
				<cfif fileExists(request.speck.speckInstallRoot & "/www/properties/html/editors/fckeditor/fckutils.cfm")>
				
					<cfinclude template="/speck/../www/properties/html/editors/fckeditor/fckutils.cfm">
					
					<cfset isCompatibleBrowser = FCKeditor_IsCompatibleBrowser()>
					
				<cfelse>
				
					<!--- old code to check browser compatibility in earlier FCKeditor versions --->
					<cfscript>
						userAgent = lCase(cgi.http_user_agent);
						isCompatibleBrowser = false;
						
						// check for Internet Explorer ( >= 5.5 )
						if ( find("msie", userAgent) and not find("mac", userAgent) and not find("opera", userAgent) ) {
					
							browserVersion = mid(userAgent, findNoCase("msie", userAgent) + 5, 3);
							if ( isNumeric(browserVersion) and browserVersion gte 5.5 ) {
								isCompatibleBrowser = true;
							}
							
						} else if( find( "gecko/", userAgent ) ) {
		
							stResult = reFind("gecko/([0-9]{8})", userAgent, 1, true);
							if( arrayLen( stResult.pos ) eq 2 ) {
								browserVersion = mid(userAgent, stResult.pos[2], stResult.len[2]);
								if( isNumeric(browserVersion) and browserVersion gte 20030210 )
									isCompatibleBrowser = true;
							}
						}
					</cfscript>
				
				</cfif>
				
				<cfif isCompatibleBrowser>
				
					<cfscript>
						lConfigKeys = "";
						lConfigKeys = lConfigKeys & "CustomConfigurationsPath,EditorAreaCSS,ToolbarComboPreviewCSS,DocType";
						lConfigKeys = lConfigKeys & ",BaseHref,FullPage,Debug,AllowQueryStringDebug,SkinPath";
						lConfigKeys = lConfigKeys & ",PreloadImages,PluginsPath,AutoDetectLanguage,DefaultLanguage,ContentLangDirection";
						lConfigKeys = lConfigKeys & ",ProcessHTMLEntities,IncludeLatinEntities,IncludeGreekEntities,ProcessNumericEntities,AdditionalNumericEntities";
						lConfigKeys = lConfigKeys & ",FillEmptyBlocks,FormatSource,FormatOutput,FormatIndentator";
						lConfigKeys = lConfigKeys & ",StartupFocus,ForcePasteAsPlainText,AutoDetectPasteFromWord,ForceSimpleAmpersand";
						lConfigKeys = lConfigKeys & ",TabSpaces,ShowBorders,SourcePopup,ToolbarStartExpanded,ToolbarCanCollapse";
						lConfigKeys = lConfigKeys & ",IgnoreEmptyParagraphValue,FloatingPanelsZIndex,TemplateReplaceAll,TemplateReplaceCheckbox";
						lConfigKeys = lConfigKeys & ",ToolbarLocation,ToolbarSets,EnterMode,ShiftEnterMode,Keystrokes";
						lConfigKeys = lConfigKeys & ",ContextMenu,BrowserContextMenuOnCtrl,FontColors,FontNames,FontSizes";
						lConfigKeys = lConfigKeys & ",FontFormats,StylesXmlPath,TemplatesXmlPath,SpellChecker,IeSpellDownloadUrl";
						lConfigKeys = lConfigKeys & ",SpellerPagesServerScript,FirefoxSpellChecker,MaxUndoLevels,DisableObjectResizing,DisableFFTableHandles";
						lConfigKeys = lConfigKeys & ",LinkDlgHideTarget,LinkDlgHideAdvanced,ImageDlgHideLink,ImageDlgHideAdvanced,FlashDlgHideAdvanced";
						lConfigKeys = lConfigKeys & ",ProtectedTags,BodyId,BodyClass,DefaultLinkTarget,CleanWordKeepsStructure";
						lConfigKeys = lConfigKeys & ",LinkBrowser,LinkBrowserURL,LinkBrowserWindowWidth,LinkBrowserWindowHeight,ImageBrowser";
						lConfigKeys = lConfigKeys & ",ImageBrowserURL,ImageBrowserWindowWidth,ImageBrowserWindowHeight,FlashBrowser,FlashBrowserURL";
						lConfigKeys = lConfigKeys & ",FlashBrowserWindowWidth ,FlashBrowserWindowHeight,LinkUpload,LinkUploadURL,LinkUploadWindowWidth";
						lConfigKeys = lConfigKeys & ",LinkUploadWindowHeight,LinkUploadAllowedExtensions,LinkUploadDeniedExtensions,ImageUpload,ImageUploadURL";
						lConfigKeys = lConfigKeys & ",ImageUploadAllowedExtensions,ImageUploadDeniedExtensions,FlashUpload,FlashUploadURL,FlashUploadAllowedExtensions";
						lConfigKeys = lConfigKeys & ",FlashUploadDeniedExtensions,SmileyPath,SmileyImages,SmileyColumns,SmileyWindowWidth,SmileyWindowHeight";
		
						fckConfig = "";
						
						for ( key in stConfig ) {
							listPosition = listFindNoCase(lConfigKeys, key);
							if ( listPosition gt 0 ) {
								if ( len( fckConfig ) )
									fckConfig = fckConfig & "&amp;";
					
								fieldValue = stConfig[key];
								fieldName = listGetAt( lConfigKeys, listPosition );
								
								fckConfig = fckConfig & fieldName & '=' & urlEncodedFormat(fieldValue);
							}
						}						
					
						fckUrl = "/speck/properties/html/editors/fckeditor/editor/fckeditor.html?InstanceName=" & stPD.name & "&Toolbar=" & stConfig.ToolbarSet; // & "&" & getTickCount();
					</cfscript>
				
					<cfoutput>
					<div>
					<input type="hidden" id="#stPD.name#" name="#stPD.name#" value="#htmlEditFormat(value)#" />
					<input type="hidden" id="#stPD.name#___Config" value="#fckConfig#" />
					<iframe id="#stPD.name#___Frame" src="#fckUrl#" width="#stConfig.Width#" height="#stConfig.Height#" frameborder="no" scrolling="no"></iframe>
					</div>
					</cfoutput>
				
				<cfelse>
				
					<cfoutput>
					<textarea id="#stPD.name#" style="width: #stConfig.Width#; height: #stConfig.Height#;" name="#stPD.name#" wrap="virtual" cols="#listFirst(stPD.displaySize)#" rows="#listLast(stPD.displaySize)#">#value#</textarea>
					</cfoutput>
				
				</cfif>
					
			<cfelse>
			
				<cfoutput><textarea class="html" name="#stPD.name#" wrap="virtual" cols="#listFirst(stPD.displaySize)#" rows="#listLast(stPD.displaySize)#">#value#</textarea></cfoutput>
			
			</cfif> <!--- stPD.richEdit --->
		
		<cfelse>
			
			<cfoutput><input class="html" type="text" name="#stPD.name#" value="#replace(value,"""","&quot;","all")#" size="#stPD.displaySize#" maxlength="#stPD.maxlength#"></cfoutput>
		
		</cfif>
	
	</cf_spPropertyHandlerMethod>
	
	
</cf_spPropertyHandler>
