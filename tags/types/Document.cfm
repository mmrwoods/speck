<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spType
	name="Document"
	description="Document">
		
 	<cf_spProperty
		name="title"
		caption="Title"
		type="Text"
		required="yes"
		maxlength="250"
		displaySize="60"
		finder="yes">
		
 	<cf_spProperty
		name="pubdate"
		caption="Pub.&nbsp;Date"
		type="Date"
		required="yes"
		defaultCurrent="yes"
		richEdit="yes">		
		
 	<cf_spProperty
		name="description"
		caption="Description"
		type="Html"
		required="no"
		displaySize="60,3"
		maxlength="500"
		richEdit="yes"
		fckToolbarSet="Basic"
		safeText="#attributes.context.getConfigString("types","article","content_safe_text","yes")#"
		replaceParagraphs="#attributes.context.getConfigString("types","article","content_force_paragraphs","yes")#">	
		
	<cf_spProperty
		name="document"
		caption="Document"
		type="Asset"
		extensions="#attributes.context.getConfigString("types","document","document_extensions","doc,rtf,pdf,ppt,pps,xls,csv,vnd,zip")#"
		contentDisposition="#attributes.context.getConfigString("types","document","document_content_disposition","inline")#"
		secureKeys="#attributes.context.getConfigString("types","document","document_secure_keys","")#"
		required="yes">
		
	<cf_spProperty
		name="fileSize"
		caption="File Size"
		type="Number"
		required="no"
		displaySize="0">
		
		
	<cf_spHandler method="display">
	
		<!--- we can reference this variable outside this method and display any 
	   		additional messages required (acrobat required message etc.) --->
		<cfparam name="request.lDocumentFileExtensions" default="">	
		
		<!--- target for link to document --->
		<cfparam name="attributes.target" default="">
		
		<cfparam name="attributes.showIcon" type="boolean" default="true">
	
		<cfif len(trim(content.document))>
		
			<!--- Get type info to find out whether property is secure or not --->
			<cfmodule template=#request.speck.getTypeTemplate("Document")# r_stType="stType">		
		
			<cfscript>
				// get filename from asset url
				if ( find("asset.cfm",content.document) ) {
					startSubstr = findNoCase("filename=",content.document) + 9;
					endSubstr = find("&",content.document,startSubstr);
					if ( endSubstr eq 0 )
						endSubstr = len(content.document);
					fileName = mid(content.document,startSubstr,endSubstr-startSubstr);
					//noDispositionUrl = reReplace(content.document,"disposition\=[a-zA-Z]+","");
					//downloadUrl = noDispositionUrl & "disposition=attachment";
				} else {
					fileName = listLast(content.document,"/");
				}	
				
				// get file size in kilobytes and round the value to the nearest integer (content.fileSize is the file size in bytes)
				if ( isNumeric(content.fileSize) ) {
					if ( content.fileSize gte 1024 and content.fileSize lt 1048576 ) {
						// between 1KB and 1MB
						hFileSize = round(content.fileSize/1024) & " KB";
					} else if ( content.fileSize gte 1048576 ) {
						// 1MB or more
						hFileSize = decimalFormat(content.fileSize/1048576) & " MB";
					} else {
						// less than 1KB
						hFileSize = decimalFormat(content.fileSize/1024) & " KB";
					}
					
				}

				if ( listLen(fileName,".") gt 1 ) {
					fileExt = lCase(listLast(fileName,"."));
					if ( not listFind(request.lDocumentFileExtensions,fileExt) )
						request.lDocumentFileExtensions = listAppend(request.lDocumentFileExtensions,fileExt);
				} else {
					fileExt = "";
				}
			</cfscript>
			
			<cfset fs = request.speck.fs>
			
			<cfoutput>
			<div class="document_display">
			<div class="document_display_title<cfif len(fileExt)> #fileExt#</cfif>"><strong></cfoutput>
			
			<cfif attributes.showIcon and len(fileExt)>

				<cfif fileExists("#request.speck.speckInstallRoot##fs#www#fs#properties#fs#asset#fs#icons#fs##fileExt#.png")>
					
					<cfset icon = fileExt>
					
				<cfelse>
					
					<cfset mimeType = request.speck.getMIMEType(fileExt)>
					
					<cfif fileExists("#request.speck.speckInstallRoot##fs#www#fs#properties#fs#asset#fs#icons#fs##listFirst(mimeType,"/")#.png")>
						
						<cfset icon = listFirst(mimeType,"/")>
						
					<cfelse>
					
						<cfset icon = "application">
						
					</cfif>
	
				</cfif>
				
				<cfoutput><a href="#content.document#" target="#attributes.target#"><img class="document_display_icon" title="Download file" alt="<cfif len(icon) lte 4>#uCase(icon)#<cfelse>#request.speck.capitalize(icon)#</cfif> icon" style="float:none;border:none;" src="/speck/properties/asset/icons/#icon#.png" width="16" height="16" border="0" align="absmiddle"></a>&nbsp;</cfoutput>	
				
			</cfif>
			
			<cfoutput><a href="#content.document#" title="Download file" target="#attributes.target#">#content.title#</a></strong>
			<em><!--- <a href="#content.document#">Download File</a> ---> (#fileName#<cfif isDefined("hFileSize")> | #hFileSize#</cfif>)</em></div></cfoutput>
			
			<cfif len(content.description)>
			
				<cfoutput>
				<p class="document_display_description">#content.description#</p>
				</cfoutput>
			
			</cfif>
			
			<cfoutput>
			</div>
			</cfoutput>
			
		</cfif>
	
	</cf_spHandler>
	
	
	<cf_spHandler method="picker">
	
		<cfif len(trim(content.document))>
		
			<!--- Get type info to find out whether property is secure or not --->
			<cfmodule template=#request.speck.getTypeTemplate("Document")# r_stType="stType">		
		
			<cfscript>
				// get filename from asset url
				if ( find("asset.cfm",content.document) ) {
					startSubstr = findNoCase("filename=",content.document) + 9;
					endSubstr = find("&",content.document,startSubstr);
					if ( endSubstr eq 0 )
						endSubstr = len(content.document);
					fileName = mid(content.document,startSubstr,endSubstr-startSubstr);
				} else {
					fileName = listLast(content.document,"/");
				}
				
				if ( listLen(fileName,".") gt 1 ) {
					fileExt = lCase(listLast(fileName,"."));
				} else {
					fileExt = "";
				}
			</cfscript>
			
			<cfset fs = request.speck.fs>
			
			<cfif len(fileExt)>

				<cfif fileExists("#request.speck.speckInstallRoot##fs#www#fs#properties#fs#asset#fs#icons#fs##fileExt#.png")>
					
					<cfset icon = fileExt>
					
				<cfelse>
					
					<cfset mimeType = request.speck.getMIMEType(fileExt)>
					
					<cfif fileExists("#request.speck.speckInstallRoot##fs#www#fs#properties#fs#asset#fs#icons#fs##listFirst(mimeType,"/")#.png")>
						
						<cfset icon = listFirst(mimeType,"/")>
						
					<cfelse>
					
						<cfset icon = "application">
						
					</cfif>
	
				</cfif>
				
				<cfoutput><img style="float:none;border:none;" src="/speck/properties/asset/icons/#icon#.png" width="16" height="16" border="0" align="absmiddle">&nbsp;</cfoutput>	
				
			</cfif>		
			
			<cfoutput>#content.title# (#fileName#)</cfoutput>
			
		<cfelse>
		
			<cfoutput>file not found</cfoutput>
			
		</cfif>
	
	</cf_spHandler>
		
	
	<cf_spHandler method="contentPut">
	
		<!--- get file size --->
		<cfset fs = request.speck.fs>
			
		<!--- assets are uploaded to a temp directory before being copied to either the secureassets or assets directory --->
		<cfdirectory action="LIST" 
			directory="#request.speck.appInstallRoot##fs#tmp" 
			filter="#content.spId#_document*" 
			sort="dateLastModified DESC" 
			name="qTmpFiles">
			
		<!--- there should only be one matching file, and if not, we only want the latest one anyway --->
		<cfif qTmpFiles.recordCount>
		
			<cfset content.fileSize = qTmpFiles.size[1]>
		
		</cfif>
		
	</cf_spHandler>	
	
		
</cf_spType>

