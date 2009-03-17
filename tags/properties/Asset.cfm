<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfscript>
	// Hash used to break assets up across directories numbered 0-99
	function assetHash(id) {
		return lsParseNumber("0" & REReplace(left(id, 5), "[^0-9]", "", "ALL")) mod 100;
	}
	
	function imageWriteBugWorkaround(image,destination) {
		
		// workaround for bug with imageWrite function in CF 8.01
		
		// Update: a hot fix has been issued to fix the bug, which is also included in the cumulative hot fix
		// Not all our servers have been updated yet, so I'm leaving this function here for the moment
		
		// I only stumbled upon the bug after upgrading to version 8,0,1,196946
		// imageWrite can barf on certain jpegs with the following error...
		// javax.imageio.IIOException: Quantization table 0x02 was not defined at
		// com.sun.imageio.plugins.jpeg.JPEGImageWriter.writeImage(Native Method) at
		// com.sun.imageio.plugins.jpeg.JPEGImageWriter.write(JPEGImageWriter.java:996) at 
		// coldfusion.image.ImageWriter.writeJPeg(ImageWriter.java:60) at
		// coldfusion.image.ImageWriter.writeImage(ImageWriter.java:119) at
		// coldfusion.image.Image.write(Image.java:578) at
		// coldfusion.runtime.CFPage.ImageWrite(CFPage.java:5719)
		// More info at: http://www.adobe.com/cfusion/webforums/forum/messageview.cfm?catid=7&threadid=1358449

		var imageIO = "";
		var bufferedImage = "";
		var imageWriteParam = "";
		var imageWriter = "";
		var iioImage = "";
		var outFile = "";
		var outStream = "";
		var iter = "";
		var extension = lcase(listLast(destination,"."));
		var quality = .75;
		if ( arrayLen(arguments) gt 2 ) {
			quality = arguments[3];
		}
		
		// try to use CF's imageWrite() function, if exception caught, use imageIO
		try {
			imageWrite(image,destination,quality);
		} catch (Any e) {
			bufferedImage = imageGetBufferedImage(image);
			imageIO = createObject("java", "javax.imageio.ImageIO");
			outFile = createObject("java", "java.io.File").init(destination);
			if ( extension eq "jpg" or extension eq "jpeg" ) {
				iter = imageIO.getImageWritersByFormatName("JPG");
				imageWriter = iter.next(); // just use the first writer available
				imageWriteParam = imageWriter.getDefaultWriteParam();
				imageWriteParam.setCompressionMode(imageWriteParam.MODE_EXPLICIT);
				imageWriteParam.setCompressionQuality(javacast("float", quality));
				outStream = createObject("java", "javax.imageio.stream.FileImageOutputStream").init(outFile);
				imageWriter.setOutput(outStream);
				iioImage = createObject("java", "javax.imageio.IIOImage").init(bufferedImage, javacast("null",""), javacast("null",""));
				imageWriter.write(javacast("null",""), iioImage, imageWriteParam);
				outStream.close();
			} else {
				imageIO.write(bufferedImage, extension, outFile);
			}
		}
		
	}
</cfscript>

