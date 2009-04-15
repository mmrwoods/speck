<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com),
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!---
Produces an RSS 2.0 feed from Speck content

example usage:
<cf_spRssExport
	type="article"
	title="mySite.com"
	description="All About Me"
	link="http://www.mysite.com"
	itemBaseUrl="http://www.mysite.com/index.cfm?articleId="
	itemTitle="title"
	itemDescription="summary"
	itemImage="thumbnail"
	ttl="1440"
	r_xml="xml">
<cfoutput>#xml#</cfoutput>

TODO : documentation. In the meantime, note that there is one required attribute,
the Speck content type. All other attributes are optional are and are cfparamed
in the "optional attributes..." section below. It should be easy enough to figure
out how to use it from the optional attributes and the code comments.
--->

<!--- check for required attributes --->
<cfif not isDefined("attributes.type")>

	<cfthrow message="Missing required attribute 'type'">

	<cfexit method="EXITTAG">

</cfif>

<!--- get type information --->
<cfmodule template=#request.speck.getTypeTemplate(attributes.type)# r_stType="stType">

<!--- optional attributes... --->

<!--- return variable for xml output --->
<cfparam name="attributes.r_xml" default="xml">

<!--- attributes to pass to spContentGet --->
<cfparam name="attributes.orderby" default="spCreated DESC">
<cfparam name="attributes.where" default="">
<cfparam name="attributes.label" default="">
<cfparam name="attributes.keywords" default="">
<cfparam name="attributes.maxRows" default="10">

<!--- channel related attributes --->
<cfparam name="attributes.about" default="http://#cgi.http_host##cgi.script_name#">
<cfparam name="attributes.title" default="#stType.name#">
<cfparam name="attributes.description" default="#stType.description#">
<cfparam name="attributes.link" default="http://#cgi.http_host#">
<cfparam name="attributes.image" default=""> <!--- image url, recommended image dimensions - 88x31 pixels --->
<cfparam name="attributes.imageWidth" default="88">
<cfparam name="attributes.imageHeight" default="31">
<cfparam name="attributes.ttl" default="1440"> <!--- 24 hours --->
<cfparam name="attributes.copyright" default=""> <!--- copyright notice --->
<cfparam name="attributes.managingEditor" default="">
<cfparam name="attributes.webMaster" default="">

<!--- item related attributes - TODO: option to obtain pubDate from speck property rather than spCreated --->
<cfparam name="attributes.itemBaseUrl" default="http://#cgi.http_host##cgi.script_name#?#cgi.query_string#&amp;id=">
<cfif left(attributes.itemBaseUrl,1) eq "/">
	<cfset attributes.itemBaseUrl = "http://" & cgi.server_name & attributes.itemBaseUrl>
</cfif>
<cfparam name="attributes.itemUrlSuffix" default="">
<cfparam name="attributes.itemId" default="spId"> <!--- speck property/column from which to obtain item title --->
<cfparam name="attributes.itemTitle" default="spLabel"> <!--- speck property/column from which to obtain item title --->
<cfparam name="attributes.itemDescription" default=""> <!--- speck property/column from which to obtain item description --->
<cfparam name="attributes.itemPubDate" default=""> <!--- speck property from which to obtain item publication date --->
<cfparam name="attributes.itemAuthor" default=""> <!--- speck property from which to obtain item author --->
<cfparam name="attributes.itemImage" default=""> <!--- speck property from which to obtain item image --->
<cfparam name="attributes.itemImageBaseUrl" default="http://#cgi.http_host#">

