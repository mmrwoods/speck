<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- Speck utility functions - these end up available in request.speck scope --->

<cfscript>
	
	function buildString(code) {
		var s = "";
		var lParams = "";
		var context = "";
		var i = 1;
		var aParams = "";
		if ( arrayLen(arguments) gt 1 )
			lParams = arguments[2];
		if (isDefined("request.speck.strings.#code#")) {
			s = request.speck.strings[code];
		} else if ( arrayLen(arguments) gt 2 ) {
			context = arguments[3];
			if ( isDefined("context.strings.#code#") )
				s = context.strings[code];
		} 
		if ( len(s) eq 0 ) {
			// cannot find string
			s = code;
			if ( len(lParams) ) {
				s = s & " (" & lParams & ")";
			}
			return s;
		} else {
			// found string, add param values and return
			aParams = listToArray(" " & replace(lParams,",,",", ,","all") & " ");
			for (i=1; i lte arrayLen(aParams); i=i+1) {
				s = replace(s, "%" & i, aParams[i],"all");
			}
			//for (i = 1; i le listLen(lParams); i = i + 1) {
			//	s = replace(s, "%" & i, replace(listGetAt(lParams, i),"&nbsp;"," ","all"),"all");
			//}
			return s;
		}			
	}
	
	function getNextRow() {
		var lCols = caller.attributes.qContent.columnList;
		var col = 0;
		caller.content.spRowNumber = caller.content.spRowNumber + 1;
		while (lCols neq "") {
			col = listFirst(lCols); lCols = listRest(lCols);
			caller.content[col] = trim(caller.attributes.qContent[col][caller.content.spRowNumber]);
		}
	}
	
	function isUUID(id) {
		return REFindNoCase("^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{16}$", trim(id)) eq 1;
	}
	
	function textDDLString(length) {
		
		var context = "";
		if ( arrayLen(arguments) gt 1 ) {
			context = arguments[2];
		} else {
			context = request.speck;
		}
		
		if ( len(context.database.varcharMaxLength) 
			and len(context.database.longvarcharType) 
			and length gt context.database.varcharMaxLength ) {
			
			if ( isDefined("context.database.specifyLongVarcharMaxLength") and context.database.specifyLongVarcharMaxLength ) {
				return context.database.longvarcharType & "(" & length & ")";
			} else {
				return context.database.longvarcharType;
			}		
			
		} else if ( len(context.database.varcharType) )	{
			
			return context.database.varcharType & "(" & length & ")";			
		
		} else {
		
			return "varchar(" & length & ")";
		
		}	
		
	}
	
	function dbConcat(expr1, expr2) { 
		// outputs SQL DML string to concat all expressions passed in the arguments array
		// at least two expressions are required
		// note: arguments are expressions which evaluate to strings, so a plain ol' string value must be qualified using apostrophe
		// example usage:
			// dbConcat("'Item last updated: '", "CAST(spUpdated AS varchar(128)")
			// note the first argument in the example is a qualified string, the other is an expression which evaluates as a string
			// oh, btw, the above will only work in SQL Server and PostgreSQL 'cos neither Oracle or MySQL support CAST (well, AFAIK anyway)
		var output = expr1;
		var i = 1;
		
		if ( len(request.speck.database.concatFunction) ) {
		
			for(i=2; i le arrayLen(arguments); i = i + 1) 
				output = output & " , " & arguments[i];
			output = request.speck.database.concatFunction & "(" & output & ")";
			
		} else {
				
			for(i=2; i le arrayLen(arguments); i = i + 1)
				output = output & " " & request.speck.database.concatOperator & " " & arguments[i];
		}			
			
		return output;			
	}
	
	function dbIdentifier(str) {
		// returns the identifier, quoted if required in whatever characters are used by the dbms
		var context = "";
		if ( isDefined("request.speck.dbtype") ) {
			dbType = request.speck;
		} else if ( arrayLen(arguments) gt 1 ) {
			context = arguments[2];
		}
		if ( isStruct(context) ) {
			if ( listFindNoCase("access,sqlserver",context.dbtype) ) {
				str = "[" & str & "]";
			} // TODO: add code to handle quoted identifers for other dbms
		}
		return str;	
	}
	
	function dbTableNotFound(errorMsg) {
		// we can't rely on the SQLSTATE to determine if the table is not found because 
		// not all database drivers return the ODBC error code S0002 when a table cannot 
		// be found. So, we'll try some crude pattern matching on the error details.
		var context = "";
		var i = 1;
		if ( arrayLen(arguments) gt 1 ) {
			context = arguments[2];
		} else {
			context = request.speck;
		}
		if ( REFindNoCase("(table|relation|object).*(unknown|invalid|not found|doesn't exist|does not exist)",errorMsg)
			or REFindNoCase("(unknown|invalid|cannot find|failed to find).*(table|relation|object)",errorMsg) ) {
			return true;
		} else {
			if ( len(context.database.tableNotFound) ) {
				for(i=1; i le listLen(context.database.tableNotFound); i = i + 1) {
					if ( findNoCase(listGetAt(context.database.tableNotFound,i),errorMsg) )
						return true;
				}
			}
		}
		return false;
	}
	
	function userHasPermission(lRoles) { 
		var lAccessPermissions = lRoles;
		var bAccess = false;
		if (request.speck.session.auth eq "logon" and structKeyExists(request.speck.session, "roles")) {
			while (lAccessPermissions neq "" and not bAccess) {
				permission = listFirst(lAccessPermissions);
				lAccessPermissions = listRest(lAccessPermissions);
				if (structKeyExists(request.speck.session.roles, permission))
					bAccess = true;
			}
		}
		return bAccess;
	}
	
	
	function getTypeTemplate(type) {
		// function to get correct template for type definition, required to handle application and server types
		var fs = request.speck.fs;
		var stType = request.speck.types[type];
		if ( fileExists("#request.speck.appInstallRoot##fs#tags#fs#types#fs##stType.name#.cfm") )			
			return "/#request.speck.mapping#/types/#stType.name#.cfm";
		else
			return "/speck/types/#stType.name#.cfm";		
	}
	
	function getHandlerTemplate(stType,method) {
		// returns path to correct handler template for type methods
		if ( structKeyExists(stType.methods, method) )
			return stType.methods[method];
		else
			return "/speck/types/spDefault.cfm";
	}
			
	function getPropertyHandlerTemplate(stPD,method) {
 		// returns path to correct handler template for property methods
		var fs = request.speck.fs;
		if ( structKeyExists(stPD.methods, method) )
			return stPD.methods[method];
		else if ( fileExists("#request.speck.appInstallRoot##fs#tags#fs#properties#fs##stPD.type#.cfm") )			
			return "/#request.speck.mapping#/properties/#stPD.type#.cfm";
		else
			return  "/speck/properties/" & stPD.type & ".cfm";			
	}
	
	function getMIMEType(extension) {
		// get MIME type - do not pass dot with extension
		if ( structKeyExists(request.speck.mimemap, extension) ) 
			return request.speck.mimemap[extension];
		else
			// unknown extension, default to application/octet-stream
			return "application/octet-stream";
	}
	
	function getRequestedPath() {
		// IIS gives the entire path required to access a script as the value of the path_info CGI env variable, 
		// but the CGI spec says the full path required to access a script should be given by appending the value
		// of the path_info env variable to the script_name env variable, ie. path_info is for extra path information
		// note: no querystring - this does not return the requested URI/URL
		return cgi.script_name & replace(cgi.path_info,cgi.script_name,""); // tested with Apache 1.3 and 2.0 on Linux, and IIS 4, 5 and 6 on Windows
	}
	
	function getCleanRequestedPath() {
		var i = 1;
		var cleanRequestedPath = cgi.script_name;
		var cleanPathInfo = reReplace(replace(cgi.path_info,cgi.script_name,""),"/resetcache/[^/]*","");
		for (i=1; i lte listLen(cleanPathInfo,"/"); i=i+1) {
			if ( i mod 2 ) {
				// parameter name
				cleanRequestedPath = listAppend(cleanRequestedPath,listGetAt(cleanPathInfo,i,"/"),"/");
			} else {
				// parameter value, url encode it and then eh, decode it a bit to help search engines
				cleanRequestedPath = listAppend(cleanRequestedPath,replaceList(urlEncodedFormat(listGetAt(cleanPathInfo,i,"/")),"%2D,%5F,%2E","-,_,."),"/");
			}
		}
		// put the trailing slash back
		if ( right(cleanPathInfo,1) eq "/" ) {
			cleanRequestedPath = cleanRequestedPath & "/";
		}
		return cleanRequestedPath;
	}
	
	function getCleanQueryString() {
		// clean speck stuff from the querystring
		return reReplace(cgi.query_string,"\&?resetcache=[^&]*","");
	}
	
	function capitalize(theString) {
		
		// possible TODO: expand the list of short words to take into account advice from Oxford, Chicago and New York style guides
		// See example using Oxford style guide as basis - http://avalon-internet.com/Capitalize_an_English_Title/en
		var tmpString = "";
		var thisToken = "";
		var tokenCount = "";
		var i = 1;
		var j = 1;
		var delimiter = "";
		
		var bForceLower = true;
		var minWordLength = 0; // minimum length of a word that should be capitalized, default 0, i.e. capitalize all words
		var delimiters = " /.(),'"""; // note: two or more of the same delimiter character in sequence will be replaced by a single character
		var prependChar = "";
		var appendChar = "";
		var smallWords = "a,an,the,and,as,at,but,by,for,if,in,is,of,on,or,to,v,via,vs";
		
		if ( not len(theString) ) {
			return "";	
		}
		
		if ( arrayLen(arguments) gte 2 and isBoolean(arguments[2]) ) {
			bForceLower = arguments[2];
		}
		
		if ( arrayLen(arguments) gte 3 and isNumeric(arguments[3]) ) {
			minWordLength = int(arguments[3]);
		}
		
		if ( arrayLen(arguments) gte 4 and len(arguments[4]) ) {
			delimiters = " " & replace(arguments[4]," ","","all");
		}
		
		theString = trim(replace(theString,"_"," ","all")); // replace underscores with spaces
		
		if ( bForceLower ) {
			theString = lCase(theString);
		}
		
		if ( find(left(theString,1),delimiters) ) {
			prependChar = left(theString,1);
		}
		
		if ( find(right(theString,1),delimiters) ) {
			appendChar = right(theString,1);
		}
		
		for ( i=1; i lte len(delimiters); i=i+1 ) {
			delimiter = mid(delimiters,i,1);
			tokenCount = listLen(theString,delimiter);
			for ( j=1; j lte tokenCount; j=j+1 ) {
				thisToken = listGetAt(theString,j,delimiter);
				if (len(thisToken) lte minWordLength or listFindNoCase(smallWords,thisToken) ) {
					tmpString = tmpString & lCase(thisToken);
				} else if (len(thisToken) eq 1) {
					tmpString = tmpString & uCase(thisToken);
				} else {
					tmpString = tmpString & uCase(left(thisToken,1)) & right(thisToken,len(thisToken)-1);
				}
				if ( j lt tokenCount ) {
					tmpString = tmpString & delimiter;
				} else {
					theString = tmpString;
					tmpString = "";
				}
			}
		}
		
		return prependChar & theString & appendChar;
			
	}
	
	function getConfigString(configFile,section,entry) {
		var context = ""; 
		var defaultValue = "";
		if (arrayLen(arguments) gt 3) {
			defaultValue = arguments[4];
		}
		if (arrayLen(arguments) gt 4) {
			context = arguments[5];
		} else if ( isDefined("attributes.context") ) {
			context = attributes.context;
		} else {
			context = request.speck;
		}
		if ( isDefined("context.config.#configFile#.#section#.#entry#") ) {
			return evaluate("context.config.#configFile#.#section#.#entry#");
		} else {
			return defaultValue;	
		}
	}
	
	function getDisplayMethodUrl(id) {
		// builds url to view a content item in full, usually via a display method, from a page of summaries, headlines etc.
		// updated to handle new rewrite urls
		// function used to be called with up to three arguments, id, title and keyword, but the title isn't used by the 
		// new rewrite urls, so if the function is called with two arguments, the second is now assumed to be the keyword.
		var displayMethodUrl = "";
		var queryString = "";
		var cleanRequestedPath = "";
		var urlSuffix = "";
		var sesTitle = "";
		var keyword = "";
		if ( structKeyExists(request.speck,"portal") ) {
			if ( arrayLen(arguments) gte 3 ) {
				// old style method call
				keyword = arguments[3];
				sesTitle = arguments[2];
			} else if ( arrayLen(arguments) eq 2 and structKeyExists(request.speck,"qKeywords") and listFind(valueList(request.speck.qKeywords.keyword),arguments[2]) ) {
				// new style method call and second argument matches a keyword
				keyword = arguments[2];
			} else if ( arrayLen(arguments) eq 2 ) {
				sesTitle = arguments[2];
				keyword = request.speck.portal.keyword;
			} else {
				keyword = request.speck.portal.keyword;
			}
			if ( isDefined("request.speck.portal.rewriteEngine") and request.speck.portal.rewriteEngine ) {
				if ( len(request.speck.portal.rewritePrefix) and right(request.speck.portal.rewritePrefix,1) eq "-" ) {
					// old rewrite url format
					if ( len(sesTitle) ) {
						sesTitle = lCase(trim(sesTitle));
						sesTitle = replace(sesTitle,"&euro;","EUR","all");
						sesTitle = reReplace(sesTitle,"&([a-zA-Z])acute;","\1","all");
						sesTitle = reReplace(sesTitle,"&[a-zA-Z0-9]+;","","all");
						sesTitle = reReplace(sesTitle,"[^A-Za-z0-9\-]+","-","all");
						sesTitle = reReplace(sesTitle,"[\-]+","-","all");
						sesTitle = replace(urlEncodedFormat(sesTitle),"%2D","-","all");
						displayMethodUrl = "/#request.speck.portal.rewritePrefix##replace(keyword,".",request.speck.portal.keywordSeparator,"all")#/#sesTitle#/spId/#id##request.speck.sesSuffix#";
					} else {
						displayMethodUrl = "/#request.speck.portal.rewritePrefix##replace(keyword,".",request.speck.portal.keywordSeparator,"all")#/spId/#id##request.speck.sesSuffix#";
					}
				} else {
					// new rewrite url format
					displayMethodUrl = "/#request.speck.portal.rewritePrefix##replace(keyword,".",request.speck.portal.keywordSeparator,"all")#/#id##request.speck.sesSuffix#";
				}
			} else {
				displayMethodUrl = cgi.script_name & "/spKey/#replace(keyword,".",request.speck.portal.keywordSeparator,"all")#/spId/#id##request.speck.sesSuffix#";
			}
		} else if ( isDefined("request.speck.sesUrls") and request.speck.sesUrls ) {
			// search engine safe url
			displayMethodUrl = request.speck.getCleanRequestedPath();
			// rip any existing id out of the url
			displayMethodUrl = REReplaceNoCase(displayMethodUrl,"\/spId(\/)?.*","");
			if ( isDefined("request.speck.sesSuffix") and len(request.speck.sesSuffix) ) {
				urlSuffix = request.speck.sesSuffix;
				if ( right(displayMethodUrl, len(request.speck.sesSuffix)) eq request.speck.sesSuffix ) {
					displayMethodUrl = left(displayMethodUrl,len(displayMethodUrl) - len(request.speck.sesSuffix));
				}
			}
			// remove possible trailing slash in path
			displayMethodUrl = REReplace(displayMethodUrl,"/$","");			
			// add spId parameter and value to url
			displayMethodUrl = displayMethodUrl & "/spId/" & id & urlSuffix;
			// append any querystring params
			queryString = request.speck.getCleanQueryString();
			if ( len(queryString) ) {
				displayMethodUrl = displayMethodUrl & "?" & queryString;
			}
		} else {
			queryString = request.speck.getCleanQueryString();
			// rip any existing id out of the querystring
			queryString = REReplaceNoCase(queryString,"\&?spId\=.+$","");
			if ( len(queryString) ) {
				displayMethodUrl = cgi.script_name & "?" & queryString & "&spId=" & id;
			} else {
				displayMethodUrl = cgi.script_name & "?spId=" & id;
			}
			displayMethodUrl = replace(displayMethodUrl,"&","&amp;","all");
		}
		return displayMethodUrl;
	}
	
	function getPropertyDefinition(type,property) {
		// gets property definition
		// returns struct (empty if no property definition found)
		var i = 1;
		var stType = application.speck.types[type];
		for(i=1; i le arrayLen(stType.props); i = i + 1) {
			if ( stType.props[i].name eq property ) {
				return duplicate(stType.props[i]);
			}
		}
		return structNew();
	}
	
	// this probably isn't the best place for this function, but unfortunately there is now code that depends on it being available in request.speck scope
	function getDomainFromHostName() {
		// some crude code to get an email domain from the current host name
		var domain = "";
		var domainElements = 2;
		if ( arrayLen(arguments) ) {
			domain = lCase(arguments[1]);
		} else {
			domain = lCase(cgi.HTTP_HOST);
		}
		if ( listFind("uk,au",listLast(domain,".")) ) {
			// tld is a country that issues domains at the third level.
			// This only handles the listed countries and assumes that 
			// all domains issued by the country domain registry are 
			// at the third level (which isn't necessarily true). 
			domainElements = 3;
		}
		while ( listLen(domain,".") gt domainElements ) {
			domain = listDeleteAt(domain,1,".");
		}
		return lCase(domain);
	}
	
	function forceParagraphs(html) {
		
		// force the use of paragraph tags in html - useful when you're trying to force structural markup
		
		// This function absolutely brutal and might make a balls of your html. It assumes that any content 
		// not already inside a block level element should be within a paragraph. In the course of forcing 
		// this outcome, it removes all end paragraph tags, inserts opening tags as necessary after the 
		// closing of existing block level elements (i.e. if they're missing) and then just slaps a load of 
		// end paragraph tags in before opening block level elements. The only significant issue I can see
		// with this is it'll remove paragraph tags from within divs, which shouldn't really be a problem.
		
		var nl = chr(13) & chr(10);
		var blockElementsPattern = "address|blockquote|div|dl|form|h1|h2|h3|h4|h5|h6|hr|ol|p|pre|table|ul";
		var cleanElementsPattern = "address|div|dd|dt|h1|h2|h3|h4|h5|h6|li|pre|td|th";

		// tidy up the html
		// rip out any non-breaking spaces
		html = trim(html);		
		html = replaceNoCase(html,"&nbsp;"," ","all");
		html = replaceNoCase(html,"&##160;"," ","all");
		// replace sequences of two or more br tags with a p tag
		html = reReplaceNoCase(html,"(<br[[:space:]]*/?>[[:space:]]*){2,}","<p>","all");
		
		// clean leading and trailing br tags from content elements like dt, td, h1 etc.
		html = reReplaceNoCase(html,"(<(#cleanElementsPattern#)>)([[:space:]]*)<br[[:space:]]*/?>","\1","all");
		html = reReplaceNoCase(html,"(<br[[:space:]]*/?>)([[:space:]]*)(</(#cleanElementsPattern#)>)","\3","all");

		// remove any existing end paragraph tags (we'll insert these as appropriate later)
		html = reReplaceNoCase(html,"</p[[:space:]]*>","","all");
		
		// remove paragraph tags from within other content elements
		do {
			html = reReplaceNoCase(html,"(<(#cleanElementsPattern#)[^>]*>)([^<]*)<p[^>]*>","\1\3 ","all");
		} while ( reFindNoCase("(<(#cleanElementsPattern#)[^>]*>)([^<]*)<p[^>]*>",html) );
		
		// insert opening paragraph tags
		if ( not reFindNoCase("^<(#blockElementsPattern#)>",html) ) {
			html = "<p>" & html;
		}
		html = reReplaceNoCase(html,"(</(#blockElementsPattern#)[^>]*>)[[:space:]]*([A-Za-z0-9]{1})","\1#nl#<p>\3","all");

		// insert closing paragraph tags
		html = reReplaceNoCase(html,"([A-Za-z0-9]{1})[[:space:]]*(<(#blockElementsPattern#)[^>]*>)","\1</p>#nl#\2","all");
		if ( not reFindNoCase("</(#blockElementsPattern#)>$",html) ) {
			html = trim(html) & "</p>";
		}

		// tidy up any empty paragraphs (browsers are supposed to ignore them, but I'm taking no chances)
		html = reReplace(html,"<p[^>]*>[[:space:]]*</p>","","all");
		
		// clean any trailing br tags from paragraphs (closing paragraph tags could have been added after a br)
		html = reReplaceNoCase(html,"(<br[[:space:]]*/?>)([[:space:]]*)(</p>)","\3","all");
		
		// force content of blockquotes to be wrapped in paragraph tags...
		html = reReplace(html,"(<blockquote>)[[:space:]]*([A-Za-z0-9]{1})","\1<p>\2","all");
		html = reReplace(html,"(<blockquote>)[[:space:]]*(<[^p])","\1<p>\2","all");
		html = reReplace(html,"([A-Za-z0-9]{1})[[:space:]]*(</blockquote>)","\1</p>\2","all");
		html = reReplace(html,"(</[^p][^>]*>)[[:space:]]*(</blockquote>)","\1</p>\2","all");
		
		return html;
	}
	
	// Hash used to break assets up across directories numbered 0-99
	function assetHash(id) {
		return lsParseNumber("0" & REReplace(left(id, 5), "[^0-9]", "", "ALL")) mod 100;
	}

	stServer.buildString = buildString;
	stServer.getNextRow = getNextRow;
	stServer.isUUID = isUUID;
	stServer.textDDLString = textDDLString;
	stServer.dbConcat = dbConcat;
	stServer.dbTableNotFound = dbTableNotFound;
	stServer.dbIdentifier = dbIdentifier;
	stServer.userHasPermission = userHasPermission;
	stServer.getTypeTemplate = getTypeTemplate;
	stServer.getHandlerTemplate = getHandlerTemplate;
	stServer.getPropertyHandlerTemplate = getPropertyHandlerTemplate;
	stServer.getMIMEType = getMIMEType;
	stServer.getRequestedPath = getRequestedPath;
	stServer.getCleanRequestedPath = getCleanRequestedPath;
	stServer.getCleanQueryString = getCleanQueryString;
	stServer.capitalize = capitalize;
	stServer.getConfigString = getConfigString;
	stServer.getDisplayMethodUrl = getDisplayMethodUrl;
	stServer.getPropertyDefinition = getPropertyDefinition;
	stServer.forceParagraphs = forceParagraphs;
	stServer.getDomainFromHostName = getDomainFromHostName;
	stServer.assetHash = assetHash;

</cfscript>