<cf_spPropertyHandler>


	<cf_spPropertyHandlerMethod method="contentGet">
	
		<!--- 
		The check for the portal framework in this condition is to avoid breaking backwards compatibility 
		with early versions of speck. It may be ok to just break backwards compatibility at this stage 
		though, but I think the sydneyjabiru demo app would need to be updated.
		<cfif value eq 0 or value eq ""> 
		--->
		<cfif value eq 0 or (value eq "" and structKeyExists(request.speck,"portal"))>

			<!--- asset never added or has been flagged as deleted --->
			<cfset newValue = "">
		
		<cfelse>
		
			<cfscript>
				fs = request.speck.fs;
				idHash = assetHash(id);
				bPublicAsset = ( stPD.secureKeys eq "" and ( not request.speck.enableRevisions or (caller.attributes.revision eq "tip" and caller.attributes.level eq "live" and caller.attributes.date eq "") ) );
				
				publicAssetDir = request.speck.appInstallRoot & fs & "www" & fs & "assets" & fs & idHash & fs & id & "_" & stPD.name & fs;
				if ( len(trim(value)) ) {
					// get secure assetDir using value from database (database value stores revision at which asset was put)
					secureAssetDir = request.speck.appInstallRoot & fs & "secureassets" & fs & idHash & fs & id & "_" & trim(value) & "_" & stPD.name & fs;	
				} else {
					// get secure assetDir using id, revision and property name of content
					// this code is here for backwards compatibility with very early version of speck, assets are now revisioned indepenently of content items, value from db is not asset version number
					secureAssetDir = request.speck.appInstallRoot & fs & "secureassets" & fs & idHash & fs & id & "_" & revision & "_" & stPD.name & fs;
				} 
				
				// only show public assets when looking at the live site
				if (bPublicAsset) {
					assetDir = publicAssetDir;
				} else {
					assetDir = secureAssetDir;
				}
			</cfscript>
			
			<cfif len(stPD.secureKeys) and directoryExists(publicAssetDir)>
				
				<!--- 
				This asset shouldn't be public, but a publicly accessible asset seems to exist. 
				Assume that access control has changed, move files from the public to the secure directory and then delete the public directory.
				--->
				<cfdirectory action="list" directory="#publicAssetDir#" sort="type DESC, dateLastModified DESC" name="qPublicDir">
				
				<cfscript>
					// skip over thumbs.db, vssver.scc, and any hidden files
					fileRow = 1;
					while ( listFindNoCase("thumbs.db,vssver.scc",qPublicDir.name[fileRow]) 
								or findNoCase("H",qPublicDir.attributes[fileRow]) ) {
						fileRow = fileRow + 1;
					}
				</cfscript>
				
				<cfif qPublicDir.type[fileRow] eq "File">
				
					<!--- found a file, move it --->
					<cfset fileName = qPublicDir.name[fileRow]>
										
					<!--- Create secure directory if it doesn't exist --->
					<cfset path = listFirst(secureAssetDir, fs) & fs>
					<cfif left(secureAssetDir,1) eq fs>
						<cfset path = fs & path>
					</cfif>
			
					<cfloop list="#listRest(secureAssetDir,fs)#" delimiters="#fs#" index="dir">
					
						<cfset path = path & dir & fs>
		
						<cfif not directoryExists(path)>
						
							<cfdirectory action="create" directory=#path# mode="775">
						
						</cfif> 
					
					</cfloop>
					
					<!--- move publicly accessible file to secure assets directory --->
					<cffile action="move" source="#publicAssetDir##fileName#" destination="#secureAssetDir##fileName#" mode="664">
					
					<!--- delete public directory (gotta delete the files first) --->
					<cfdirectory action="list" directory="#publicAssetDir#" sort="type desc" name="qFilesToDelete">
					
					<cfloop query="qFilesToDelete">
					
						<cfif type eq "file">
						
							<cffile action="delete" file="#publicAssetDir##name#">
						
						</cfif>
					
					</cfloop>
					
					<cfdirectory action="delete" directory="#publicAssetDir#">
			
				</cfif>
				
			<cfelseif stPD.secureKeys eq "" and not directoryExists(publicAssetDir)>
			
				<!--- 
				This asset should be public, but there is no publicly accessible asset.
				Assume that access control has changed, copy files from secure to public directory. 
				Note: Do not move or delete from secure assets, secure assets directory is used for revisioning of assets.
				--->
				<cfdirectory action="list" directory="#secureAssetDir#" sort="type DESC, dateLastModified DESC" name="qSecureDir">
				
				<cfscript>
					// skip over thumbs.db, vssver.scc, and any hidden files
					fileRow = 1;
					while ( listFindNoCase("thumbs.db,vssver.scc",qSecureDir.name[fileRow]) 
								or findNoCase("H",qSecureDir.attributes[fileRow]) ) {
						fileRow = fileRow + 1;
					}
				</cfscript>
				
				<cfif qSecureDir.type[fileRow] eq "File">
				
					<!--- found a file, copy it --->
					<cfset fileName = qSecureDir.name[fileRow]>
										
					<!--- Create public directory if it doesn't exist --->
					<cfset path = listFirst(publicAssetDir, fs) & fs>
					<cfif left(publicAssetDir,1) eq fs>
						<cfset path = fs & path>
					</cfif>
			
					<cfloop list="#listRest(publicAssetDir,fs)#" delimiters="#fs#" index="dir">
					
						<cfset path = path & dir & fs>
		
						<cfif not directoryExists(path)>
						
							<cfdirectory action="create" directory=#path# mode="775">
						
						</cfif> 
					
					</cfloop>
					
					<!--- copy secure asset into public directory --->
					<cffile action="copy" source="#secureAssetDir##fileName#" destination="#publicAssetDir##fileName#" mode="664">
					
				</cfif>
			
			</cfif>
			
			<!--- get the link to this asset --->
			<cfif directoryExists(assetDir)>
	
				<cfdirectory action="list" directory="#assetDir#" sort="type DESC, dateLastModified DESC" name="qAssetDir">
				
				<cfscript>
					// skip over thumbs.db, vssver.scc, and any hidden files
					fileRow = 1;
					while ( listFindNoCase("thumbs.db,vssver.scc",qAssetDir.name[fileRow]) 
								or findNoCase("H",qAssetDir.attributes[fileRow]) ) {
						fileRow = fileRow + 1;
					}
					
					if (qAssetDir.type[fileRow] eq "File") {
					
						fileName = qAssetDir.name[fileRow];
	
						if ( bPublicAsset and stPD.displayMimeType eq "" and stPD.contentDisposition neq "attachment" ) {
							
							newValue = request.speck.appWebRoot & "/assets/" & idHash & "/" & id & "_" & stPD.name & "/" & fileName;
							
						} else {
							
							// Assets script must handle file
							// get mime type
							if ( len(trim(stPD.displayMimeType)) )
								// force mime type
								mimeType = trim(stPD.displayMimeType);						
							else if ( REFind("\.[A-Za-z]+$", fileName) )
								// get mime type from mappings
								mimeType = request.speck.getMIMEType(listLast(fileName,"."));
							else
								// default mime type
								mimeType = "application/octet-stream";
							
							newValue = 	"/speck/properties/asset/asset.cfm?type=" & type &
										"&amp;id=" & id &
										"&amp;property=" & stPD.name &
										"&amp;filename=" & fileName &
										"&amp;revision=" & caller.attributes.revision &
										"&amp;mimetype=" & URLEncodedFormat(mimeType) &
										"&amp;app=" & request.speck.appName & 
										"&amp;disposition=" & stPD.contentDisposition;
						}
						
					} else {
						
						newValue = "";	// No file, this shouldn't happen normally but we handle it gracefully	
								
					}
				</cfscript>

			<cfelse>
			
				<cfset newValue = "">
			
			</cfif>
			
		</cfif>
	
	</cf_spPropertyHandlerMethod>
	

	<!--- only call other methods if we have to - a nifty little performance hack from Robin --->
	<cfif attributes.method neq "contentGet">
	
		
		<cf_spPropertyHandlerMethod method="validateAttributes">
			
			<cfparam name="stPD.accept" default="*/*">
			<cfparam name="stPD.secureKeys" default="">
			<cfparam name="stPD.displayMimeType" default="">
			
			<!--- allow default content disposition to be overridden --->
			<cfparam name="stPD.contentDisposition" default="inline">
			
			<!--- a list of allowed file extensions for uploads, can be used instead of or as a complement to accept attribute --->
			<cfparam name="stPD.extensions" default="">
			
			<cfif not len(stPD.contentDisposition)>	
				
				<cfset stPD.contentDisposition = "inline">
				
			<cfelseif not listFindNoCase("inline,attachment",stPD.contentDisposition)>
			
				<!--- content disposition must be either "inline" or "attachment", we've no implementation for "hidden" --->
				<cf_spError error="ATTR_INV" lParams="#stPD.contentDisposition#,contentDisposition" context=#caller.ca.context#>
				
			</cfif>
			
			<!--- optional attributes for image re-sizing --->
			<!--- TODO: add preserveAspect attribute and update image manipulation code --->
			<cfparam name="stPD.width" default="">
			<cfparam name="stPD.height" default="">
			<cfparam name="stPD.maxWidth" default="">
			<cfparam name="stPD.maxHeight" default="">
			<cfparam name="stPD.cropToExact" default="no" type="boolean">
			<cfparam name="stPD.preserveAspect" default="yes" type="boolean">
			<cfparam name="stPD.jpegCompression" default="90">
			
			<!--- 
			Source attribute allows the asset file to be obtained from another property when doing a contentPut.
			The source file must be found in the tmp directory for the application. The source property definition 
			must come before this property defintion in order for that to be possible.
			--->
			<cfparam name="stPD.source" default="">
			
			<!--- asset field in database stores the revision at which this asset was put --->
			<cfset stPD.databaseColumnType = "integer">
			
			<!--- 
			note: When validating values, Speck checks that the length of new values do not exceed their
			maxLength. This has little effect on most file uploads as the form field and new value
			will be the path to a tmp file created by CF - we just need to allow ample maxLength for the 
			path to the tmp file. However, text files (plain and rich text) are posted as text, not binary, 
			so the form field and new value to be validated will be the actual text to be saved as a file.
			To allow for uploading of text files, I've set the maxLength for Asset properties to 3MB.
			TODO: allow developers to set the maxLength and check that size of uploaded file does not exceed it.
			--->
			<cfset stPD.maxLength = 3145728>
			
						
		</cf_spPropertyHandlerMethod>
		
	
		<cf_spPropertyHandlerMethod method="renderFormField">
			
			<!--- this can be removed once apps have been refreshed --->
			<cfparam name="request.speck.strings.P_ASSET_INVALID_EXTENSION_JS" default="Error: invalid file type for field '%1'.\n\nFile extension '%2' not in the list of allowed extensions '%3'.">
			
			<cfoutput>
			<script type="text/javascript">
				// this is pretty horrible, but the message needs to be clear for users
				// todo: make sure this always gets called, even if a user pastes a path into the form field
				function check_extension_#stPD.name#() {
					<cfif len(stPD.extensions)>
						var field = document.speditform.#stPD.name#;
						var errorStr = "#request.speck.buildString("P_ASSET_INVALID_EXTENSION_JS","#replace(jsStringFormat(stPD.caption),"&nbsp;"," ","all")#")#";
						if ( field.value.replace(/\s+/, '') != '' && !/(\.#listChangeDelims(stPD.extensions,"|\.")#)$/i.test(field.value) ) {
							// insert file extension into error string
							errorStr = errorStr.replace(/\%2/,field.value.substr(field.value.lastIndexOf('.')+1));
							// insert list of allowed extensions into error string (it's easier to do this here rather than when calling Speck's buildString function - buildString assumes the second argument is a comma-delimited list of params, it can't handle params with commas)
							errorStr = errorStr.replace(/\%3/,"#stPD.extensions#");
							alert(errorStr);
							return false;
						}
					</cfif>
					return true;
					
				}
				function copy_client_file_path_#stPD.Name#() {
					document.speditform.#stPD.Name#_client_file_path.value = document.speditform.#stPD.Name#.value;
				}
			</script>
			<input type="File" name="#stPD.Name#" size="#stPD.displaySize#" title="Browse for new #lCase(stPD.caption)# file" class="button" onchange="copy_client_file_path_#stPD.Name#();check_extension_#stPD.name#();" />
			<input type="hidden" name="#stPD.Name#_client_file_path" value="" size="70">
			</cfoutput>
			
			<cfif not isDefined("request.spDeleteAssetsElementExists")>
			
				<cfset request.spDeleteAssetsElementExists = "yes">
				<cfoutput><input type="hidden" name="spDeleteAssets" value="" /></cfoutput>
			
			</cfif>
			
			<cfif len(value)>
				
				<!--- get file name --->
				<cfset fileName = "">
				<cftry>
					<cfscript>
						if ( find("asset.cfm",value) ) {
							startFileName = find("filename=",value) + 9;
							endFileName = find("&",value,startFileName); 
							fileName = mid(value,startFileName,endFileName - startFileName);
						} else {
							fileName = listLast(value,"/");
						}
					</cfscript>
				<cfcatch><!--- do nothing ---></cfcatch>
				</cftry>

				<cfif not stPD.required>

					<cfoutput>
					<script>
						function delete_#lCase(stPD.name)#() {
							if (window.confirm("Delete file #fileName#?\n\nAll changes to the form will be saved.")) {
								if ( document.speditform.spDeleteAssets.value == "" ) {
									document.speditform.spDeleteAssets.value = "#stPD.name#";
								} else {
									document.speditform.spDeleteAssets.value = document.speditform.spDeleteAssets.value + "," + "#stPD.name#";
								}
								if ( document.speditform.onsubmit ) {
									document.speditform.onsubmit();
								}
								document.speditform.submit();
							}
						}
					</script>
					<input type="button" class="button" value="Delete" title="Delete #lCase(stPD.caption)# file #fileName#" onclick="delete_#lCase(stPD.name)#();" />
					</cfoutput>
				
				</cfif>
				
				<cfset fileExt = listLast(fileName,".")>
				
				<cfoutput><div style="margin:3px;" class="alternateRow">
				<!---<table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td>--->
				</cfoutput>
				
				<cfif listFindNoCase("png,gif,jpg,jpeg",fileExt)>
				
					<cfoutput><img id="#stPD.Name#image" src="#value#" /></cfoutput>
				
				<cfelse>
				
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
						
						<cfoutput><a href="#value#" target="_blank"><img style="float:none;border:none;" src="/speck/properties/asset/icons/#icon#.png" width="16" height="16" border="0" align="absmiddle"></a>&nbsp;</cfoutput>	
						
					</cfif>
					
					<cfoutput><a href="#value#" target="_blank">#fileName#</a></cfoutput>
					
				</cfif>

				<!---
				<cfoutput>
				</td><td align="right"><input type="button" class="button" value="Delete"></td></tr></table>
				</cfoutput>
				--->
				
				<cfoutput></div></cfoutput>
				
			</cfif>
			
		</cf_spPropertyHandlerMethod>
		
		
		<cf_spPropertyHandlerMethod method="readFormField">
		
			<cfset fs = request.speck.fs>
			
			<!--- delete any existing tmp files for this asset --->
			<cfdirectory action="list" directory="#request.speck.appInstallRoot##fs#tmp" sort="type DESC" name="qTmpDir">
			
			<cfquery name="qFilesToDelete" dbtype="query">
				SELECT name
				FROM qTmpDir
				WHERE name LIKE '#id#\_#stPD.name#\_%'
				ESCAPE '\'
			</cfquery>
			
			<cfloop query="qFilesToDelete">
				
				<cffile action="delete" file="#request.speck.appInstallRoot##fs#tmp#fs##name#">
				
			</cfloop>
			
			<!--- ok, any tmp files for this asset have been deleted - upload the new tmp file --->	
			
			<!--- only set to true if we save a file --->
			<cfset fileWasSaved = false> 
			
			<!--- only attempt file upload if formfield contains some value --->
			<cfset doUpload = yesNoFormat(len(trim(evaluate("form.#stPD.name#"))))>
			
			<cfif doUpload>
				
				<!--- if client is Mac IE, check that we have a file length gt 2 (Mac IE may append CRLF to form fields, 
					resulting in an uploaded file length 2 even when user has not chosen a file to upload) --->
				<cfif findNoCase("Mac",cgi.http_user_agent) and findNoCase("MSIE",cgi.http_user_agent)>
				
					<cftry>
				
						<cffile action="readbinary" file="#stPD.name#" variable="tmpFile">
						
						<cfif len(tmpFile) lte 2>
							
							<cfset doUpload = false>
							
							<!--- attempt to delete tmp file --->
							<cftry>
								<cffile action="delete" file="#stPD.name#">
							<cfcatch><!--- do nothing ---></cfcatch>
							</cftry>
						
						</cfif>
						
					<cfcatch>
						
						<cfset doUpload = false>
						
					</cfcatch>
					</cftry>
				
				</cfif>
			
				<cfif doUpload>
			
					<cftry>
			
						<cffile action="upload"
							filefield="#stPD.name#"
							destination="#request.speck.appInstallRoot##fs#tmp#fs#"
							nameconflict="makeunique"
							accept="#stPD.accept#"
							mode="664">
					
					<cfcatch type="application">
					
						<cfif isDefined("cfcatch.mimeType")>
						
							<!--- invalid MIME type exception --->
							<cf_spError error="P_ASSET_INVALID_TYPE" lParams="#stPD.caption#,#cfcatch.mimeType#,#replace(stPD.accept,",",";","all")#">
						
						<cfelse>
						
							<cfrethrow>
						
						</cfif>
						
					</cfcatch>
					</cftry>
					
					<cfif cffile.fileWasSaved>
					
						<!--- clean up file name to avoid any pitfalls with disallowed characters - be brutal --->
						<cfset tmpFileName = replace(cffile.clientFile,"&","and","all")>
						<cfset tmpFileName = reReplace(tmpFileName,"[^A-Za-z0-9\-\.]", "_", "all")> 
						
						<!--- generate file name in format recognised by contentPut handler: id_propertyName_*.* --->
						<cfset tmpFileName = id & "_" & stPD.name & "_" & tmpFileName>
						
						<!--- move uploaded file to tmp directory --->
						<cffile action="move" 
							source="#request.speck.appInstallRoot##fs#tmp#fs##cffile.serverFile#" 
							destination="#request.speck.appInstallRoot##fs#tmp#fs##tmpFileName#"
							mode="664">
						
						<cfset fileWasSaved = true>
					
					</cfif>

				</cfif>
				
			<cfelseif isDefined("form.#stPD.name#_client_file_path") and reFindNoCase("^http(s)?://",form['#stPD.name#_client_file_path'])>
				
				<cfset clientFilePath = form['#stPD.name#_client_file_path']>
				<cfset clientFile = listLast(clientFilePath,"/\")>
				
				<!--- clean up file name to avoid any pitfalls with disallowed characters - be brutal --->
				<cfset tmpFileName = replace(clientFile,"&","and","all")>
				<cfset tmpFileName = reReplace(tmpFileName,"[^A-Za-z0-9\-\.]", "_", "all")> 
						
				<!--- generate file name in format recognised by contentPut handler: id_propertyName_*.* --->
				<cfset tmpFileName = id & "_" & stPD.name & "_" & tmpFileName>
				
				<cfhttp url="#clientFilePath#" 
					method="get"
					file="#tmpFileName#" 	
					path="#request.speck.appInstallRoot##fs#tmp#fs#" 
					timeout="10">
					
				<cfif val(cfhttp.statusCode) eq 200 and fileExists("#request.speck.appInstallRoot##fs#tmp#fs##tmpFileName#")>
				
					<cfset fileWasSaved = true>
					<cfset "form.#stPD.name#" = clientFilePath>
				
				</cfif>
			
			<cfelseif len(stPD.source)>
				
				<!--- get file from source property if exists --->
				<cfquery name="qSourceFile" dbtype="query">
					SELECT name
					FROM qTmpDir
					WHERE name LIKE '#id#\_#stPD.source#\_%'
					ESCAPE '\'
				</cfquery>
				
				<cfif qSourceFile.recordCount>
				
					<cfset tmpFileName = replace(qSourceFile.name,"#id#_#stPD.source#","#id#_#stPD.name#")>
				
					<!--- copy the source file --->
					<cffile action="copy" 
						source="#request.speck.appInstallRoot##fs#tmp#fs##qSourceFile.name#" 
						destination="#request.speck.appInstallRoot##fs#tmp#fs##tmpFileName#"
						mode="664">
						
					<cfset fileWasSaved = true>
				
				</cfif>
				
			</cfif>
			
			<cfif fileWasSaved>
			
				<cfif listFind("png,jpg,gif,jpeg",lcase(listLast(tmpFileName,"."))) and listFirst(request.speck.cfVersion) neq 5>
				
					<cfset tmpFilePath = "#request.speck.appInstallRoot##fs#tmp#fs##tmpFileName#">
					
					<cfscript>
						function getResizeDimensions(stPD,width,height){
							// compares existing dimensions with property definition 
							// attributes to determine if an image should be resized
							// returns resize dimensions as width,height list
							var newWidth = 0;
							var newHeight = 0;
							if ( isNumeric(stPD.width) and isNumeric(stPD.height) ) {
								newWidth = stPD.width;
								newHeight = stPD.height;
							} else {
								if (isNumeric(stPD.width)) {
									newWidth = stPD.width;
								} else if (isNumeric(stPD.maxWidth) and width gt stPD.maxWidth) {
									newWidth = stPD.maxWidth;
								}
								if (isNumeric(stPD.height)) {
									newHeight = stPD.height;
								} else if (isNumeric(stPD.maxHeight) and height gt stPD.maxHeight) {
									newHeight = stPD.maxHeight;
								}
							}
							return newWidth & "," & newHeight;
						}
					</cfscript>
					
					<!--- check the current dimensions and then see if we need to resize --->
					<cf_spImageInfo file="#tmpFilePath#" r_stImageInfo="stImageInfo">
					
					<cfset resizeDimensions = getResizeDimensions(stPD,stImageInfo.width,stImageInfo.height)>
					<cfset newWidth = listFirst(resizeDimensions)>
					<cfset newHeight = listLast(resizeDimensions)>
					
					<cfif newWidth gt 0 or newHeight gt 0>

						<cfscript>
							// resize image - always save as jpeg
							newFilePath = reReplace(tmpFilePath,"\.([a-zA-Z]+)$",".jpg");
							
							if ( listFirst(request.speck.cfVersion) gte 8 ) { 
								
								// use cfimage
								image = imageRead(tmpFilePath);
								if ( newWidth gt 0 and newHeight gt 0 ) {
									if ( stPD.cropToExact ) {
										// crop image, maintaining aspect ratio
										// first resize the image to fit either width or height and then crop the other way around
										// code mostly taken from aspectCrop method of ImageUtils CFC
										wPercent = newWidth / image.width;
										hPercent = newHeight / image.height;
										if (wPercent gt hPercent) {
											// resize to fit in new width, maintaining aspect ratio
											px = image.width * wPercent + 1;
											imageResize(image,px,"");
											// crop to fit in new height
											imageCrop(image,0,(image.height - newHeight)/2,newWidth,newHeight);
										} else {
											// resize to fit in new height, maintaining aspect ratio
											px = image.height * hPercent + 1;
											imageResize(image,"",px);
											// crop to fit in new width
											imageCrop(image,(image.width - newWidth)/2,0,newWidth,newHeight);
										}
									} else if ( stPD.preserveAspect ) {
										imageScaleToFit(image,newWidth,newHeight);
									} else {
										imageResize(image,newWidth,newHeight);
									}
								} else {
									if ( newWidth eq 0 ) { newWidth = ""; }
									if ( newHeight eq 0 ) { newHeight = ""; }
									imageScaleToFit(image,newWidth,newHeight);
								}
								imageWriteBugWorkaround(image,newFilePath,stPD.jpegCompression/100);
								
							} else {
								
								// use ImageCFC
								image = createObject("component","spImage");
								image.setOption("defaultJpegCompression",stPD.jpegCompression);
								image.init(tmpFilePath);
								if ( newWidth gt 0 and newHeight gt 0 ) {
									image.resize(newWidth,newHeight,stPD.preserveAspect,stPD.cropToExact);	
								} else {
									image.resize(newWidth,newHeight);
								}
								image.save(newFilePath);
								
							}
						</cfscript>
						
						<!--- if new file path isn't the same as the original, delete the original file --->
						<cfif compare(tmpFilePath,newFilePath) neq 0>
						
							<cftry>
							
								<cffile action="delete" file="#tmpFilePath#">
								
							<cfcatch>
								<!--- do nothing, TODO: log info --->
							</cfcatch>
							</cftry>
						
						</cfif>
	
					</cfif>
					
				</cfif>
				
			<cfelseif doUpload>
			
				<cfif isDefined("cffile.clientFile")>
					<cfset fileName = cffile.clientFile>
				<cfelse>
					<cfset fileName = "unknown">
				</cfif>
			
				<cf_spError error="P_ASSET_NOT_SAVED" lParams="#stPD.caption#,#fileName#">
				
			</cfif>

		</cf_spPropertyHandlerMethod>	
		
		
		<cf_spPropertyHandlerMethod method="validateValue">
		
			<!--- do we need to check that the file extension is allowed --->
			<cfif isDefined("stPD.extensions") and len(stPD.extensions)>
			
				<cfset fs = request.speck.fs>
				
				<!--- get tmp file --->
				<cfdirectory action="LIST" 
					directory="#request.speck.appInstallRoot##fs#tmp" 
					filter="#id#_#stPD.name#_*" 
					sort="type DESC" 
					name="qTmpFiles">
					
				<cfif qTmpFiles.recordCount>
			
					<!--- check that file has an allowed extension --->
					<cfif not find(".",qTmpFiles.name)>
					
						<!--- hmm, what do we do when there's no extension? I suppose we barf --->
						<cfset lErrors = request.speck.buildString("P_ASSET_NO_EXTENSION","#stPD.caption#,#listRest(listRest(qTmpFiles.name,"_"),"_")#,#replace(stPD.extensions,",",";","all")#")>
						
					<cfelseif not listFindNoCase(stPD.extensions,listLast(qTmpFiles.name,"."))>
						
						<!--- file extension not in allowed list --->
						<cfset lErrors = request.speck.buildString("P_ASSET_INVALID_EXTENSION","#stPD.caption#,#listRest(listRest(qTmpFiles.name,"_"),"_")#,#listLast(qTmpFiles.name,".")#,#replace(stPD.extensions,",",";","all")#")>
	
					</cfif>
				
				</cfif>
			
			</cfif>
		
		</cf_spPropertyHandlerMethod>
		
		
		<cf_spPropertyHandlerMethod method="contentPut">
		
			<cfmodule template=#request.speck.getTypeTemplate(attributes.type)# r_stType="stType">
			
			<cfset bRevision = request.speck.enableRevisions and stType.revisioned>
	
			<!--- look for files matching id_propertyName_*.* in the application tmp directory --->
			<cfset fs = request.speck.fs>
			
			<cfdirectory action="list" directory="#request.speck.appInstallRoot##fs#tmp" sort="type DESC, dateLastModified DESC" name="qTmpDir">
			
			<cfquery name="qFileToPut" dbtype="query">
				SELECT name, dateLastModified
				FROM qTmpDir
				WHERE name LIKE '#id#\_#stPD.name#\_%'
				ESCAPE '\'
			</cfquery>
			
			<cfif qFileToPut.recordCount gt 0 and dateDiff("n",qFileToPut.dateLastModified,now()) eq 0>
			
				<cf_spDebug msg="found a file to put">
			
				<!--- Found a file to "put" --->
				<cfscript>
				
					tmpFileName = qFileToPut.name[1];	// Name of file we found in tmp directory
					assetFileName = listRest(listRest(tmpFileName, "_"), "_");	// Remove "id_propertyname_" prefix for asset dir filename
					idHash = assetHash(id);
					if ( len(stPD.secureKeys) or bRevision ) { // if revisioning is on, always save a copy of the asset in the secureassets directory, the currently live version will go into the public assets directory if the asset is not secure
						// move uploaded file to private secureassets directory and wait for promotion
						assetDir = request.speck.appInstallRoot & fs & "secureassets" & fs & idHash & fs & id & "_" & revision & "_" & stPD.name & fs;
					} else {		
						// move uploaded file to public assets directory
						assetDir = request.speck.appInstallRoot & fs & "www" & fs & "assets" & fs & idHash & fs & id & "_" & stPD.name & fs;
					}
					
				</cfscript>
				
				<cf_spDebug msg="asset directory for file: #assetDir#">
				
				<!--- Create assetDir if it doesn't exist --->
				<cfset path = listFirst(assetDir, fs) & fs> <!--- base path from which to start checking that directories in the path to the assetDir exist --->
				<cfif left(assetDir,1) eq fs>
					<!--- if assetDir starts with the filesystem separator, prefix the path with it too --->
					<cfset path = fs & path>
				</cfif>
				
				<cfloop list="#listRest(assetDir,fs)#" delimiters="#fs#" index="dir">
				
					<cfset path = path & dir & fs>
	
					<cfif not directoryExists(path)>
					
						<cfdirectory action="create" directory=#path# mode="775">
					
					</cfif> 
				
				</cfloop>
	
				
				<!--- Delete existing file if any --->
				<cfdirectory action="list" directory="#assetDir#" sort="type DESC" name="qFilesToDelete">
				<cfloop query="qFilesToDelete">
				
					<cfif type eq "file">
						
						<cftry>
						
							<cffile action="delete" file="#assetDir##name#">
							
						<cfcatch>
							<!--- do nothing, if this fails, the attempt to move the file later should also fail 
							but a move error makes more sense when putting content than a delete error --->
						</cfcatch>
						</cftry>
					
					</cfif>
				
				</cfloop>
				
				<cf_spDebug msg="move file from #request.speck.appInstallRoot##fs#tmp#fs##tmpFileName# to #assetDir##assetFileName#">
				
				<cftry>
				
					<!--- Move action is failing most of the time with CFMX, cffile error "The value of the attribute source, 
					which is currently 'blah', is invalid." even though the source file and destination path do exist. I'm assuming 
					this is something to do with the way CFMX handles file operations within modules (this property is called with 
					readFormField and then contentPut in order to upload a file from admin forms), readFormField doesn't seem to be 
					releasing the file for writing in time for contentPut to move it. I tried using named locks around the cffile 
					actions, all using the same name, but that didn't help either so try moving. If fails, try copy, then delete --->
				
					<cffile action="move" source="#request.speck.appInstallRoot##fs#tmp#fs##tmpFileName#" destination="#assetDir##assetFileName#" mode="664">
				
				<cfcatch>
				
					<cf_spDebug msg="could not move file...<br> #cfcatch.message# #cfcatch.detail#">
					
					<cf_spDebug msg="copy file from #request.speck.appInstallRoot##fs#tmp#fs##tmpFileName# to #assetDir##assetFileName#">
				
					<cffile action="copy" source="#request.speck.appInstallRoot##fs#tmp#fs##tmpFileName#" destination="#assetDir##assetFileName#" mode="664">
					
					<!--- attempt to delete source file in application's tmp directory --->
					<cftry>
					
						<cffile action="delete" file="#request.speck.appInstallRoot##fs#tmp#fs##tmpFileName#">
					
					<cfcatch>
						<!--- do nothing, TODO log warning! --->
					</cfcatch>
					</cftry>
	
											
				</cfcatch>
				</cftry>
				
				<!--- save new revision number as newValue --->
				<cfset newValue = revision>
				
			<cfelse>
			
				<cf_spDebug msg="no files to put">
			
				<!--- no file to put --->
				<cfparam name="form.spDeleteAssets" default="">
				<cfparam name="stPD.source" default="">
				<cfparam name="attributes.newRevision" default="yes">
				
				<cfif listFindNoCase(form.spDeleteAssets,stPD.name)>
				
					<cfset propName = stPD.name>
					
					<cf_spDebug msg="'#propName#' found in list of assets to remove '#form.spDeleteAssets#'">
				
					<!--- delete public asset if we are looking at the live version of the site --->
					<cfif request.speck.session.viewLevel eq "live" and request.speck.session.viewDate eq "">
					
						<cfset assetDir = request.speck.appInstallRoot & fs & "www" & fs & "assets" & fs & assetHash(id) & fs & id & "_" & propName & fs>
						
						<!--- delete files and directory --->
						<cfdirectory action="list" directory="#assetDir#" sort="type DESC" name="qFilesToDelete">
						<cfloop query="qFilesToDelete">
						
							<cfif type eq "file">
							
								<cffile action="delete" file="#assetDir##name#">
							
							</cfif>
						
						</cfloop>
						
						<cfset newValue = 0>
						
						<!--- attempt to delete directory --->
						<cftry>
							<cfdirectory action="delete" directory="#assetDir#">
						<cfcatch><!--- do nothing ---></cfcatch>
						</cftry>
						
					<cfelseif not attributes.newRevision>
					
						<cf_spDebug msg="not a new revision for this content item, therefore we can delete the asset from secureassets directory">
					
						<!--- this is a not a new revision, i.e. we're in edit mode with promotion enabled
							if the asset was originally put by this revision, we can delete it from secureassets --->
						<cfset assetDir = request.speck.appInstallRoot & fs & "secureassets" & fs & assetHash(id) & fs & id & "_" & revision & "_" & propName & fs>
		
						<cfif directoryExists(assetDir)>
						
							<!--- the directory will only exist if the asset was put at this revision --->
						
							<!--- delete files and directory --->
							<cfdirectory action="list" directory="#assetDir#" sort="type DESC" name="qFilesToDelete">
							<cfloop query="qFilesToDelete">
							
								<cfif type eq "file">
								
									<cffile action="delete" file="#assetDir##name#">
								
								</cfif>
							
							</cfloop>
		
							<cfset newValue = 0>
							
							<!--- attempt to delete directory --->
							<cftry>
								<cfdirectory action="delete" directory="#assetDir#">
							<cfcatch><!--- do nothing ---></cfcatch>
							</cftry>
							
						</cfif>
					
					</cfif>
					
				<cfelse>
				
					<!---
					If we're not putting a file, we need to get the keep the existing value...
					If revisioning is enabled and this is a new revision and a previous revision exists, 
					then we use the value from the previous revision as the new value
					Otherwise, we use the value from the current revision as the new value
					--->
				
					<cfif bRevision and revision gt 1 and attributes.newRevision>
					
						<cfquery name="qPreviousAssetValue" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
						
							SELECT #stPD.name# AS assetValue 
							FROM #type#
							WHERE spId = '#id#'
								AND spRevision = (
									SELECT MAX(revision) 
									FROM spHistory
									WHERE id = '#id#'
										AND ts = (
											SELECT DISTINCT MAX(ts)
											FROM spHistory
											WHERE id = '#id#'
												AND revision <> #revision#
												AND promolevel > 1
										)
								)
						
						</cfquery>
						
						<cfset newValue = qPreviousAssetValue.assetValue>
							
					<cfelse>
					
						<cfquery name="qCurrentAssetValue" datasource=#request.speck.codb# username=#request.speck.database.username# password=#request.speck.database.password#>
						
							SELECT #stPD.name# AS assetValue 
							FROM #type#
							WHERE spId = '#id#'
								AND spRevision = #revision#
						
						</cfquery>
						
						<cfset newValue = qCurrentAssetValue.assetValue>				
						
					</cfif>
					
				</cfif>
				
			</cfif>
	
		</cf_spPropertyHandlerMethod>
		
		
		<cf_spPropertyHandlerMethod method="promote">
			
			<!--- This action was created especially for us - if property not secure copy asset file from secureassets to assets --->
			<cfset fs = request.speck.fs>
			
			<cfscript>
				idHash = assetHash(id);
				secureAssetDir = request.speck.appInstallRoot & fs & "secureassets" & fs & idHash & fs & id & "_" & revision & "_" & stPD.name & fs;
				assetDir = request.speck.appInstallRoot & fs & "www" & fs & "assets" & fs & idHash & fs & id & "_" & stPD.name & fs;
			</cfscript>
			
			<cfdirectory action="list" directory="#secureAssetDir#" sort="type DESC" name="qAssetDir">
				
			<cfif qAssetDir.type[1] eq "File">
					
				<cfset fileName = qAssetDir.name[1]>
				
			<cfelse>
				
				<cfset fileName = "">
				
			</cfif>
			
			<cfif fileName neq "" and newLevel eq "live" and stPD.secureKeys eq "" and revision neq 0>
			
				<cfif directoryExists(assetDir)>
				
					<!--- delete existing files in the public assets directory - public assets directory should only contain the live version of the asset --->
					<cfdirectory action="list" directory="#assetDir#" sort="type desc" name="qFilesToDelete">
					
					<cfloop query="qFilesToDelete">
					
						<cfif type eq "file" and name neq fileName>
						
							<cffile action="delete" file="#assetDir##name#">
						
						</cfif>
					
					</cfloop>
					
				<cfelse>
				
					<!--- Create assetDir if it doesn't exist --->
					<cfset path = listFirst(assetDir, fs) & fs> <!--- base path from which to start checking that directories in the path to the assetDir exist --->
					<cfif left(assetDir,1) eq fs>
						<!--- if assetDir starts with the filesystem separator, prefix the path with it too --->
						<cfset path = fs & path>
					</cfif>
					
					<cfloop list="#listRest(assetDir,fs)#" delimiters="#fs#" index="dir">
					
						<cfset path = path & dir & fs>
						
						<cfif not directoryExists(path)>
						
							<cfdirectory action="create" directory="#path#" mode="775">
						
						</cfif> 
					
					</cfloop>
					
				</cfif>
				
				<cffile action="copy" source="#secureAssetDir##fileName#" destination="#assetDir##fileName#" mode="664">
				
			<cfelseif filename neq "" and revision eq 0>
			
				<!--- Should delete the copy in the asset directory --->
				<cffile action="delete" file="#assetDir##fileName#">
			
			</cfif>
		
		</cf_spPropertyHandlerMethod>
		
		
		<cf_spPropertyHandlerMethod method="delete">
		
			<!--- delete any assets (public and secure) - note: this only applies when revisioning is not enabled --->
			<cfset fs = request.speck.fs>
			
			<cfscript>
				idHash = assetHash(id);
				// note: we need to delete all revisions of secure assets (revisioning may have been enabled in the past)
				secureAssetPath = request.speck.appInstallRoot & fs & "secureassets" & fs & idHash & fs;
				// there is only one public asset directory for each property
				assetDir = request.speck.appInstallRoot & fs & "www" & fs & "assets" & fs & idHash & fs & id & "_" & stPD.name & fs;
			</cfscript>
				
			<!--- delete public asset file and directory --->
			<cfdirectory action="list" directory="#assetDir#" sort="type desc" name="qFilesToDelete">
			
			<cfloop query="qFilesToDelete">
			
				<cfif type eq "file">
				
					<cffile action="delete" file="#assetDir##name#">
				
				</cfif>
			
			</cfloop>
	
			<!--- attempt to delete asset directory --->
			<cftry>
				<cfdirectory action="delete" directory="#assetDir#">
			<cfcatch><!--- do nothing ---></cfcatch>
			</cftry>
			
			<!--- 
			Get secure directories containing assets for this content item. In most cases, this code won't 
			do anything because this method only gets called when revisioning is disabled and secure 
			assets aren't created when revisioning is disabled. It's possible that revisioning was 
			previously enabled for this application or content type though, so we'll try and delete any 
			old secure assets while we're at it.
			--->
			<cfdirectory directory="#secureAssetPath#" filter="#id#*#stPD.name#*" name="qSecureAssetDirs">
		
			<cfloop query="qSecureAssetDirs">
			
				<cfset secureAssetDir = secureAssetPath & name & fs>
			
				<!--- delete files and directory --->
				<cfdirectory action="list" directory="#secureAssetDir#" sort="type desc" name="qFilesToDelete">
				<cfloop query="qFilesToDelete">
				
					<cfif type eq "file">
					
						<cffile action="delete" file="#secureAssetDir##name#">
					
					</cfif>
				
				</cfloop>
				
				<!--- attempt to delete asset directory --->
				<cftry>
					<cfdirectory action="delete" directory="#secureAssetDir#">
				<cfcatch><!--- do nothing ---></cfcatch>
				</cftry>
			
			</cfloop>
		
		</cf_spPropertyHandlerMethod>
		
	
	</cfif> <!--- attributes.method neq "contentGet" --->
	

</cf_spPropertyHandler>