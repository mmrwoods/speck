<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- Validate attributes --->
<cfloop list="r_stImageInfo,file" index="attribute">

	<cfif not isdefined("attributes.#attribute#")>
	
		<cf_spError error="ATTR_REQ" lParams="#attribute#">	<!--- Missing attribute --->
		
	</cfif>

</cfloop>

<cftry>

	<cfobject type="Java" action="create" class="ImageInfo" name="oImageInfo">
	
<cfcatch>

	<cf_spDebug msg="Cannot create ImageInfo object, will try AWT BufferedImage instead.<br>#cfcatch.message#<br>#cfcatch.detail#">

</cfcatch>
</cftry>

<cfscript>
	// populate this struct and return it - an empty struct returned means something went wrong
	stImageInfo = structNew();
	
	//create a file object
	oFile = createObject("java","java.io.File");
	oFile.init(attributes.file);
</cfscript>
	
<cfif not oFile.exists() or not oFile.canRead()>

	<cfthrow message="File '#attributes.file#' does not exist or cannot be read">
	
<cfelse>
		
	<cfif isDefined("oImageInfo") and not isSimpleValue(oImageInfo)>
	
		<!--- get dimensions using ImageInfo class --->
	
		<cfscript>
			// ok, file exists, create file input stream and set the input for the imageInfo object
			oFileInputStream = createObject("java","java.io.FileInputStream");
			oFileInputStream.init(oFile);
			oImageInfo.setInput(oFileInputStream);
		</cfscript>
		
		<cfif not oImageInfo.check()>
		
			<cfthrow message="Image format not supported" detail="ImageInfo.check() failed for file '#attributes.file#'">
			
		<cfelse>
		
			<cfscript>
				// set the width and height
				stImageInfo.width = oImageInfo.getWidth();
				stImageInfo.height = oImageInfo.getHeight();
			</cfscript>
		
		</cfif>
			
		<cfscript>
			// close the input stream
			oFileInputStream.close();
		</cfscript>
		
	<cfelse>
	
		<!--- get dimensions using AWT BufferedImage class --->	
		<cfscript>
			// get Java version
			oSystem = createObject("java", "java.lang.System");
			javaVersion = oSystem.getProperty("java.version");
			
			if ( left(trim(javaVersion),3) gte 1.4 ) {
				oImageIO = createObject("java", "javax.imageio.ImageIO");
				oImage = oImageIO.read(oFile);
			} else { // note: this will barf on UNIX systems without an X server (JRE 1.4 or later is required for "headless" mode)
				oAWTToolkit = createObject("java", "java.awt.Toolkit");
				oToolkit = oAWTToolkit.getDefaultToolkit();
				oImage = oToolkit.getImage("#attributes.file#");
			}
			
			if ( oImage.getWidth() neq -1 and oImage.getHeight() neq -1 ) {
				stImageInfo.width = oImage.getWidth();
				stImageInfo.height = oImage.getHeight();
			}
		</cfscript>
	
	</cfif>

</cfif>

<!--- only return structure if dimensions found --->
<cfif structKeyExists(stImageInfo,"width") and structKeyExists(stImageInfo,"height")>

	<cfset "caller.#attributes.r_stImageInfo#" = stImageInfo>

</cfif>