<!--- content elements (see http://purl.org/rss/1.0/modules/content) --->
<cfparam name="attributes.itemContent" default=""> <!--- speck property/column from which to obtain item content --->

<!--- get the content --->
<cf_spContentGet
	type="#attributes.type#"
	r_qcontent="qContent"
	where="#attributes.where#"
	label="#attributes.label#"
	keywords="#attributes.keywords#"
	orderby="#attributes.orderby#"
	maxrows="#attributes.maxRows#">

<!--- get current time, we may need this in a few places --->
<cfset currentTime = now()>

<cfset fs = request.speck.fs>

<cfset nl = chr(10) & chr(13)>

<cfscript>
	if ( left(request.speck.cfVersion,1) eq 5 ) {
		encoding = "ISO-8859-1";
	} else {
		encoding = "UTF-8";
	}
</cfscript>

<cfsavecontent variable="xml">
<cfoutput>
<?xml version="1.0" encoding="#encoding#"?>
<rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
</cfoutput>

	<cfoutput>
	<channel>
		<title>#xmlFormat(attributes.title)#</title>
		<description>#xmlFormat(attributes.description)#</description>
		<link>#attributes.link#</link>
		<generator>SpeckCMS</generator>
		<language>#request.speck.language#</language>
		<cfif len(attributes.copyright)><copyright>#xmlFormat(attributes.copyright)#</copyright>#nl#</cfif>
		<cfif len(attributes.managingEditor)><managingEditor>#xmlFormat(attributes.managingEditor)#</managingEditor>#nl#</cfif>
		<cfif len(attributes.webMaster)><webMaster>#xmlFormat(attributes.webMaster)#</webMaster>#nl#</cfif>
		<ttl>#attributes.ttl#</ttl>
		<pubDate>#dateFormat(currentTime,"ddd, dd mmm yyyy")# #timeFormat(currentTime,"HH:mm:ss")#</pubDate>
		<cfif len(attributes.image)>
			<image>
				<url>#attributes.image#</url>
				<title>#xmlFormat(attributes.title)#</title>
				<link>#attributes.link#</link>
				<width>attributes.imageWidth</width>
				<height>attributes.imageWidth</height>
			</image>
		</cfif>
		</cfoutput>

		<cfloop query="qContent">
			<cfoutput>
			<item>
				<title>#xmlFormat(evaluate(attributes.itemTitle))#</title>
				<link>#attributes.itemBaseUrl##evaluate(attributes.itemId)##attributes.itemUrlSuffix#</link>
				<guid isPermaLink="false">#evaluate(attributes.itemId)#</guid>
				<cfif len(attributes.itemDescription)><description>#xmlFormat(evaluate(attributes.itemDescription))#</description>#nl#</cfif>
				<cfif len(attributes.itemContent)><content:encoded><![CDATA[ #evaluate(attributes.itemContent)# ]]></content:encoded>#nl#</cfif>
				<cfif len(attributes.itemPubDate)>
					<cfset thisPubDate = evaluate(attributes.itemPubDate)>
				<cfelse>
					<cfset thisPubDate = spCreated>
				</cfif>
				<pubDate>#dateFormat(thisPubDate,"ddd, dd mmm yyyy")# #timeFormat(thisPubDate,"HH:mm:ss")#</pubDate>
				<cfif len(attributes.itemAuthor)><author>#xmlFormat(evaluate(attributes.itemAuthor))#</author>#nl#</cfif>
			</cfoutput>
	
			<cfif len(attributes.itemImage)>
				<cfset thisImage = evaluate(attributes.itemImage)>
				<cfif len(trim(thisImage))>
					<cfif REFindNoCase("^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{16}$", thisImage)>
						<!--- picked image - assume image content type and get thumbnail value --->
						<cf_spContentGet r_qcontent="qImage" type="Image" id="#thisImage#" properties="caption,thumbnail,thumbnailWidth,thumbnailHeight">
						<cfset thisImage = qImage.thumbnail>
					</cfif>
					<cfset imagePath = request.speck.appInstallRoot & fs & "www" & replace(thisImage,"/",fs,"all")>
					<cfif fileExists(imagePath)>
						<!--- get file size --->
						<cfdirectory action="list" directory="#listDeleteAt(imagePath,listLen(imagePath,fs),fs)#" filter="#listLast(imagePath,fs)#" name="qDir">
						<cfset imageSize = qDir.size>
						<cfset imageType = request.speck.getMimeType(listLast(imagePath,"."))>
						<cfoutput>
						<enclosure url="http://#cgi.http_host##thisImage#" length="#imageSize#" type="#imageType#" />
						</cfoutput>
					</cfif>
				</cfif>
			</cfif>
	
			<cfoutput>
			</item>
			</cfoutput>
		</cfloop>

	<cfoutput>
	</channel>
</rss>
</cfoutput>
</cfsavecontent>

<!--- return xml to caller --->
<cfset "caller.#attributes.r_xml#" = trim(xml)>