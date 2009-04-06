<cfsetting enablecfoutputonly="yes">
<!---
	CFFM 1.16
	Written by Rick Root (rick@webworksllc.com)
	See LICENSE.TXT for copyright and redistribution restrictions.	

	File:  cffm.cfm
--->
<!---		**************************************************
			LOAD THE RESOURCE BUNDLE FIRST
			**************************************************
--->
<cfscript>
	variables.rbm = createObject('component','javaRB');
	variables.defaultJavaLocale = "en_US";
	variables.rbDir= GetDirectoryFromPath(getCurrentTemplatePath());
	variables.rbFile= rbDir & "cffm.properties"; //base resource file
	variables.resourceKit = variables.rbm.getResourceBundle("#variables.rbFile#","#variables.defaultJavaLocale#");
</cfscript>

<!---		**************************************************
			INITIALIZE the CFC
			**************************************************
--->
<cffunction name="cffmdump">
	<cfargument name="arg1" type="any" required="yes">
	<cfoutput>
	<cfdump var="#arguments#">
	</cfoutput>
	<cfabort>
</cffunction>
<cfset cffm = createObject("component","cffm")>
<cfinvoke component="#cffm#" method="init">
	<!--- includeDir = You can and probably should hard code this... by default, the directory is a 
		directory named "custom" located in the same directory as this file. --->
	<cfinvokeargument name="includeDir" value="#ExpandPath(".")#/custom">
	<!--- includeDirWeb = web path to the directory specified above. --->
	<cfinvokeargument name="includeDirWeb" value="./custom">
	<!--- disallowedExtensions = file extensions you don't want people to upload --->
	<cfinvokeargument name="disallowedExtensions" value="cfm,cfml,cfc,dbm,dbml,php,php3,php4,php5,asp,aspx,pl,plx,pls,cgi,jsp,pif,scr,vbs,exe">
	<!---
	// allowedExtensions = 
	// as an alternative to disallowing extensions, you can allow 
	// only certain extensions.  This overrides the disallowedExtensions
	// setting.  You might use this to restrict the user to uploading
	// images or something.
	--->
	<cfinvokeargument name="allowedExtensions" value="jpg,gif,png,txt,html,htm">
	<!--- editableExtensions:  specifies what kind of files can be edited with the simple text editor --->
	<cfinvokeargument name="editableExtensions" value="cfm,cfml,cfc,dbm,dbml,php,php3,php4,asp,aspx,pl,plx,pls,cgi,jsp,txt,html,htm,log,csv,js,css">
	<!---
	// overwriteDefault = 
	// There are several places where a checkbox appears to overwrite
	// existing.  This controls what it defaults to.  On or off.
	--->
	<cfinvokeargument name="overwriteDefault" value="true">
	<!--- iconPath = web path to the location of the icons used by CFFM --->
	<cfinvokeargument name="iconPath" value="./cffmIcons">

	<cfinvokeargument name="debug" value="0">
	<!--- file to be cfincluded above all CFFM output --->
	<cfinvokeargument name="templateWrapperAbove" value="">
	<!--- file to be cfincluded below all CFFM output --->
	<cfinvokeargument name="templateWrapperBelow" value="">
	<!--- name of this file.  You should not change this. --->
	<cfinvokeargument name="cffmFilename" value="#GetfileFromPath(getBaseTemplatePath())#">
	<cfinvokeargument name="enableImageDimensionsInDirList" value="true">
	<cfinvokeargument name="maxImageDimensionsPerFileListing" value="20">
	<cfinvokeargument name="readOnly" value="No">
	<Cfinvokeargument name="allowUnzip" value="Yes">
	<cfinvokeargument name="allowCreateDirectory" value="Yes">
	<cfinvokeargument name="allowMultipleUploads" value="Yes">
</cfinvoke>
<!--- place the resource kit in the cffm object --->
<cfset cffm.resourceKit = variables.resourceKit>

<!---	**************************************************
		END OF CONFIGURATION SECTION.
		YOU DO NOT NEED TO MAKE ANY CHANGES BELOW HERE
		**************************************************

		**************************************************
		BEGIN UDF SECTION
		These functions could not be included in the CFC
		for various reasons.  
		**************************************************
