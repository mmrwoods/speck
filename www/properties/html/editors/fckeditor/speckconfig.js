// Default FCKeditor configuration file for SpeckCMS

// FCKeditor instances can be custom configured using an fckeditor.cfg config file in <appInstallRoot>/config
// and through the use of a number of cf_spProperty attributes for Html properties. Note that you can also 
// use your own CustomConfigurationsPath FCKeditor setting to override the values in this configuration file, 
// but this should be avoided unless you need to use JavaScript to do the customisation (e.g. to add a toolbar set)

FCKConfig.ToolbarSets["Default"] = [
	['Cut','Copy','Paste','PasteText','PasteWord','-','Undo','Redo','-','SpellCheck','-','Table','Link','Unlink','Anchor','Image','-','Rule','-','SpecialChar','-','RemoveFormat'],
	['FontFormat','Bold','Italic','Underline','StrikeThrough','-','Subscript','Superscript','-','OrderedList','UnorderedList','-','Source']
] ;

FCKConfig.ToolbarSets["Basic"] = [
	['PasteText','-','Bold','Italic','Underline','StrikeThrough','-','Subscript','Superscript','-','OrderedList','UnorderedList','-','Link','Unlink','Image','Rule','SpecialChar','-','Source']
] ;

FCKConfig.ToolbarSets["Minimal"] = [
	['PasteText','-','Bold','Italic','Underline','StrikeThrough','-','OrderedList','UnorderedList','-','Link','Unlink','SpecialChar']
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
// FCKConfig.SpellChecker = 'SpellerPages';
FCKConfig.SpellerPagesServerScript = '/speck/properties/html/editors/fckeditor/speckspellchecker.cfm';

FCKConfig.FillEmptyBlocks = true;

FCKConfig.IgnoreEmptyParagraphValue = true;

FCKConfig.FontFormats = "p;pre;address;h1;h2;h3;h4;h5;h6";

FCKConfig.PreserveSessionOnFileBrowser = true;

FCKConfig.UseBROnCarriageReturn = true;
FCKConfig.EnterMode = "br";
FCKConfig.ShiftEnterMode = "p";