﻿/*
 * TODO:
 * Create a separate command rather than override PasteText
 * Replace hard-coded strings with a language file
 * Long term - get rid of the popup where possible (where the clipboard can be accessed)
 */
FCKCommands.RegisterCommand( 'PasteText', new FCKDialogCommand( 
	'Paste Text', 
	'Paste Text', 
	FCKPlugins.Items['pasteclean'].Path + 'paste_clean.html',400,300)
);
