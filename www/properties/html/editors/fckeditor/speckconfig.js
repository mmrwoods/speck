// Default FCKeditor configuration file for SpeckCMS

// FCKeditor instances can be custom configured using an fckeditor.cfg config file in <appInstallRoot>/config
// and through the use of a number of cf_spProperty attributes for Html properties. Note that you can also 
// use your own CustomConfigurationsPath FCKeditor setting to override the values in this configuration file, 
// but this should be avoided unless you need to use JavaScript to do the customisation (e.g. to add a toolbar set)

FCKConfig.ToolbarSets["Default"] = [
	['Paste','PasteText','PasteWord','-','SpellCheck','-','Table','Link','Unlink','Anchor','Image','-','OrderedList','UnorderedList','-','SpecialChar','-','Rule','-','ShowBlocks','Source'],
	['FontFormat','Style','RemoveFormat','Bold','Italic','Underline','StrikeThrough','Blockquote']
] ;

FCKConfig.ToolbarSets["Basic"] = [
	['PasteText','-','Bold','Italic','Underline','StrikeThrough','-','Subscript','Superscript','-','OrderedList','UnorderedList','-','Link','Unlink','Image','Rule','SpecialChar','-','Source']
] ;

FCKConfig.ToolbarSets["Minimal"] = [
	['PasteText','-','Bold','Italic','-','OrderedList','UnorderedList','-','Link','Unlink','Image','SpecialChar','-','Source']
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

// FCKConfig.ForcePasteAsPlainText = true;
// FCKConfig.AutoDetectPasteFromWord = true;
FCKConfig.CleanWordKeepsStructure = true;

FCKConfig.FirefoxSpellChecker = true;
FCKConfig.SpellChecker = 'ieSpell'; // set to SpellerPages if Aspell installed on server
FCKConfig.SpellerPagesServerScript = '/speck/properties/html/editors/fckeditor/speckspellchecker.cfm';

FCKConfig.FillEmptyBlocks = true;

FCKConfig.IgnoreEmptyParagraphValue = true;

FCKConfig.FontFormats = "p;pre;address;h1;h2;h3;h4;h5;h6";

FCKConfig.PreserveSessionOnFileBrowser = true;

FCKConfig.UseBROnCarriageReturn = true;
FCKConfig.EnterMode = "br";
FCKConfig.ShiftEnterMode = "p";

FCKConfig.CustomStyles = "";
FCKConfig.StylesXmlPath = "/speck/properties/html/editors/fckeditor/speckstyles.xml";

FCKConfig.TemplatesXmlPath = "/speck/properties/html/editors/fckeditor/specktemplates.xml";

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