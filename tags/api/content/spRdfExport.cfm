<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com),
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!---
Produces an RSS 1.0 feed from Speck content

example usage:
<cf_spRdfExport
	type="article"
	title="mySite.com"
	description="All About Me"
	link="http://www.mysite.com"
	itemBaseUrl="http://www.mysite.com/index.cfm?articleId="
	itemTitle="title"
	itemDescription="summary"
	itemImage="thumbnail"
	updatePeriod="daily"
	updateFrequency="1"
	publisher="Mark Woods"
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

<!--- core rss elements and attributes (see http://purl.org/rss/1.0) --->
<cfparam name="attributes.about" default="http://#cgi.http_host##cgi.script_name#">
<cfparam name="attributes.title" default="#stType.name#">
<cfparam name="attributes.description" default="#stType.description#">
<cfparam name="attributes.link" default="http://#cgi.http_host#">
<cfparam name="attributes.image" default=""> <!--- image url, recommended image dimensions - 88x33 pixels (for backwards compatibility) --->
<cfparam name="attributes.itemBaseUrl" default="http://#cgi.http_host##cgi.script_name#?#cgi.query_string#&amp;id=">
<cfif left(attributes.itemBaseUrl,1) eq "/">
	<cfset attributes.itemBaseUrl = "http://" & cgi.server_name & attributes.itemBaseUrl>
</cfif>
<cfparam name="attributes.itemUrlSuffix" default="">
<cfparam name="attributes.itemId" default="spId"> <!--- speck property/column from which to obtain item title --->
<cfparam name="attributes.itemTitle" default="spLabel"> <!--- speck property/column from which to obtain item title --->
<cfparam name="attributes.itemDescription" default=""> <!--- speck property/column from which to obtain item description --->

<!--- content elements (see http://purl.org/rss/1.0/modules/content) --->
<cfparam name="attributes.itemContent" default=""> <!--- speck property/column from which to obtain item content --->

<!--- admin elements (see http://purl.org/rss/1.0/modules/admin)--->
<cfparam name="attributes.errorReportsTo" default=""> <!--- email address to send error reports to --->

<!--- syndication elements (see http://purl.org/rss/1.0/modules/syndication) --->
<cfparam name="attributes.updatePeriod" default="daily">
<cfparam name="attributes.updateFrequency" default="1">
<cfparam name="attributes.updateBase" default="2000-01-01T12:00Z">

<!--- dublin core elements (see http://purl.org/rss/1.0/modules/dc) --->
<cfparam name="attributes.creator" default="">
<cfparam name="attributes.publisher" default="">
<cfparam name="attributes.rights" default="">
<cfparam name="attributes.language" default="en-gb">
<cfparam name="attributes.itemCreator" default=""> <!--- speck property from which to obtain item creator --->
<cfparam name="attributes.itemSubject" default=""> <!--- speck property from which to obtain item subject --->

<!--- item image element (see http://www.peerfear.org/rss/proposed/image/mod_image.html) --->
<cfparam name="attributes.itemImage" default=""> <!--- speck property from which to obtain item image --->
<cfparam name="attributes.itemImageBaseUrl" default="http://#cgi.http_host#">

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
<rdf:RDF
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns##"
	xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:content="http://purl.org/rss/1.0/modules/content/"
	xmlns:image="http://purl.org/rss/1.0/modules/image/"
	xmlns:admin="http://purl.org/rss/1.0/modules/admin/"
	xmlns="http://purl.org/rss/1.0/"
>
</cfoutput>

	<cfoutput>
	<channel rdf:about="#attributes.about#">
		<title>#attributes.title#</title>
		<description>#attributes.description#</description>
		<link>#attributes.link#</link>
		<admin:generatorAgent rdf:resource="http://www.speckcms.org" />
		<cfif len(attributes.errorReportsTo)><admin:errorReportsTo rdf:resource="mailto:#attributes.errorReportsTo#" /></cfif>
		<sy:updatePeriod>#attributes.updatePeriod#</sy:updatePeriod>
		<sy:updateFrequency>#attributes.updateFrequency#</sy:updateFrequency>
		<sy:updateBase>#attributes.updateBase#</sy:updateBase>
		<dc:language>#attributes.language#</dc:language>
		<cfif len(attributes.creator)><dc:creator>#attributes.creator#</dc:creator></cfif>
		<cfif len(attributes.publisher)><dc:publisher>#attributes.publisher#</dc:publisher></cfif>
		<cfif len(attributes.rights)><dc:rights>#attributes.rights#</dc:rights></cfif>
		<dc:date>#dateFormat(currentTime,"YYYY-MM-DD")#T#timeFormat(currentTime,"HH:mm")#Z</dc:date>
		<cfif len(attributes.image)><image rdf:resource="#attributes.image#" /></cfif>
		<items>
			<rdf:Seq>
			<cfloop query="qContent">
				<rdf:li rdf:resource="#attributes.itemBaseUrl##evaluate(attributes.itemId)#" />
			</cfloop>
			</rdf:Seq>
		</items>
	</channel>
	</cfoutput>

	<cfif len(attributes.image)>
		<cfoutput>
		<image rdf:about="#attributes.image#">
			<title>#attributes.title#</title>
			<url>#attributes.image#</url>
			<link>#attributes.link#</link>
		</image>
		</cfoutput>
	</cfif>

	<cfloop query="qContent">
		<cfoutput>
		<item rdf:about="#attributes.itemBaseUrl##evaluate(attributes.itemId)##attributes.itemUrlSuffix#">
			<title>#xmlFormat(evaluate(attributes.itemTitle))#</title>
			<link>#attributes.itemBaseUrl##evaluate(attributes.itemId)##attributes.itemUrlSuffix#</link>
			<cfif len(attributes.itemDescription)><description>#xmlFormat(evaluate(attributes.itemDescription))#</description></cfif>
			<cfif len(attributes.itemContent)><content:encoded><![CDATA[ #evaluate(attributes.itemContent)# ]]></content:encoded></cfif>
			<dc:date>#dateFormat(spCreated,"YYYY-MM-DD")#T#timeFormat(spCreated,"HH:mm")#Z</dc:date>
			<cfif len(attributes.itemCreator)><dc:creator>#xmlFormat(evaluate(attributes.itemCreator))#</dc:creator></cfif>
			<cfif len(attributes.itemSubject)><dc:subject>#xmlFormat(evaluate(attributes.itemSubject))#</dc:subject></cfif>
		</cfoutput>

		<cfif len(attributes.itemImage)>
			<cfset thisImage = evaluate(attributes.itemImage)>
			<cfif len(trim(thisImage))>
				<cfif REFindNoCase("^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{16}$", thisImage)>
					<!--- picked image - assume image content type and get thumbnail value --->
					<cf_spContentGet r_qcontent="qImage" type="Image" id="#thisImage#" properties="caption,thumbnail,thumbnailWidth,thumbnailHeight">
					<cfoutput>
					<image:item rdf:about="http://#cgi.http_host##qImage.thumbnail#">
						<cfif len(trim(qImage.caption))><dc:title>#xmlFormat(qImage.caption)#</dc:title></cfif>
						<cfif len(qImage.thumbnailWidth) and len(qImage.thumbnailHeight)>
					    	<image:width>#qImage.thumbnailWidth#</image:width>
					    	<image:height>#qImage.thumbnailHeight#</image:height>
						</cfif>
					</image:item>
					</cfoutput>
				<cfelse>
					<!--- image is an asset of the content item --->
					<cfoutput>
					<image:item rdf:about="#attributes.itemImageBaseUrl##thisImage#" />
					</cfoutput>
				</cfif>
			</cfif>
		</cfif>

		<cfoutput>
		</item>
		</cfoutput>
	</cfloop>

<cfoutput>
</rdf:RDF>
</cfoutput>
</cfsavecontent>

<!--- return xml to caller --->
<cfset "caller.#attributes.r_xml#" = trim(xml)>