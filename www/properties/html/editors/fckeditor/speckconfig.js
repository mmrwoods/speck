// Default FCKeditor configuration file for Speck.
// The Html property sets CustomConfigurationsPath to use this config file by default

/* 
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
*/

FCKConfig.ToolbarSets["Default"] = [
	['Paste','PasteText','PasteWord','-','SpellCheck','-','Table','Link','Unlink','Anchor','Image','-','OrderedList','UnorderedList','-','SpecialChar','-','Rule','-','ShowBlocks','Source'],
	['FontFormat','Style','RemoveFormat','Bold','Italic','Underline','StrikeThrough','Blockquote']
] ;

FCKConfig.ToolbarSets["Basic"] = [
	['PasteText','-','SpellCheck','-','Bold','Italic','Underline','StrikeThrough','-','Subscript','Superscript','-','OrderedList','UnorderedList','-','Link','Unlink','Image','SpecialChar','-','Source']
] ;

FCKConfig.ToolbarSets["Minimal"] = [
	['PasteText','-','SpellCheck','-','Bold','Italic','-','Subscript','Superscript','-','OrderedList','UnorderedList','-','Link','Unlink','Anchor','Image','SpecialChar','-','ShowBlocks','Source']
] ;

// FCKConfig.ImageBrowser = false;
FCKConfig.LinkBrowser = false;
FCKConfig.FlashBrowser = false;
FCKConfig.LinkUpload = false;
FCKConfig.ImageUpload = false;
FCKConfig.FlashUpload = false;

FCKConfig.AutoDetectLanguage = false;
FCKConfig.DefaultLanguage = 'en';
FCKConfig.ContentLangDirection = 'ltr';

FCKConfig.ProcessHTMLEntities = false;
FCKConfig.ForceStrongEm = true;
FCKConfig.GeckoUseSPAN = false;

FCKConfig.IgnoreEmptyParagraphValue = true;

FCKConfig.ForcePasteAsPlainText = false;
FCKConfig.AutoDetectPasteFromWord = false;
FCKConfig.CleanWordKeepsStructure = true;

FCKConfig.FirefoxSpellChecker = true;
FCKConfig.SpellChecker = 'ieSpell'; // set to SpellerPages if Aspell installed on server

FCKConfig.FillEmptyBlocks = true;

FCKConfig.IgnoreEmptyParagraphValue = true;

FCKConfig.FontFormats = "p;pre;address;h1;h2;h3;h4;h5;h6";

FCKConfig.PreserveSessionOnFileBrowser = true;

FCKConfig.UseBROnCarriageReturn = true;
FCKConfig.EnterMode = "br";
FCKConfig.ShiftEnterMode = "p";

FCKConfig.CustomStyles = "";

FCKConfig.Keystrokes = [
	[ CTRL + 65 /*A*/, true ],
	[ CTRL + 67 /*C*/, true ],
	[ CTRL + 70 /*F*/, true ],
	[ CTRL + 83 /*S*/, true ],
	[ CTRL + 84 /*T*/, true ],
	[ CTRL + 88 /*X*/, true ],
	[ CTRL + 86 /*V*/, 'PasteText' ],
	[ CTRL + 45 /*INS*/, true ],
	[ SHIFT + 45 /*INS*/, 'PasteText' ],
	[ CTRL + 88 /*X*/, 'Cut' ],
	[ SHIFT + 46 /*DEL*/, 'Cut' ],
	[ CTRL + 90 /*Z*/, 'Undo' ],
	[ CTRL + 89 /*Y*/, 'Redo' ],
	[ CTRL + SHIFT + 90 /*Z*/, 'Redo' ],
	[ CTRL + 76 /*L*/, 'Link' ],
	[ CTRL + 66 /*B*/, 'Bold' ],
	[ CTRL + 73 /*I*/, 'Italic' ],
	[ CTRL + 85 /*U*/, 'Underline' ],
	[ CTRL + SHIFT + 83 /*S*/, 'Save' ],
	[ CTRL + ALT + 13 /*ENTER*/, 'FitWindow' ]
] ;
