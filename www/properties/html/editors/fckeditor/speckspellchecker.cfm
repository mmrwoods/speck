<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<!---
This code uses a CF User Defined Function and should work in CF version 5.0
and up without alteration.

Also if you are hosting your site at an ISP, you will have to check with them
to see if the use of <CFEXECUTE> is allowed. In most cases ISP will not allow
the use of that tag for security reasons. Clients would be able to access each
others files in certain cases.
--->

<!---
Updated by Mark Woods - 17 April 2008
* Added support for UNIX OSes (assumes that cf can execute sh with -c option).
* Automatically determine Aspell language from CF locale.
* Upadated code so it should work in CF5 (previous code would not have worked 
with CF5 because it doesn't support UTF8 and the charset attribute of cffile 
was only introduced in CF6, it makes CF5 throw up into a champagne glass - classy!)

Possible TODO: update the windows command so it doesn't pipe the output from 
type into aspell. I don't have a windows machine to test on today though. 
Question to previous author - was type used to ensure UTF8 encoding isn't lost?
--->

<cflock type="readonly" scope="server" timeout="3" throwontimeout="true">
<cfset osName = server.os.name>
<cfset cfMajorVersion = listFirst(server.coldFusion.productVersion,",.")>
</cflock>

<cfscript>
	// set paths to the aspell executable
	windows_executable = "C:\Program Files\Aspell\bin\aspell.exe";
	unix_executable = "aspell";
	
	// what encoding do we use (utf-8 where possible)
	if ( cfMajorVersion gte 6 ) {
		encoding = "utf-8";
	} else {
		encoding = "iso8859-1";
	}
	
	// get aspell language from cf locale
	// note: I'm assuming that the java locale can be used as the aspell language as long as relevant dictionary installed
	cfLocale = getLocale();
	if ( len(cfLocale) eq 2 ) {
		// we just have a language code, that'll do grand
		aspell_lang = cfLocale;
	} else if ( reFind("^[a-zA-Z]{2}_[a-zA-Z]{2}",cfLocale) ) {
		// java locale, remove any variant info from the locale, we just want the language and country codes
		aspell_lang = left(cfLocale,5);
	} else {
		// old skool cf locale from CF6.1 or before (e.g. English (UK)) - convert to jvm locale
		stJavaLocales = structNew();
		stJavaLocales.zh_CH = "Chinese (China)";
		stJavaLocales.zh_HK = "Chinese (Hong Kong)";
		stJavaLocales.zh_TW = "Chinese (Taiwan)";
		stJavaLocales.nl_BE = "Dutch (Belgian)";
		stJavaLocales.nl_NL = "Dutch (Standard)";
		stJavaLocales.en_AU = "English (Australian)";
		stJavaLocales.en_CA = "English (Canadian)";
		stJavaLocales.en_NZ = "English (New Zealand)";
		stJavaLocales.en_GB = "English (UK)";
		stJavaLocales.en_US = "English (US)";
		stJavaLocales.fr_BE = "French (Belgian)";
		stJavaLocales.fr_CA = "French (Canadian)";
		stJavaLocales.fr_FR = "French (Standard)"; 
		stJavaLocales.fr_CH = "French (Swiss)";
		stJavaLocales.de_AT = "German (Austrian)";
		stJavaLocales.de_DE = "German (Standard)";
		stJavaLocales.de_CH = "German (Swiss)";
		stJavaLocales.it_IT = "Italian (Standard)";
		stJavaLocales.it_CH = "Italian (Standard)";
		stJavaLocales.ja_JP = "Japanese";
		stJavaLocales.ko_KR = "Korean";
		stJavaLocales.no_NO = "Norwegian (Bokmal)";
		stJavaLocales.no_NO = "Norwegian (Nynorsk)";
		stJavaLocales.pt_BR = "Portuguese (Brazilian)";
		stJavaLocales.pt_PT = "Portuguese (Standard)";
		stJavaLocales.es_MX = "Spanish (Mexican)";
		stJavaLocales.es_ES = "Spanish (Modern)";
		stJavaLocales.es_ES = "Spanish (Standard)";
		stJavaLocales.sv_SE = "Swedish";
		
		aKeys = structFindValue(stJavaLocales,cfLocale);
		if ( arrayIsEmpty(aKeys) ) {
			aspell_lang = "en_US";
		} else {
			aspell_lang = aKeys[1]["key"];
			aspell_lang = lCase(left(aspell_lang,2)) & "_" & uCase(right(aspell_lang,2));
		}
	}
</cfscript>

<cfset aspell_opts  = "-a --lang=#aspell_lang# --encoding=#encoding# -H --rem-sgml-check=alt">
<cfset tempfile_in  = GetTempFile(GetTempDirectory(), "spell_")>
<cfset tempfile_out = GetTempFile(GetTempDirectory(), "spell_")>
<cfset spellercss   = "/speck/properties/html/editors/fckeditor/editor/dialog/fck_spellerpages/spellerpages/spellerStyle.css">
<cfset word_win_src = "/speck/properties/html/editors/fckeditor/editor/dialog/fck_spellerpages/spellerpages/wordWindow.js">

<cfset form.checktext = form["textinputs[]"]>

<!--- make no difference between URL and FORM scopes --->
<cfparam name="url.checktext"  default="">
<cfparam name="form.checktext" default="#url.checktext#">

<!--- Takes care of those pesky smart quotes from MS apps, replaces them with regular quotes --->
<cfset submitted_text = ReplaceList(form.checktext,"%u201C,%u201D","%22,%22")>