--->
<cffunction name="fckUploadResult">
        <cfargument name="errorNumber" type="numeric" required="yes">
        <cfargument name="fileUrl" type="string" required="no" default="">
        <cfargument name="fileName" type="string" required="no" default="">
        <cfargument name="customMsg" type="string" required="no" default="">

        <cfoutput>
                <script type="text/javascript">
                        window.parent.OnUploadCompleted(#errorNumber#, "#JSStringFormat(fileUrl)#", "#JSStringFormat(fileName)#", "#JSStringFormat(customMsg)#");
                </script>
        </cfoutput>

        <cfabort><!--- Result sent, stop processing this page --->
</cffunction>

<cffunction name="uploadFromFCK" output="no" returnType="struct">
	<cfargument name="destination" type="string" required="yes">
	<cfargument name="overwriteExisting" type="boolean" required="yes">
	<cfargument name="scopeForm" type="Struct" required="yes">
	
	<cfset var retVal = StructNew()>

	<cfset retVal.errorCode = 0>
	<cfset retVal.errorMessage = "">
	
	<cfif isDefined("Form.NewFile") and Evaluate("Form.NewFile") neq "">
		<cftry>
			<cffile action="UPLOAD" filefield="Form.NewFile" destination="#arguments.destination#" nameconflict="#iif(arguments.overwriteExisting, DE("OVERWRITE"), DE("ERROR"))#">
			<cfif NOT cffile.fileWasSaved>
				<cfset retVal.errorCode = 1>
				<cfset retVal.errorMessage = retVal.errorMessage & "#cffm.resourceKit.errorMsg.t23#.">
			</cfif>
			<cfif NOT cffm.checkExtension(cffile.clientFileExt)>
				<cffile action="delete" file="#cffile.serverDirectory##variables.dirSep##cffile.serverFile#">
				<cfset retVal.errorCode = 1>
				<cfset retVal.errorMessage = retVal.errorMessage & "#cffm.resourceKit.errorMsg.t11#.<br>">
			</cfif>
			<cfset retVal.fileUrl = variables.workingDirectoryWeb & "/" & cffile.serverFile>
			<cfset retVal.fileName = cffile.serverFile>
			<cfcatch type="any">
				<cfset retVal.errorCode = 1>
				<cfset retVal.errorMessage = retVal.errorMessage & "#cffm.resourceKit.errorMsg.t24#:  #cfcatch.message# - #cfcatch.detail#<br>">
			</cfcatch>
		</cftry>
	</cfif>
	<cfreturn retVal>
</cffunction>

<cffunction name="uploadMultipleFiles" output="no" returnType="struct">
	<cfargument name="destination" type="string" required="yes">
	<cfargument name="overwriteExisting" type="boolean" required="yes">
	<cfargument name="scopeForm" type="Struct" required="yes">
	
	<cfset var retVal = StructNew()>
	<cfset var cnt = 1>

	<cfset retVal.errorCode = 0>
	<cfset retVal.errorMessage = "">
	
	<cfif isDefined("form.NewFile")>
		<cfset form.uploadFile1 = form.NewFile>
	</cfif>
	<cfloop from="1" to="20" index="cnt" step="1">
		<cfif isDefined("Form.uploadFile#cnt#") and Evaluate("Form.uploadFile#cnt#") neq "">
			<cftry>
				<cffile action="UPLOAD" filefield="Form.uploadFile#cnt#" destination="#arguments.destination#" nameconflict="#iif(arguments.overwriteExisting, DE("OVERWRITE"), DE("ERROR"))#">
				<cfif NOT cffile.fileWasSaved>
					<cfset retVal.errorCode = 1>
					<cfset retVal.errorMessage = retVal.errorMessage & "#cffm.resourceKit.errorMsg.t23#.">
				</cfif>
				<cfif NOT cffm.checkExtension(cffile.clientFileExt)>
					<cffile action="delete" file="#cffile.serverDirectory##variables.dirSep##cffile.serverFile#">
					<cfset retVal.errorCode = 1>
					<cfset retVal.errorMessage = retVal.errorMessage & "#cffm.resourceKit.errorMsg.t11#.<br>">
				</cfif>
				<cfset retVal.fileUrl = variables.workingDirectoryWeb & "/" & cffile.serverFile>
				<cfset retVal.fileName = cffile.serverFile>
				<cfcatch type="any">
					<cfset retVal.errorCode = 1>
					<cfset retVal.errorMessage = retVal.errorMessage & "#cffm.resourceKit.errorMsg.t24#:  #cfcatch.message# - #cfcatch.detail#<br>">
				</cfcatch>
			</cftry>
		</cfif>
	</cfloop>
	<cfreturn retVal>
	
</cffunction>

<cffunction name="DebugOutput" output="yes" returnType="void">
	<cfargument name="debugContent" default="" required="no" type="any">
	<cfif cffm.debug><cfoutput>#arguments.debugContent#</cfoutput></cfif>
</cffunction>

<cffunction name="FatalError" output="yes" returnType="void">
	<cfargument name="errorContent" default="" required="no" type="any">
	<cfoutput>#arguments.errorContent#</cfoutput>
	<cfabort>
</cffunction>

<cffunction name="relocate" output="yes" returnType="void">
	<cfargument name="newlocation" required="yes" type="string">
	<cflocation url="#arguments.newlocation#" addtoken="No">
</cffunction>

<cffunction name="setCFFMCookie" output="yes" returnType="void">
	<cfargument name="cookieName" type="string" required="yes">
	<cfargument name="cookieValue" type="any" required="yes">
	<cfcookie name="#cookieName#" value="#cookieValue#">
</cffunction>

<!---
		**************************************************
		ACTUAL CODE BEGINS HERE... 
		
		FIRST WE MUST DO VARIABLE INITIALIZATION
		
		IMPORTANT NOTE:  Session Management on the server or cookies
		on the browser are required in order for CFFM to be used as
		a file browser for HTML editors such as FCKeditor or TinyMCE
		**************************************************
--->

<cftry>
    <cfset session.test = 1>
    <cfset variables.sessionEnabled = "true">
    <cfcatch type="any">
       <cfset variables.sessionEnabled = "false">
    </cfcatch>
</cftry>

<cfscript>
	if (getFileFromPath(getCurrentTemplatePath()) eq "cffm_image.cfm") 
	{
		variables.EDITOR_RESOURCE_TYPE = "image";
		variables.editorType = "fck";
	} else if (getFileFromPath(getCurrentTemplatePath()) eq "cffm_flash.cfm") {
		variables.EDITOR_RESOURCE_TYPE = "flash";
		variables.editorType = "fck";
	} else if (getFileFromPath(getCurrentTemplatePath()) eq "cffm_file.cfm") {
		variables.EDITOR_RESOURCE_TYPE = "file";
		variables.editorType = "fck";
	} else if (getFileFromPath(getCurrentTemplatePath()) eq "upload.cfm") {
		variables.EDITOR_RESOURCE_TYPE = "file";
		variables.editorType = "fck";
		variables.action = "quickupload";
		url.action = "quickupload";
	} else {
		if (isDefined("url.EDITOR_RESOURCE_TYPE")) {
			variables.EDITOR_RESOURCE_TYPE = url.EDITOR_RESOURCE_TYPE;
		} else if (variables.sessionEnabled AND isDefined("session.EDITOR_RESOURCE_TYPE")) {
			variables.EDITOR_RESOURCE_TYPE = session.EDITOR_RESOURCE_TYPE;
		} else if (isDefined("cookie.EDITOR_RESOURCE_TYPE")) {
			variables.EDITOR_RESOURCE_TYPE = cookie.EDITOR_RESOURCE_TYPE;
		} else {
			variables.EDITOR_RESOURCE_TYPE = "file";
		}
		if (variables.sessionEnabled) {
			session.EDITOR_RESOURCE_TYPE = variables.EDITOR_RESOURCE_TYPE;
		} else {
			setCFFMCookie("EDITOR_RESOURCE_TYPE", variables.EDITOR_RESOURCE_TYPE);
		}

		if (isDefined("url.editorType")) {
			variables.editorType = url.editorType;
		} else if (variables.sessionEnabled AND isDefined("session.editorType")) {
			variables.editorType = session.editorType;
		} else if (isDefined("cookie.editorType")) {
			variables.editorType = cookie.editorType;
		} else {
			variables.editorType = "";
		}
		if (variables.sessionEnabled) {
			session.editorType = variables.editorType;
		} else {
			setCFFMCookie("editorType", variables.editorType);
		}
	}
	if (isDefined("url.subdir")) {
		variables.subdir = url.subdir;
	} else if (isDefined("form.subdir")) {
		variables.subdir = form.subdir;
	} else if (variables.sessionEnabled AND isDefined("session.subdir")) {
		variables.subdir = session.subdir;
	} else if (isDefined("cookie.subdir")) {
		variables.subdir = cookie.subdir;
	} else {
		variables.subdir = "";
	}
	if (variables.sessionEnabled) {
		session.subdir = variables.subdir;
	} else {
		setCFFMCookie("subdir", variables.subdir);
	}
	
</cfscript>




<cfscript>
	/* determine the proper directory separator */
	variables.dirSep = cffm.getDirectorySeparator();
	if (not DirectoryExists(cffm.includeDir)) {
		FatalError(cffm.resourceKit.errorMsg.t1);
	}

	variables = cffm.createVariables(variables, form, url, "action,subdir,deleteFilename,renameOldFilename,renameNewFilename,editFilename,viewFilename,editFileContent,createNewFilename,createNewFileType,unzipFilename,moveToSubdir,moveFilename,unzipToSubdir,overWrite,rotateDegrees,resizeWidthValue,resizeHeightValue,cropStartX,cropStartY,cropWidthValue,cropHeightValue,preserveAspect,cropToExact,showTotalUsage");
	if (variables.action eq "") { 
		variables.action = "list"; 
	}
	if (variables.overWrite eq "") {
		variables.overWrite = false;
	}

</cfscript>
<cfscript>
	// some vars are being passed to java methods and MUST be cast to double using javacast
	variables = cffm.forceNumeric(variables, "resizeWidthValue,resizeHeightValue,cropStartX,cropStartY,cropWidthValue,cropHeightValue,preserveAspect,cropToExact,rotateDegrees");

	/* strip leading and trailing slashes first */
	variables.subdir = trim(REReplace(variables.subdir,"[\\\/]*(.*?)[\\\/]*$","\1","ONE"));
	/* 
	** there should never be ./ or ../ or /../ or /./ in the subdir
	** we don't like that kinda stuff
	*/
	variables.subdir = cffm.checkSubdirValue(variables.subdir);
	DebugOutput("cffm.includeDir = " & cffm.includeDir & "<P>");
	// set the physical path to our current working directory.
	variables.workingDirectory = cffm.createServerPath(variables.subdir);
	// set the logical URL path to our current working directory.
	variables.workingDirectoryWeb = cffm.createWebPath(variables.subdir);
	variables.errorMessage = "";
	DebugOutput("variables.workingDirectory = " & variables.workingDirectory & "<P>");
	DebugOutput("variables.workingDirectoryWeb = " & variables.workingDirectoryWeb & "<P>");
</cfscript>
<cfscript>
	if ( variables.moveToSubdir neq cffm.checkSubdirValue(variables.moveToSubdir) )
	{
		variables.action = "list";
		variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t2#</li>#Chr(10)#";
	}
</cfscript>
<cfscript>
	if ( variables.unzipToSubdir neq cffm.checkSubdirValue(variables.unzipToSubdir) )
	{
		variables.action = "list";
		variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t3#</li>#chr(10)#";
	}
</cfscript>
<cfscript>
	if (NOT DirectoryExists(variables.workingDirectory) ) {
		/* oops!  Reset everything and return to the home directory */
		variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t4#</li>#Chr(10)#";
		variables.workingDirectory = cffm.includeDir;
		variables.workingDirectoryWeb = cffm.includeDirWeb;
		variables.subdir = "";
		variables.action = "list";
	}
</cfscript>
<cfif variables.action eq "download">
        <cfheader name="Content-disposition" value="attachment;filename=#downloadFilename#">
        <cfcontent type="#cffm.getMimeType(downloadFilename)#" file="#variables.workingDirectory##dirsep##downloadFilename#">
        <cfabort>
</cfif>

<cfscript>
	// **************************************************
	// ARE WE PERFORMING SOME KIND OF ACTION? //
	// **************************************************
	if (variables.action eq "delete") {
		if (variables.deleteFilename contains "/" or variables.deleteFilename contains "\") {
			variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t5#</li>#Chr(10)#";
		} else {
			variables.deleteResults = "";
			variables.fileToDelete = variables.workingDirectory & variables.dirsep & variables.deleteFilename;
			if (cffm.getPathType(fileToDelete) eq "file")
			{
				variables.deleteResults = cffm.deleteFile(variables.fileToDelete);
			} else {
				variables.deleteResults = cffm.deleteDirectory(variables.fileToDelete, "True");
			}
			if (variables.deleteResults.errorCode neq 0) 
			{
				variables.errorMessage = variables.errorMessage & "<li>#variables.deleteResults.errorMessage#</li>#Chr(10)#";
			} else {
				relocate(cffm.cffmFilename & "?subdir=" & urlEncodedFormat(variables.subdir));
			}
		}
		variables.action = "list";
	} else if (variables.action eq "unzip") {
		if (variables.unzipFilename contains "/" or variables.unzipFilename contains "\") {
			variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t5#</li>#Chr(10)#";
		} else {
			variables.unzipResults = "";
			variables.fileToUnzip = variables.workingDirectory & variables.dirsep & variables.unzipFilename;
			variables.unzipResults = cffm.unzipFile(variables.fileToUnzip,cffm.createServerPath(variables.unzipToSubdir),variables.overwrite);
			if (isStruct(variables.unzipResults) and variables.unzipResults.errorCode neq 0) 
			{
				variables.errorMessage = variables.errorMessage & "<li>#variables.unzipResults.errorMessage#</li>#Chr(10)#";
			} else {
				variables.subdir = variables.unzipToSubdir;
				relocate(cffm.cffmFilename & "?subdir=" & urlEncodedFormat(variables.subdir));
			}
		}
		variables.action = "list";
	} else if (variables.action eq "rename") {
		if (variables.renameNewFilename contains "/" or variables.renameNewFilename contains "\") {
			variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t5#</li>#Chr(10)#";
		} else {
			variables.renameResults = "";
			variables.oldFilename = variables.workingDirectory & variables.dirsep & variables.renameOldFilename;
			variables.newFilename = variables.workingDirectory & variables.dirsep & variables.renameNewFilename;
			variables.renameResults = cffm.renameFile(variables.oldFilename,variables.newFilename,"rename",variables.overWrite);
			if (isStruct(variables.renameResults) and variables.renameResults.errorCode neq 0) 
			{
				variables.errorMessage = variables.errorMessage & "<li>#variables.renameResults.errorMessage#</li>#Chr(10)#";
			} else {
				relocate(cffm.cffmFilename & "?subdir=" & urlEncodedFormat(variables.subdir));
			}
		}
		variables.action = "list";
	} else if (variables.action eq "move" or variables.action eq "copy") {
		if (variables.moveFilename contains "/" or variables.moveFilename contains "\") 
		{
			variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t5#</li>#Chr(10)#";
		} else {
			variables.moveFromPath = cffm.createServerPath(variables.subdir,variables.moveFilename);
			variables.moveToPath = cffm.createServerPath(variables.moveToSubdir,variables.moveFilename);
			if (cffm.getPathType(variables.moveFromPath) eq "directory" AND variables.moveFromPath eq variables.moveToPath)
			{
				variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t6#</li>#Chr(10)#";
			} else if (cffm.getPathType(variables.moveFromPath) eq "directory" and Find(variables.moveFromPath,variables.moveToPath) eq 1) {
				variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMessage.t7#</li>#Chr(10)#";
			} else if (cffm.getPathType(variables.moveFromPath) eq "file" AND getDirectoryFromPath(variables.moveFromPath) eq variables.moveToPath ) {
				/* don't do anything, because they selected to move the file to the directory it's already in! */
			} else {
				variables.moveResults = "";
				variables.moveResults = cffm.renameFile(variables.moveFromPath,variables.moveToPath,variables.action, variables.overWrite);
				if (isStruct(variables.moveResults) and variables.moveResults.errorCode neq 0)
				{
					variables.errorMessage = variables.errorMessage & "<li>#variables.moveResults.errorMessage#</li>#Chr(10)#";
				} else {
					relocate(cffm.cffmFilename & "?subdir=" & urlEncodedFormat(variables.subdir));
				}
			}
		}
		variables.action = "list";

	} else if (variables.action eq "upload") {
		variables.uploadResults = "";
		variables.uploadResults = uploadMultipleFiles(variables.workingDirectory, variables.overwrite, form);
		if (isStruct(variables.uploadResults) and variables.uploadResults.errorCode neq 0) 
		{
			variables.errorMessage = variables.errorMessage & "<li>#variables.uploadResults.errorMessage#</li>#Chr(10)#";
		} else {
			relocate(cffm.cffmFilename & "?subdir=" & urlEncodedFormat(variables.subdir));
		}
		variables.action = "list";
	} else if (variables.action eq "quickupload") {
		variables.uploadResults = "";
		variables.uploadResults = uploadFromFCK(variables.workingDirectory, variables.overwrite, form);
		if (variables.uploadResults.errorCode neq 0)
		{
			variables.errorMessage = variables.errorMessage & "<li>#variables.uploadResults.errorMessage#</li>#Chr(10)#";
			fckUploadResult(variables.uploadResults.errorCode,'','',variables.uploadResults.errorMessage);
		} else if (not structKeyExists(variables.uploadResults,"fileurl") ) {
			variables.errorMessage = variables.errorMessage & "<li>#variables.resourceKit.errorMsg.t25#</li>#Chr(10)#";
			fckUploadResult(variables.uploadResults.errorCode,'','',variables.resourceKit.errorMsg.t25);
		} else {
			fckUploadResult(0,variables.uploadResults.fileUrl,variables.uploadResults.fileName,'');
		}
	} else if (variables.action eq "viewSource" or action eq "edit") {
		if (variables.editFilename contains "/" or variables.editFilename contains "\") {
			variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t5#</li>#Chr(10)#";
			action = "list";
		} else if (cffm.getPathType(cffm.createServerPath(variables.subdir,variables.editFilename)) neq "file")	{
			variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t8#  #cffm.createServerPath(variables.subdir, variables.editFilename)#</li>#Chr(10)#";		
			variables.action = "list";
		} else {
			variables.fileToRead = variables.workingDirectory & variables.dirsep & variables.editFilename;
			variables.readResults = cffm.readFile(variables.fileToRead);
			if (variables.readResults.errorCode is 0) {
				variables.content = variables.readResults.fileContent;
			} else {
				variables.errorMessage = variables.errorMessage & "<li>#variables.readResults.errorMessage#</li>#Chr(10)#";
				action = "list";
			}
		}
	} else if (variables.action eq "save") {
		variables.fileToWrite = variables.workingDirectory & variables.dirsep & variables.editFilename;
		variables.saveResults = cffm.saveFile(variables.fileToWrite, variables.editFileContent);
		if (variables.saveResults.errorCode gt 0)
		{
			variables.errorMessage = variables.errorMessage & "<li>#variables.saveResults.errorMessage#</li>#Chr(10)#";		
		} else {
			relocate(cffm.cffmFilename & "?subdir=" & urlEncodedFormat(variables.subdir));
		}
	} else if (variables.action eq "create") {
		if (variables.createNewFilename contains "/" or variables.createNewFilename contains "\") {
			variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t5#</li>#Chr(10)#";
		} else if (variables.createNewFilename eq "") {
			variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t22#</li>#Chr(10)#";
		} else {
			variables.fileToCreate = variables.workingDirectory & variables.dirsep & variables.createNewFilename;
			variables.createResults = cffm.createFile(variables.fileToCreate,variables.createNewFileType);
			if (variables.createResults.errorCode gt 0)
			{
				variables.errorMessage = variables.errorMessage & "<li>#variables.createResults.errorMessage#</li>#Chr(10)#";		
			} else {
				relocate(cffm.cffmFilename & "?subdir=" & urlEncodedFormat(variables.subdir));
			}
		}
		variables.action = "list";
	} else if (listFind("flip,flop,resize,crop,rotate,manipulateForm,commitChanges,undoChanges",action) gt 0) {
		if (variables.editFilename contains "/" or variables.editFilename contains "\") {
			variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t5#</li>#Chr(10)#";
			action = "list";
		} else if (cffm.getPathType(cffm.createServerPath(variables.subdir,variables.editFilename)) neq "file")	{
			variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t8#  #cffm.createServerPath(variables.subdir, variables.editFilename)#</li>#Chr(10)#";		
			variables.action = "list";
		} else {
			variables.image = CreateObject("component","ImageObject");
			variables.imagePath = cffm.createServerPath(variables.subdir, variables.editFilename);
			try {
				variables.image.init(variables.imagePath);
				imageLoaded = true;
			} catch(Any e) {
				imageLoaded = false;
			}
			if (NOT imageLoaded)
			{
				variables.errorMessage = variables.errorMessage & "<li>#cffm.resourceKit.errorMsg.t9#</li>#Chr(10)#";
				variables.action = "list";
			} else if (listFindNoCase("flip,flop,rotate,resize,crop",variables.action)) {
				try {
					if (variables.action eq "flip") {
						variables.image.flipVertical();
					} else if (variables.action eq "flop") {
						variables.image.flipHorizontal();
					} else if (variables.action eq "rotate") {
						variables.image.rotate(variables.rotateDegrees);
					} else if (variables.action eq "resize") {
						variables.image.resize(variables.resizeWidthValue, variables.resizeHeightValue, yesNoFormat(variables.preserveAspect), yesNoFormat(variables.cropToExact));
					} else if (variables.action eq "crop") {
						variables.image.crop(variables.cropStartX, variables.cropStartY, variables.cropWidthValue, variables.cropHeightValue);
					}
					DebugOutput("Writing image");
					variables.image.save(variables.imagePath,95);
					imageWritten = true;
				} catch(Any e) {
					// cffmdump(e);
					variables.errorMessage = variables.errorMessage & "<li>#e.detail#.</li>#Chr(10)#";
					imageWritten = false;
				}
				if (not imageWritten)
				{
					variables.action = "list";
				} else {
					relocate(cffm.cffmFilename & "?action=manipulateForm&subdir=" & urlEncodedFormat(variables.subdir) & "&editFilename=" & urlEncodedFormat(variables.editFilename));
				}
			}
		}
	}
	
	// **************************************************
	// LET'S GET IT STARTED
	// **************************************************
	variables.dirlist = "";
</cfscript>
<cfif cffm.templateWrapperAbove neq "">
	<cfsetting enablecfoutputonly="no">
	<CFINCLUDE TEMPLATE="#cffm.templateWrapperAbove#">
	<cfsetting enablecfoutputonly="yes">
<cfelse>
	<cfoutput><HTML><HEAD><TITLE>CFFM File Manager version <CFOUTPUT>#cffm.version#</CFOUTPUT></TITLE></HEAD><BODY></cfoutput>
	<cfhtmlhead text="<link rel=stylesheet type=text/css href=cffmDefault.css>">
</cfif>

<cfif variables.editorType eq "fck">
	<cfoutput>
	<script language="javascript">
	function OpenFile( fileUrl )
	{
		window.opener.SetUrl( fileUrl ) ;
		window.close() ;
		window.opener.focus() ;
	}
	</script>
	</cfoutput>
<cfelseif variables.editorType eq "mce">
	<cfoutput>
	<script language="javascript">
	function OpenFile( fileUrl )
	{
		srcInput = window.opener.win2.document.getElementById('<cfif variables.EDITOR_RESOURCE_TYPE eq "file">href<cfelseif variables.EDITOR_RESOURCE_TYPE eq "flash">file<cfelse>src</cfif>');		
		srcInput.value = fileUrl;

		window.close() ;
		window.opener.win2.focus() ;
	}
	</script>
	</cfoutput>
</cfif>
<cfoutput>
#debugOutput("<P>Physical Directory: #variables.workingDirectory#</P>")#
<p class="cffm_location">#cffm.resourceKit.Msg.t1#:  #variables.workingDirectoryWeb#</p></cfoutput>
<cfif listFind("edit,viewsource,viewzip,renameForm,copymoveForm,manipulateForm",action) gt 0>
	<cfoutput><p class="cffm_editor">Working with #cffm.getPathType(cffm.createServerPath(variables.subdir,variables.editFilename))#:  #variables.workingDirectoryWeb#/#editFilename# </p></cfoutput>
</cfif>
<cfset variables.listAllFiles = cffm.directoryList(cffm.includeDir,"true")>
<cfif variables.listAllFiles.RecordCount gt 0>
	<cfquery name="variables.listAllDirectories" dbtype="query">
		select * from variables.listAllFiles
		where type = 'Dir'
	</cfquery>
<cfelse>
	<!--- this is a workaround for CFMX --->
	<cfset variables.listAllDirectories = QueryNew("IGNORE")>
</cfif>
<cfif isDefined("variables.errorMessage") and variables.errorMessage neq "">
	<cfoutput>
	<fieldset class="cffm_errorMessage">
	<legend>#cffm.resourceKit.Msg.t3#</legend>
	<ul>
	#variables.errorMessage#
	</ul>
	</fieldset>
	</cfoutput>
</cfif>
<cfsetting enablecfoutputonly="no">
<cfif variables.action eq "viewSource" or variables.action eq "edit">
	<cfoutput><a href="#cffm.cffmFilename#?subdir=#urlEncodedFormat(variables.subdir)#"><b>#cffm.resourceKit.Msg.t14#</b></A></cfoutput>
	<P>
	<form method="post" action="<cfoutput>#cffm.cffmFilename#</cfoutput>">
	<input type="hidden" name="action" value="save">
	<input type="hidden" name="subdir" value="<cfoutput>#variables.subdir#</cfoutput>">
	<input type="hidden" name="editFilename" value="<cfoutput>#variables.editFilename#</cfoutput>">
	<textarea class="cffm_editor" name="editFileContent"><cfoutput>#variables.content#</cfoutput></textarea>
	<p>
	<cfif variables.action eq "edit">
	<input type="submit" class="button" value="<cfoutput>#cffm.resourceKit.buttonText.t1#</cfoutput>">
	<input type="button" class="button" value="<cfoutput>#cffm.resourceKit.buttonText.t2#</cfoutput>" onClick="javascript:history.go(-1);">
	</cfif>
	</form>
<cfelseif action eq "commitChanges">
	<cffile action="COPY" source="#variables.workingDirectory#/#variables.editFilename#" destination="#variables.workingDirectory#/#reReplace(variables.editFilename,"^\_\_TEMP\_\_","","ALL")#">
	<cffile action="DELETE" file="#variables.workingDirectory#/#variables.editFilename#">
	<cfoutput>
		<p>#cffm.ResourceKit.Msg.t66#</p>
		<p><a href="#cffm.cffmFilename#?subdir=#urlEncodedFormat(variables.subdir)#"><b>#cffm.ResourceKit.Msg.t14#</b></A></p>
	</cfoutput>
<cfelseif action eq "undoChanges">
	<cffile action="DELETE" file="#variables.workingDirectory#/#variables.editFilename#">
	<cfoutput>
		<p>#cffm.ResourceKit.Msg.t66#</p>
		<p><a href="#cffm.cffmFilename#?subdir=#urlEncodedFormat(variables.subdir)#"><b>#cffm.ResourceKit.Msg.t14#</b></A></p>
	</cfoutput>
<cfelseif action eq "manipulateForm" and variables.image.getImageInfo().IMAGETYPE eq 0>
	<cfoutput>
		<p>#cffm.ResourceKit.Msg.t68#</p>
		<p><a href="#cffm.cffmFilename#?subdir=#urlEncodedFormat(variables.subdir)#"><b>#cffm.ResourceKit.Msg.t14#</b></A></p>
	</cfoutput>
<cfelseif action eq "manipulateForm">
	<!--- make a "working copy" --->
	<cfset variables.workingCopy = "No">
	<cfif Find("__TEMP__",variables.editFilename) is 1>
		<cfset variables.workingCopy = "Yes">
	<cfelse>
		<cffile action="COPY" source="#variables.workingDirectory#/#variables.editFilename#" destination="#variables.workingDirectory#/__TEMP__#variables.editFilename#">
		<cfset variables.editFilename = "__TEMP__" & variables.editFilename>
		<cfset variables.workingCopy = "Yes">
	</cfif>
	<!--- variables.image was created earlier --->
	<cfset variables.imageHeight = variables.image.getImageInfo().height>
	<cfset variables.imageWidth = variables.image.getImageInfo().width>
	<cfoutput>
	<cfif NOT variables.workingCopy>
		<p>#cffm.ResourceKit.Msg.t61#</p>
		<p><a href="#cffm.cffmFilename#?subdir=#urlEncodedFormat(variables.subdir)#"><b>#cffm.ResourceKit.Msg.t14#</b></A></p>
	<cfelse>
		<p>Changes are being made to a temporary copy of your original image.  
			<a href="#cffm.cffmFilename#?subdir=#urlEncodedFormat(variables.subdir)#&editFilename=#urlEncodedFormat(variables.editFilename)#&action=commitChanges" id="commitChanges"><b>#cffm.ResourceKit.Msg.t64#</b></A>
			<a href="#cffm.cffmFilename#?subdir=#urlEncodedFormat(variables.subdir)#&editFilename=#urlEncodedFormat(variables.editFilename)#&action=undoChanges" id="undoChanges"><b>#cffm.ResourceKit.Msg.t65#</b></A>
		</p>
	</cfif>
	<p>#cffm.ResourceKit.Msg.t62#:  #variables.imageWidth# x #variables.imageHeight#</p>

	<script language="javascript">
	function rotate(degrees)
	{
		document.frmRotate.rotateDegrees.value = degrees;
		document.frmRotate.submit();
	}
	</script>
	<ul>
	<li>#cffm.ResourceKit.Msg.t63#: 
	<a href="javascript:document.frmFlipVertical.submit()"><img align="absmiddle" border=1 src="#cffm.iconPath#/imgFlipVertical.gif" BORDER=0 ALT="Flip image vertically"></a>&nbsp;
	<a href="javascript:document.frmFlipHorizontal.submit()"><img align="absmiddle" border=1 src="#cffm.iconPath#/imgFlipHorizontal.gif" BORDER=0 ALT="Flip image horizontally"></a>&nbsp;
	<a href="javascript:rotate(90)"><img align="absmiddle" border=1 src="#cffm.iconPath#/imgRotate90.gif" BORDER=0 ALT="Rotate 90 degrees clockwise"></a>&nbsp;
	<a href="javascript:rotate(180)"><img align="absmiddle" border=1 src="#cffm.iconPath#/imgRotate180.gif" BORDER=0 ALT="Rotate 180 degrees"></a>&nbsp;
	<a href="javascript:rotate(270)"><img align="absmiddle" border=1 src="#cffm.iconPath#/imgRotate270.gif" BORDER=0 ALT="Rotate 90 degrees counter-clockwise"></a>

	<form name="frmFlipVertical" method="post" action="#cffm.cffmFilename#">
	<input type="hidden" name="subdir" value="#variables.subdir#">
	<input type="hidden" name="editFilename" value="#variables.editFilename#">
	<input type="hidden" name="action" value="flip">
	</form>

	<form name="frmFlipHorizontal" method="post" action="#cffm.cffmFilename#">
	<input type="hidden" name="subdir" value="#variables.subdir#">
	<input type="hidden" name="editFilename" value="#variables.editFilename#">
	<input type="hidden" name="action" value="flop">
	</form>
	
	<form name="frmRotate" method="post" action="#cffm.cffmFilename#">
	<input type="hidden" name="subdir" value="#variables.subdir#">
	<input type="hidden" name="editFilename" value="#variables.editFilename#">
	<input type="hidden" name="action" value="rotate">
	<input type="hidden" name="rotateDegrees" value="90">
	</form>

	<form name="frmScaleWidth" method="post" action="#cffm.cffmFilename#">
	<input type="hidden" name="subdir" value="#variables.subdir#">
	<input type="hidden" name="editFilename" value="#variables.editFilename#">
	<input type="hidden" name="action" value="resize">
	<li>#cffm.resourceKit.Msg.t5#
	<input type="text" size="4" maxlength="4" name="resizeWidthValue" value="0"> #cffm.resourceKit.Msg.t6#.
	<input type="hidden" name="resizeHeightvalue" value="0">
	<input type="submit" class="button" value="#cffm.resourceKit.buttonText.t3#">
	</form>

	<form name="frmScaleHeight" method="post" action="#cffm.cffmFilename#">
	<input type="hidden" name="subdir" value="#variables.subdir#">
	<input type="hidden" name="editFilename" value="#variables.editFilename#">
	<input type="hidden" name="action" value="resize">
	<li>#cffm.resourceKit.Msg.t9#
	<input type="text" size="4" maxlength="4" name="resizeHeightValue" value="0"> #cffm.resourceKit.Msg.t6#.
	<input type="hidden" name="resizeWidthvalue" value="0">
	<input type="submit" class="button" value="#cffm.resourceKit.buttonText.t3#">
	</form>

	<form name="frmResize" method="post" action="#cffm.cffmFilename#">
	<input type="hidden" name="subdir" value="#variables.subdir#">
	<input type="hidden" name="editFilename" value="#variables.editFilename#">
	<input type="hidden" name="action" value="resize">
	<li>#cffm.resourceKit.Msg.t10#
	<input type="text" size="4" maxlength="4" name="resizeWidthValue" value="0"> #cffm.resourceKit.Msg.t7#
	<input type="text" size="4" maxlength="4" name="resizeHeightValue" value="0"> #cffm.resourceKit.Msg.t8#.
	<input type="submit" class="button" value="#cffm.resourceKit.buttonText.t3#"><br>
	<input type="checkbox" name="preserveAspect" value="1" onclick="if(this.checked){document.getElementById('cropToExact').style.display='inline'}else{document.getElementById('cropToExact').style.display='none'}">
	#cffm.resourceKit.Msg.t57#
	<span id="cropToExact" style="display: none;">
	<input type="checkbox" name="cropToExact" value="1">
	#cffm.resourceKit.Msg.t58#</span>
	</form>

	<form name="frmCrop" method="post" action="#cffm.cffmFilename#">
	<input type="hidden" name="subdir" value="#variables.subdir#">
	<input type="hidden" name="editFilename" value="#variables.editFilename#">
	<input type="hidden" name="action" value="crop">
	<li>#cffm.resourceKit.Msg.t59#
	<input type="text" size="4" maxlength="4" name="cropStartX" value="0"> x
	<input type="text" size="4" maxlength="4" name="cropStartY" value="0">.<br/>
	#cffm.resourceKit.Msg.t60#
	<input type="text" size="4" maxlength="4" name="cropWidthValue" value="0"> x
	<input type="text" size="4" maxlength="4" name="cropHeightValue" value="0">.
	<input type="submit" class="button" value="#cffm.resourceKit.buttonText.t3#">
	</form>

	</ul>

	<cfif variables.imageWidth gt 400>
		<cfset variables.scale = 400 / variables.imageWidth>
		<cfset variables.displaywidth = 400>
		<cfset variables.displayHeight = Round(variables.imageHeight * variables.scale)>
	<cfelse>
		<cfset variables.scale = 1>
		<cfset variables.displayWidth = variables.imageWidth>
		<cfset variables.displayHeight = variables.imageHeight>
	</cfif>
	<cfif variables.scale lt 1>
		<p>#cffm.resourceKit.Msg.t11# #NumberFormat(variables.scale*100,"__")# #cffm.resourceKit.Msg.t12#.  <a target="_blank" href="#variables.workingDirectoryWeb#/#variables.editFilename#">#cffm.resourceKit.Msg.t13#.</a></p>
	</cfif>
	<p><img src="#variables.workingDirectoryWeb#/#editFilename#?x=#RandRange(1,50000)#" borer=5 width="#variables.displayWidth#" height="#variables.displayHeight#"></p>
	</cfoutput>

<cfelseif action eq "renameForm">
	<cfoutput>
	<a href="#cffm.cffmFilename#?subdir=#urlEncodedFormat(variables.subdir)#"><b>#cffm.ResourceKit.Msg.t14#</b></A><p>

	<form name="frmRename" method="post" action="#cffm.cffmFilename#">
	<input type="hidden" name="action" value="rename">
	<input type="hidden" name="subdir" value="#variables.subdir#">
	<input type="hidden" name="renameOldFilename" value="#editFilename#">
	
	<input type="text" size="40" maxlength="200" name="renameNewFilename" value="#editFilename#">
	<input type="submit" class="button" value="#cffm.resourceKit.buttonText.t4#">
	<br><input type="checkbox" name="overWrite" value="true"<cfif cffm.overwriteDefault> CHECKED</cfif>> #cffm.resourceKit.Msg.t15#.
	</form>
	</cfoutput>

<cfelseif action eq "uploadForm">
	<cfoutput>
		<a href="#cffm.cffmFilename#?subdir=#urlEncodedFormat(variables.subdir)#"><b>#cffm.ResourceKit.Msg.t14#</b></A>
		<p>
	</cfoutput>

	<form name="frmUpload" enctype="multipart/form-data" method="post" action="<cfoutput>#cffm.cffmFilename#</cfoutput>">
	<input type="hidden" name="action" value="upload">
	<input type="hidden" name="subdir" value="<cfoutput>#variables.subdir#</cfoutput>">
	
	<P><cfoutput>#cffm.resourceKit.Msg.t16#</cfoutput>:</p>
	<cfloop from="1" to="20" index="cnt" step="2">
	<input type="file" name="uploadFile<cfoutput>#cnt#</cfoutput>">
	<input type="file" name="uploadFile<cfoutput>#cnt+1#</cfoutput>"><br>
	</cfloop>
	<br>
	<input type="submit" class="button" value="<cfoutput>#cffm.resourceKit.buttonText.t5#</cfoutput>">
	<input type="checkbox" value="true" name="overwrite"<cfif cffm.overwriteDefault> CHECKED</cfif>>overwrite&nbsp;existing
	</form>

<cfelseif action eq "copymoveForm">
	<cfoutput>
	<a href="#cffm.cffmFilename#?subdir=#urlEncodedFormat(variables.subdir)#"><b>#cffm.ResourceKit.Msg.t14#</b></A><p>
	<cfset variables.workingFileType = cffm.getPathType(cffm.createServerPath(variables.subdir,variables.editFilename))>

	<form name="frmCopyMove" method="post" action="#cffm.cffmFilename#">
	<input type="hidden" name="subdir" value="#variables.subdir#">
	<input type="hidden" name="moveFilename" value="#variables.editFilename#">
	<input type="radio" name="action" value="move" checked>move
	<input type="radio" name="action" value="copy">copy to:
	<cfset options = 0>
	<select name="moveToSubdir" size="1">
		<cfif variables.subdir neq "">
			<cfset options = options + 1>
			<option value="">#cffm.resourceKit.Msg.t27#</option>
		</cfif>
		<cfloop query="variables.listAllDirectories">
			<cfset webPath = Replace(ReplaceNoCase(fullPath,cffm.includeDir & variables.dirSep,"","ALL"),"\","/","all")>
			<cfset compare = variables.subdir & iif(len(subdir) gt 0,DE("/"),DE("")) & variables.editFilename>
			<cfif findNoCase(compare, webpath) neq 1>
				<Cfset options = options + 1>
				<option value="#webPath#">#cffm.createWebPath(webPath)#</option>
			</cfif>
		</cfloop>
	</select>
	<cfif options neq 0>
		<input type="submit" class="button" value="#cffm.resourceKit.buttonText.t3#">
	<cfelse>
		<input type="button" class="button" value="#cffm.resourceKit.buttonText.t2#" onClick="history.go(-1);">
		#cffm.resourceKit.Msg.t17#
	</cfif>
	<br>
	<input type="checkbox" name="overWrite" value="true"<cfif cffm.overwriteDefault> CHECKED</cfif>> #cffm.resourceKit.Msg.t15#.
	</form>
	</cfoutput>
<cfelseif action eq "viewzip">
	<cfoutput><a href="#cffm.cffmFilename#?subdir=#urlEncodedFormat(variables.subdir)#"><b>#cffm.ResourceKit.Msg.t14#</b></A><p></cfoutput>
	<form method="post" action="<cfoutput>#cffm.cffmFilename#</cfoutput>">
	<input type="hidden" name="action" value="unzip">
	<input type="hidden" name="subdir" value="<cfoutput>#variables.subdir#</cfoutput>">
	<input type="hidden" name="unzipFilename" value="<cfoutput>#editFilename#</cfoutput>">
	Unzip to: 
<select name="unzipToSubdir" size="1">
<cfoutput>
<option value="#variables.subdir#">#cffm.resourceKit.Msg.t1# (#cffm.createWebPath(variables.subdir)#)</option>
<cfif variables.subdir neq ""><option value="">#cffm.resourceKit.Msg.t27# (#cffm.includeDirWeb#)</option></cfif>
<cfloop query="variables.listAllDirectories">
<cfset webPath = Replace(ReplaceNoCase(fullPath,cffm.includeDir & variables.dirSep,"","ALL"),"\",variables.dirsep,"all")>
<cfif webpath neq variables.subdir>
	<option value="#webPath#">#cffm.createWebPath(webPath)#</option>
</cfif>
</cfloop>
</cfoutput>
</select>
<cfoutput>
<input type="submit" class="button" value="#cffm.resourceKit.buttonText.t6#"> <input type="checkbox" value="true" name="overwrite"<cfif cffm.overwriteDefault> CHECKED</cfif>>#cffm.resourceKit.Msg.t15#
</cfoutput>
</form>
<cfif cffm.allowedExtensions neq "">
	<p><cfoutput><b>#cffm.resourceKit.Msg.t18#</b>:  #cffm.resourceKit.Msg.t20#</cfoutput>
	<ul>
	<cfloop list="#cffm.allowedExtensions#" index="thisExt">
		<li><cfoutput>#thisExt#</cfoutput></li>
	</cfloop>
	</ul>
	</p>
<cfelseif cffm.disallowedExtensions neq "">
	<cfoutput><p><B>#cffm.resourceKit.Msg.t18#</B>:  #cffm.resourceKit.Msg.t21#</p></cfoutput>
</cfif>
<cfset variables.viewzipResults = cffm.viewZipFile(cffm.createServerPath(variables.subdir,variables.editFilename))>
<table class="zipcontents">
<cfoutput>
<tr class="headrow">
	<td>#cffm.resourceKit.Msg.t22#</td>
	<td>#cffm.resourceKit.Msg.t23#</td>
	<td>#cffm.resourceKit.Msg.t24#</td>
</tr>
</cfoutput>
<cfoutput query="variables.viewzipResults">
<tr>
	<td>#name#</td>
	<td>#type#</td>
	<td>#size#</td>
</tr>
</cfoutput>
</table>

<cfelseif action eq "list">
<cfdirectory action="LIST" directory="#variables.workingDirectory#" name="variables.dirList">

<script language="javascript">
function preview(fileUrl) 
{
if (fileUrl == "") {
	alert('Nothing to preview');
} else {
	if (fileUrl.indexOf('/') != 0)
	{
		fileUrl = '/' + fileUrl;
	}
	fileUrl = "file://" + fileUrl;
	newWindow = window.open(fileUrl,"","width=300,height=300,left=20,top=20,bgcolor=white,resizable,scrollbars");
	if ( newWindow != null )
	{
		newWindow.focus();
	}
}
}
</script>
<cfif not cffm.readOnly>
<table>
<tr>
<form name="frmUpload" enctype="multipart/form-data" method="post" action="<cfoutput>#cffm.cffmFilename#</cfoutput>">
<input type="hidden" name="action" value="upload">
<input type="hidden" name="subdir" value="<cfoutput>#variables.subdir#</cfoutput>">
<td width=50%>
<fieldset>
<legend><cfoutput>#cffm.resourceKit.Msg.t41#</cfoutput></legend>
<input type="file" name="uploadFile1"><input type="submit" class="button" value="<cfoutput>#cffm.resourceKit.buttonText.t5#</cfoutput>">
<input type="checkbox" value="true" name="overwrite"<cfif cffm.overwriteDefault> CHECKED</cfif>>overwrite&nbsp;existing<br>
<cfif cffm.allowMultipleUploads>
<cfoutput><a href="#cffm.cffmFilename#?subdir=#urlEncodedFormat(subdir)#&action=uploadForm">#cffm.resourceKit.Msg.t25#</a></cfoutput></cfif>
<!---<input type="button" class="button" value="Preview" onClick="preview(document.frmUpload.uploadFile.value);">--->
</fieldset>
</td>
</form>
<form name="frmCreateNew" method="post" action="<cfoutput>#cffm.cffmFilename#</cfoutput>">
<td width=50%>
<input type="hidden" name="action" value="create">
<input type="hidden" name="subdir" value="<cfoutput>#variables.subdir#</cfoutput>">
<input type="hidden" name="createNewFileType" value="">
<fieldset>
<legend><cfoutput>#cffm.resourceKit.Msg.t26#</cfoutput> </legend>
<input type="text" size="20" name="createNewFilename" onFocus="select();"><br>
<input type="submit" class="button" value="<cfoutput>#cffm.resourceKit.buttonText.t7#</cfoutput>" onClick="document.frmCreateNew.createNewFileType.value='file';">
<cfif cffm.allowCreateDirectory><input type="submit" class="button" value="<cfoutput>#cffm.resourceKit.buttonText.t8#</cfoutput>" onClick="document.frmCreateNew.createNewFileType.value='directory';"></a></cfif>
</fieldset>
</td>
</form>
</tr></table>
</cfif>
<div class="cffmDirectoryLinks">
<cfoutput>
<a href="#cffm.cffmFilename#?subdir="><b>#cffm.resourceKit.Msg.t27#</b></a></li>&nbsp; | &nbsp;
<a href="#cffm.cffmFilename#?subdir=#variables.subdir#"><b>#cffm.resourceKit.Msg.t28#</b></a></li>
</cfoutput>
</div>
<table width=100% class="cffm_filelist">
<cfoutput>
<tr>
	<th colspan="2" width=100%>#cffm.resourceKit.Msg.t22#</th>
	<th>#cffm.resourceKit.Msg.t24#</th>
	<th>#cffm.resourceKit.Msg.t29#</th>
	<th>#cffm.resourceKit.Msg.t30#</th>
</tr>
</cfoutput>
<cfif variables.subdir neq "">
<!--- include link to parent directory --->
<cfset variables.linkToFile = cffm.cffmFilename & "?subdir=" & ListDeleteAt(variables.subdir,listlen(variables.subdir,"/"),"/")>
<cfoutput><tr>
<td><a href="<cfoutput>#variables.linkToFile#</cfoutput>" target="_self"><img src="<cfoutput>#cffm.iconPath#/</cfoutput>folder_up.gif" border="0"></a></td>
<td width="100%">
	<cfoutput><a href="#variables.linkToFile#" target="_self">#cffm.resourceKit.Msg.t31#</a></cfoutput>
</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
</tr>
</cfoutput>
</cfif>
<cfset cnt = 0>
<cfset variables.totalDirectories = 0>
<cfset variables.totalFiles = 0>
<cfset variables.totalSize = 0>
<cfquery name="sortedDirList" dbtype="query">
	select *, lower(name) as sortname
	from variables.dirlist
	order by type, sortname
</cfquery>
<cfoutput query="variables.sortedDirList">
<cfsilent>
<cfset cnt = cnt + 1>
<cfset variables.dimensionCount = 0>
<cfscript>
variables.editable = 0;
variables.zipFile = 0;
variables.editableImage = 0;
variables.fileIcon = "spacer.gif";
variables.dimensions = "";
variables.previewLink = "";
if (listLen(name,".") gt 1) {
	variables.extension = lcase(listLast(name,"."));
	if (listFind(cffm.editableExtensions, variables.extension) gt 0 and type eq "file") {
		variables.editable = 1;
		variables.fileIcon = "documenticon.gif";
	} else if (listFind("zip",variables.extension) gt 0) {
		variables.zipFile = 1;
	}
} else {
	variables.extension = "";
	variables.editable = 0;
}
if (type eq "dir") {
	variables.totalDirectories = variables.totalDirectories + 1;
	variables.fileIcon = "folder_closed.gif";
	variables.linkTarget = "_self";
	variables.linkToFile = cffm.cffmFilename & "?subdir=";
	if (variables.subdir eq "") {
		variables.linkToFile = variables.linkToFile & name;
	} else {
		variables.linkToFile = variables.linkToFile & variables.subdir & "/" & name;
	}
} else {
	variables.totalFiles = variables.totalFiles + 1;
	variables.totalSize = variables.totalSize + size;
	if (listFind("gif,jpg,png",variables.extension) gt 0)
	{
		variables.previewLink = "#variables.workingDirectoryWeb#/#name#"; 
		variables.fileIcon = "imgicon.gif";
		if (variables.extension eq "jpg" or variables.extension eq "png")
		{
			variables.editableImage = 1;
		}
		if (cffm.enableImageDimensionsInDirList AND variables.dimensionCount lt cffm.maxImageDimensionsPerFileListing)
		{
			variables.DimensionCount = variables.DimensionCount + 1;
			if (NOT isDefined("variables.image")) {
				variables.image = createObject("component","ImageObject");
			}
			try
			{
				variables.image.init(cffm.createServerPath(variables.subdir,name));
				variables.dimensions = variables.image.getImageInfo().width & "x" & variables.image.getImageInfo().height;
			} catch(Any e) {
				// next line is for debugging 
				// cffmdump(e);
				// image won't be editable, but for now
				// let's leave the manipulate link.  To remove
				// it, uncomment the following line:
				// variables.editableImage = 0;
			}
		}
	}
	variables.previewTarget = "_blank";
	variables.previewLink = "#variables.workingDirectoryWeb#/#name#";
	if (variables.editorType eq "")
	{
		// editorType is empty when CFFM is being used as a plain ol' file manager.
		variables.linkTarget = "_blank";
		variables.linkToFile = "#variables.workingDirectoryWeb#/#name#";
	} else {
		// editor type is "fck" or "mce" or something so we should perform some action when
		// a file is clicked on.
		variables.linkTarget = "_self";
		if ( variables.EDITOR_RESOURCE_TYPE eq "image" AND listFindNoCase("jpg,gif,png",extension) eq 0 )
		{
			// we can only perform the action if the file is an image.
			variables.linkToFile="javascript:alert('#cffm.resourceKit.Msg.t32#.');";
		} else if ( variables.EDITOR_RESOURCE_TYPE eq "flash" AND lcase(extension) neq "swf") {
			// we can only perform the action if the file is a flash document.
			variables.linkToFile="javascript:alert('Sorry, but this file is not a Flash document.  Flash documents have a .SWF extension.');";
		} else {
			// we're inserting a link to a file, so any file would be fine.
			variables.linkToFile = "#variables.workingDirectoryWeb#/#name#";
			variables.linkToFile = Replace(variables.linkToFile,"'","\'","ALL");
			variables.linkToFile = "javascript:OpenFile('#variables.linkToFile#');";
		}
	}
}</cfscript>
</cfsilent>
<tr>
<td><a href="#variables.linkToFile#" target="#variables.linkTarget#"><img src="#cffm.iconPath#/#variables.fileIcon#" border="0"></a></td>
<td width="100%">
	<a href="#variables.linkToFile#" target="#variables.linkTarget#">#name#</a><cfif type eq "file">&nbsp;<a class="previewLink" href="#cffm.cffmFilename#?action=download&subdir=#urlEncodedFormat(subdir)#&downloadFilename=#urlEncodedFormat(name)#">[#cffm.resourceKit.Msg.t47#]</a></cfif><cfif variables.editorType neq "" AND variables.previewLink neq "">&nbsp;<a class="previewLink" target=_blank href="#variables.previewLink#">[#cffm.resourceKit.Msg.t48#]</a></cfif>
</td>
<td><cfif size lt 10000>#size#&nbsp;bytes<cfelseif size lt 1000000>#round(size/1024)#&nbsp;KB<cfelse>#round(size/1024/1024)#&nbsp;MB</cfif><cfif variables.dimensions neq ""><br>#variables.dimensions#</cfif></td>
<td nowrap>#replace(dateFormat(dateLastModified,"yyyy-mm-dd") & " " & TimeFormat(dateLastModified,"HH:mm:00")," ","&nbsp;","ALL")#</td>
<td class="actionLinks">
	<cfif not cffm.readOnly><a href="javascript:if(confirm('Delete #cffm.getPathType(cffm.createServerPath(variables.subdir,name))# \'#replace(name,"'","\'","ALL")#\'?')){window.location.href='#cffm.cffmFilename#?action=delete&subdir=' + escape('#replace(variables.subdir,"'","\'","ALL")#') +'&deleteFilename=' + escape('#replace(name,"'","\'","ALL")#');}">#cffm.resourceKit.Msg.t50#</a>&nbsp;<a href="#cffm.cffmFilename#?action=renameForm&subdir=#urlEncodedFormat(variables.subdir)#&editFilename=#urlEncodedFormat(name)#">#cffm.resourceKit.Msg.t51#</a>&nbsp;<a href="#cffm.cffmFilename#?action=copymoveForm&subdir=#UrlEncodedFormat(variables.subdir)#&editFilename=#urlEncodedFormat(name)#">#cffm.resourceKit.Msg.t52#</a>&nbsp;<cfif variables.editable eq 1><a href="#cffm.cffmFilename#?action=edit&subdir=#urlEncodedFormat(variables.subdir)#&editFilename=#urlEncodedFormat(name)#">#cffm.resourceKit.Msg.t53#</a>&nbsp;</cfif></cfif><cfif variables.editable eq 1><a href="#cffm.cffmFilename#?action=viewSource&subdir=#urlEncodedFormat(variables.subdir)#&editFilename=#urlEncodedFormat(name)#">#cffm.resourceKit.Msg.t54#</a>&nbsp;</cfif><cfif not cffm.readOnly and cffm.allowUnzip and variables.zipfile eq 1><a href="#cffm.cffmFilename#?action=viewzip&subdir=#urlEncodedFormat(variables.subdir)#&editFilename=#urlEncodedFormat(name)#">#cffm.resourceKit.Msg.t55#</a>&nbsp;</cfif><cfif not cffm.readOnly and variables.editableImage><a href="#cffm.cffmFilename#?action=manipulateForm&subdir=#urlEncodedFormat(variables.subdir)#&editFilename=#urlEncodedFormat(name)#">#cffm.resourceKit.Msg.t56#</a>&nbsp;</cfif>
</td>
</tr>
</cfoutput>
</table>
<cfsetting enablecfoutputonly="yes">
<cfoutput>
#cffm.resourceKit.Msg.t33# #variables.totalDirectories# <cfif variables.totalDirectories IS 1>#cffm.resourceKit.Msg.t34#<cfelse>#cffm.resourceKit.Msg.t35#</cfif> 
#cffm.resourceKit.Msg.t36# #variables.totalFiles# <cfif variables.totalFiles eq 1>#cffm.resourceKit.Msg.t37#<cfelse>#cffm.resourceKit.Msg.t38#</cfif>.<br>
#cffm.resourceKit.Msg.t39# #NumberFormat(variables.totalSize,"_,___")# bytes.
</cfoutput>
<cfif variables.showTotalUsage eq 1>
	<cfset variables.metadata = cffm.getDirectoryMetadata(variables.listAllFiles)>
	<cfoutput>#cffm.resourceKit.Msg.t40#:  #variables.metadata.totalSize# bytes</cfoutput>
<cfelse>
	<cfoutput><a href="#cffm.cffmFilename#?subdir=#variables.subdir#&showTotalUsage=1">#cffm.resourceKit.Msg.t45#</a></cfoutput>
</cfif>

</cfif>

<cfoutput>
<p>
#cffm.resourceKit.Msg.t46# <a href="http://www.webworksllc.com/cffm">CFFM v.#cffm.version#</A></p>
</cfoutput>
<cfif cffm.templateWrapperBelow neq "">
	<cfsetting enablecfoutputonly="no">
	<CFINCLUDE TEMPLATE="#cffm.templateWrapperBelow#">
<cfelse>
	<cfoutput></BODY></HTML></cfoutput>
</cfif>
