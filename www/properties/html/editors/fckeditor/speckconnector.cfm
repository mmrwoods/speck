<cfsetting enablecfoutputonly="yes" showdebugoutput="no">

<cfparam name="url.command" default="">
<cfparam name="url.type" default="">
<cfparam name="url.currentFolder" default="">

<!--- optional attributes for image re-sizing --->
<cfparam name="url.width" default="">
<cfparam name="url.height" default="">
<cfparam name="url.maxWidth" default="">
<cfparam name="url.maxHeight" default="">
<cfparam name="url.cropToExact" default="yes" type="boolean">
<cfparam name="url.jpegCompression" default="90">

<cfscript>
	// TODO: allow default configuration to be overridden
	stConfig = structNew();
	stConfig.userFilesPath = "/assets/FCKeditor/";
	
	stConfig.allowedExtensions = structNew(); // note: unlike other FCKeditor connectors, there is no denied extensions list - file extension must be explicitly allowed
	
	stConfig.allowedExtensions["File"] = "doc,rtf,pdf,ppt,pps,xls,csv,vnd,zip";
	stConfig.allowedExtensions["Image"] = "png,gif,jpg,jpeg";
	stConfig.allowedExtensions["Flash"] = "swf,fla";
	stConfig.allowedExtensions["Media"] = "swf,fla,jpg,gif,jpeg,png,avi,mpg,mpeg,mp3,mp4,m4a,wma,wmv,wav,mid,midi,rmi,rm,ram,rmvb,mov,qt";

	userFilesPath = stConfig.userFilesPath;
	lAllowedExtensions = stConfig.allowedExtensions[url.type];
	
	// make sure the user files path is correctly formatted
	userFilesPath = replace(userFilesPath, "\", "/", "ALL");
	userFilesPath = replace(userFilesPath, '//', '/', 'ALL');
	if ( right(userFilesPath,1) neq "/" ) {
		userFilesPath = userFilesPath & "/";
	}
	if ( left(userFilesPath,1) neq "/" ) {
		userFilesPath = "/" & userFilesPath;
	}
	
	// make sure the current folder is correctly formatted
	url.currentFolder = replace(url.currentFolder, "\", "/", "ALL");
	url.currentFolder = replace(url.currentFolder, '//', '/', 'ALL');
	if ( right(url.currentFolder,1) neq "/" ) {
		url.currentFolder = url.currentFolder & "/";
	}
	if ( left(url.currentFolder,1) neq "/" ) {
		url.currentFolder = "/" & url.currentFolder;
	}
</cfscript>

<cfif not isDefined("url.app")>

	<cfset xmlContent = "<Error number=""1"" text=""Required url parameter 'app' not found."" />">
	
<cfelse>

	<cf_spApp name="#url.app#">
	
	<!--- <cfif not request.speck.userHasPermission("spSuper,spEdit")> --->
	<cfif request.speck.session.auth neq "logon" or not structKeyExists(request.speck.session, "roles") or structIsEmpty(request.speck.session.roles)>
	
		<cfset xmlContent = "<Error number=""1"" text=""Access Denied. Your session may have expired, please log in again."" />">
		
	<cfelse>
	
		<!--- ok, no problems so far, lets do some work... --->

		<cfscript>
			xmlContent = ""; // append to this string to build content
			
			fs = request.speck.fs; // we'll need this a few places
			
			// Get the base physical path to the web root for this application. Haven't figured out a way to do this reliably 
			// apart from hard-coding the www directory, bear in mind that this code is running from a virtual directory.
			rootDir = request.speck.appInstallRoot & fs & "www";
			
			// map the user files path to a physical directory
			userFilesDirectory = rootDir & replace(userFilesPath,"/",fs,"all");
			
			// hack the user files path to deal with speck applications running inside virtual directories
			userFilesPath = request.speck.appWebRoot & userFilesPath;
		</cfscript>
		
		<!--- create directories in physical path if they don't already exist --->
		<cfset currentDir = rootDir>
		<cfloop list="#userFilesPath#" index="dir" delimiters="/">
			
			<cfif not directoryExists(currentDir & fs & dir)>
				
				<cfdirectory action="create" directory="#currentDir##fs##dir#" mode="775">
			
			</cfif>
			
			<cfset currentDir = currentDir & fs & dir>
			
		</cfloop>
		
		<!--- create sub-directory for file type if it doesn't already exist --->
		<cfif not directoryExists(userFilesDirectory & fs & url.type)>
			<cfdirectory action="create" directory="#userFilesDirectory##fs##url.type#" mode="775">
		</cfif>
		
		<!--- 
		Most of the following code was copied from the default connector, although we do now check 
		for allowed extensions and delete uploaded files if they do not have an allowed extension.
		
		TODO: uploaded to the tmp directory for the application before moving them to the their 
		final destinations. That way we can be absolutely sure that files with extensions not 
		explicitly allowed never get uploaded to a publicly accessible directory. At the moment, 
		the file must be uploaded before the extension can be checked and if necessary, the file 
		deleted. This leaves the server open to attack temporarily while we're checking that it
		has an allowed extension, which fair enough is a pretty minimal risk, but it also leaves 
		the possibility of a file which shouldn't have been allowed being uploaded permanently
		to a publicly accessible directory in the event of some failure deleting the file. Ouch!
		--->
		
		<!--- :: Switch command arguments :: --->
		<cfswitch expression="#url.command#">
		
		
			<cfcase value="FileUpload">
			
				<cfset fileName = "">
				<cfset fileExt = "">
			
				<cftry>
				
					<!--- :: first upload the file with an unique filename :: --->
					<cffile action="upload"
						fileField="NewFile"
						destination="#userFilesDirectory##url.type##url.currentFolder#"
						nameConflict="makeunique"
						mode="664"
						attributes="normal">
						
					<cfif not listFindNoCase(lAllowedExtensions,cffile.ServerFileExt)>
					
						<cfset errorNumber = "202">
						<cffile action="delete" file="#cffile.ServerDirectory##fs##cffile.ServerFile#">
					
					<cfelse>
					
						<cfscript>
						errorNumber = 0;
						fileName = cffile.ClientFileName;
						fileExt = cffile.ServerFileExt;
				
						/**
						  * Validate filename for html download. Only a-z, 0-9, _, - and . are allowed.
						  */
						if( reFind("[^A-Za-z0-9_\-\.]", fileName) )
						{
							fileName = reReplace(fileName, "[^A-Za-z0-9\-\.]", "_", "ALL");
							fileName = reReplace(fileName, "_{2,}", "_", "ALL");
							fileName = reReplace(fileName, "([^_]+)_+$", "\1", "ALL");
							fileName = reReplace(fileName, "$_([^_]+)$", "\1", "ALL");
						}
				
						// When the original filename already exists, add numbers (0), (1), (2), ... at the end of the filename.
						if( compare( cffile.ServerFileName, fileName ) )
						{
							iCounter = 0;
							sTmpFileName = fileName;
							while( fileExists('#userFilesDirectory##url.type##url.currentFolder##fileName#.#fileExt#') )
							{
							  	iCounter=iCounter+1;
								fileName = sTmpFileName & '(#iCounter#)';
							}
						}
						</cfscript>
						
						<!--- :: Rename the uploaded file, if neccessary --->
						<cfif compare( cffile.ServerFileName, fileName )>
							<cfset errorNumber = "201">
							<cffile
								action="rename"
								source="#userFilesDirectory##url.type##url.currentFolder##cffile.ServerFileName#.#cffile.ServerFileExt#"
								destination="#userFilesDirectory##url.type##url.currentFolder##fileName#.#fileExt#"
								mode="664"
								attributes="normal">
						</cfif>		
						
						<!--- if type is image, check if uploaded file needs to be resized... --->
						<cfif url.type eq "image">
						
							<cfscript>
								// note: function copied from Asset property, but url struct can be passed as property definition struct
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
							<cfset tmpFilePath = "#userFilesDirectory##url.type##url.currentFolder##fileName#.#fileExt#">
							<cf_spImageInfo file="#tmpFilePath#" r_stImageInfo="stImageInfo">
							
							<cfset resizeDimensions = getResizeDimensions(url,stImageInfo.width,stImageInfo.height)>
							<cfset newWidth = listFirst(resizeDimensions)>
							<cfset newHeight = listLast(resizeDimensions)>
							
							<cfif newWidth gt 0 or newHeight gt 0>
								
								<!--- resize image - always save as jpeg --->
								
								<cfscript>
								
									if ( listFirst(request.speck.cfVersion) gte 8 ) { 
										
										// use cfimage
										image = imageRead(tmpFilePath);
										if ( newWidth gt 0 and newHeight gt 0 and url.cropToExact ) {
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
										} else {
											if ( newWidth eq 0 ) { newWidth = ""; }
											if ( newHeight eq 0 ) { newHeight = ""; }
											imageResize(image,newWidth,newHeight);
										}
										newFilePath = reReplace(tmpFilePath,"\.([a-zA-Z]+)$","_#image.width#x#image.height#.jpg");
										imageWrite(image,newFilePath,url.jpegCompression/100);
										
									} else {
										
										// use ImageCFC
										image = createObject("component","spImage");
										image.setOption("defaultJpegCompression",url.jpegCompression);
										image.init(tmpFilePath);
										if ( newWidth gt 0 and newHeight gt 0 and url.cropToExact ) {
											image.resize(newWidth,newHeight,true,true);	
										} else {
											image.resize(newWidth,newHeight);
										}
										imageInfo = image.getImageInfo();
										newFilePath = reReplace(tmpFilePath,"\.([a-zA-Z]+)$","_#imageInfo.width#x#imageInfo.height#.jpg");
										image.save(newFilePath);
										
									}
								</cfscript>
								
								<!--- delete the original file --->
								<cftry>
								
									<cffile action="delete" file="#tmpFilePath#">
									
								<cfcatch>
									<!--- do nothing, TODO: log info --->
								</cfcatch>
								</cftry>
			
							</cfif>
						
						</cfif>
					
					</cfif>
			
					<cfcatch type="Any">
					
						<cfset errorNumber = "202">
						
					</cfcatch>
					
				</cftry>
				
				
				<cfif errorNumber eq 201>
				
					<!--- :: file was changed (201), submit the new filename :: --->
					<cfoutput>
					<script type="text/javascript">
					window.parent.frames['frmUpload'].OnUploadCompleted(#errorNumber#,'#replace( fileName & "." & fileExt, "'", "\'", "ALL")#');
					</script>
					</cfoutput>

				<cfelse>
				
					<!--- :: file was uploaded succesfully(0) or an error occured(202). Submit only the error code. :: --->
					<cfoutput>
					<script type="text/javascript">
					window.parent.frames['frmUpload'].OnUploadCompleted(#errorNumber#);
					</script>
					</cfoutput>
					
				</cfif>
				
				<cfabort>
			
			</cfcase>
			
			
			<cfcase value="GetFolders">
			
				<!--- :: Sort directories first, name ascending :: --->
				<cfdirectory 
					action="list" 
					directory="#userFilesDirectory##url.type##url.currentFolder#" 
					name="qDir"
					sort="type,name">
				
				<cfscript>
					iLen = qDir.recordCount;	
					i=1;
					sFolders = '';
					
					while( i LTE iLen )
					{
						if( not compareNoCase( qDir.type[i], "FILE" ))
							break;
						if( not listFind(".,..", qDir.name[i]) )
							sFolders = sFolders & '<Folder name="#xmlFormat(qDir.name[i])#" />';
						i=i+1;
					}
			
					xmlContent = xmlContent & '<Folders>' & sFolders & '</Folders>';
				</cfscript>
			
			</cfcase>
			
			
			<cfcase value="GetFoldersAndFiles">
			
				<!--- :: Sort directories first, name ascending :: --->
				<cfdirectory 
					action="list" 
					directory="#userFilesDirectory##url.type##url.currentFolder#" 
					name="qDir"
					sort="type,name">
				<cfscript>
					iLen = qDir.recordCount;
					i=1;
					sFolders = '';
					sFiles = '';
					
					while( i LTE iLen )
					{
						if( not compareNoCase( qDir.type[i], "DIR" ) and not listFind(".,..", qDir.name[i]) )
						{
							sFolders = sFolders & '<Folder name="#xmlFormat(qDir.name[i])#" />';
						}
						else if( not compareNoCase( qDir.type[i], "FILE" ) )
						{
							iFileSize = int( qDir.size[i] / 1024 );
							sFiles = sFiles & '<File name="#xmlFormat(qDir.name[i])#" size="#IIf( iFileSize GT 0, DE( iFileSize ), 1)#" />';
						}
						i=i+1;
					}
			
					xmlContent = xmlContent & '<Folders>' & sFolders & '</Folders>';
					xmlContent = xmlContent & '<Files>' & sFiles & '</Files>';
				</cfscript>
			
			</cfcase>
			
			
			<cfcase value="CreateFolder">
			
				<cfparam name="url.NewFolderName" default="">
			
				<cfif not len( url.NewFolderName ) or len( url.NewFolderName ) GT 255>
					<cfset iErrorNumber = 102>	
				<cfelseif directoryExists( userFilesDirectory & url.type & url.currentFolder & url.NewFolderName )>
					<cfset iErrorNumber = 101>
				<cfelseif reFind( "^\.\.", url.NewFolderName )>
					<cfset iErrorNumber = 103>
				<cfelse>
					<cfset iErrorNumber = 0>
			
					<cftry>
						<cfdirectory
							action="create"
							directory="#userFilesDirectory##url.type##url.currentFolder##url.NewFolderName#"
							mode="775">
						<cfcatch>
							<!--- ::
								* Not resolvable ERROR-Numbers in ColdFusion:
								* 102 : Invalid folder name. 
								* 103 : You have no permissions to create the folder. 
								:: --->
							<cfset iErrorNumber = 110>
						</cfcatch>
					</cftry>
				</cfif>
				
				<cfset xmlContent = xmlContent & '<Error number="#iErrorNumber#" />'>
			
			</cfcase>
			
			
			<cfdefaultcase>
			
				<cfthrow type="fckeditor.connector" message="Illegal command: #url.command#">
				
			</cfdefaultcase>
			
			
		</cfswitch>
			
	</cfif> <!--- not request.speck.userHasPermission("spSuper,spEdit") or request.speck.session.auth neq "logon" --->

</cfif> <!--- not isDefined("url.app") --->

<cfscript>
	xmlHeader = '<?xml version="1.0" encoding="utf-8" ?><Connector command="#url.command#" resourceType="#url.type#">';
	xmlHeader = xmlHeader & '<CurrentFolder path="#url.currentFolder#" url="#userFilesPath##url.type##url.currentFolder#" />';
	xmlFooter = '</Connector>';
</cfscript>

<cfheader name="Pragma" value="no-cache">
<cfheader name="Cache-Control" value="no-cache, no-store, must-revalidate">
<cfcontent reset="true" type="text/xml; charset=UTF-8">
<cfoutput>#xmlHeader##xmlContent##xmlFooter#</cfoutput>