<!--- submitted_text now is ready for processing --->

<!--- use carat on each line to escape possible aspell commands --->
<cfset text = "">
<cfset CRLF = Chr(13) & Chr(10)>

<cfloop list="#submitted_text#" index="field" delimiters=",">
	<cfset text = text & "%"  & CRLF
                      & "^A" & CRLF
                      & "!"  & CRLF>
	<!--- Strip all tags for the text. (by FredCK - #339 / #681) --->
	<cfset field = REReplace(URLDecode(field), "<[^>]+>", " ", "all")>
	<cfloop list="#field#" index="line" delimiters="#CRLF#">
		<cfset text = ListAppend(text, "^" & Trim(JSStringFormat(line)), CRLF)>
	</cfloop>
</cfloop>

<!--- create temp file from the submitted text, this will be passed to aspell to be check for misspelled words --->
<cftry>
	<!--- cfmx --->
	<cffile action="write" file="#tempfile_in#" output="#text#" charset="utf-8">
<cfcatch>
	<!--- cf5 --->
	<cffile action="write" file="#tempfile_in#" output="#text#">
</cfcatch>
</cftry>


<!--- execute aspell in an UTF-8 console and redirect output to a file --->
<cfif findNoCase("windows",osName)>
		
	<cfexecute name="cmd.exe" arguments='/c type "#tempfile_in#" | "#windows_executable#" #aspell_opts# > "#tempfile_out#"' timeout="3"></cfexecute>

<cfelse>

	<cfexecute name="sh" arguments='-c "#unix_executable# #aspell_opts# < #tempfile_in# > #tempfile_out#"' timeout="3"></cfexecute>
	
</cfif>

<!--- read output file for further processing --->
<cftry>
	<!--- cfmx --->
	<cffile action="read" file="#tempfile_out#" variable="food" charset="utf-8">
<cfcatch>
	<!--- cf5 --->
	<cffile action="read" file="#tempfile_out#" variable="food">
</cfcatch>
</cftry>

<!--- remove temp files --->
<cffile action="delete" file="#tempfile_in#">
<cffile action="delete" file="#tempfile_out#">

<cfset texts = StructNew()>
<cfset texts.textinputs = "">
<cfset texts.words      = "">
<cfset texts.abort      = "">

<!--- Generate Text Inputs --->
<cfset i = 0>
<cfloop list="#submitted_text#" index="textinput">
  <cfset texts.textinputs = ListAppend(texts.textinputs, 'textinputs[#i#] = decodeURIComponent("#textinput#");', CRLF)>
  <cfset i = i + 1>
</cfloop>

<!--- Generate Words Lists --->
<cfset word_cnt  = 0>
<cfset input_cnt = -1>
<cfloop list="#food#" index="aspell_line" delimiters="#CRLF#">
    <cfset leftChar = Left(aspell_line, 1)>
	<cfif leftChar eq "*">
			<cfset input_cnt   = input_cnt + 1>
			<cfset word_cnt    = 0>
			<cfset texts.words = ListAppend(texts.words, "words[#input_cnt#] = [];", CRLF)>
			<cfset texts.words = ListAppend(texts.words, "suggs[#input_cnt#] = [];", CRLF)>
    <cfelse>
        <cfif leftChar eq "&" or leftChar eq "##">
			<!--- word that misspelled --->
			<cfset bad_word    = Trim(ListGetAt(aspell_line, 2, " "))>
			<cfset bad_word    = Replace(bad_word, "'", "\'", "ALL")>
			<!--- sugestions --->
			<cfset sug_list    = Trim(ListRest(aspell_line, ":"))>
			<cfset sug_list    = ListQualify(Replace(sug_list, "'", "\'", "ALL"), "'")>
			<!--- javascript --->
			<cfset texts.words = ListAppend(texts.words, "words[#input_cnt#][#word_cnt#] = '#bad_word#';", CRLF)>
			<cfset texts.words = ListAppend(texts.words, "suggs[#input_cnt#][#word_cnt#] = [#sug_list#];", CRLF)>
			<cfset word_cnt    = word_cnt + 1>
		</cfif>
     </cfif>
</cfloop>

<cfif texts.words eq "">
  <cfset texts.abort = "alert('Spell check complete.\n\nNo misspellings found.');">
</cfif>

<cfcontent type="text/html; charset=#encoding#">

<cfoutput><html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=#encoding#">
<link rel="stylesheet" type="text/css" href="#spellercss#" />
<script language="javascript" src="#word_win_src#"></script>
<script language="javascript">
var suggs      = new Array();
var words      = new Array();
var textinputs = new Array();
var error;

#texts.textinputs##CRLF#
#texts.words#
#texts.abort#

var wordWindowObj = new wordWindow();
wordWindowObj.originalSpellings = words;
wordWindowObj.suggestions = suggs;
wordWindowObj.textInputs = textinputs;

function init_spell() {
	// check if any error occured during server-side processing
	if( error ) {
		alert( error );
	} else {
		// call the init_spell() function in the parent frameset
		if (parent.frames.length) {
			parent.init_spell( wordWindowObj );
		} else {
			alert('This page was loaded outside of a frameset. It might not display properly');
		}
	}
}
</script>

</head>
<body onLoad="init_spell();">

<script type="text/javascript">
wordWindowObj.writeBody();
</script>

</body>
</html></cfoutput>
<cfsetting enablecfoutputonly="false">
