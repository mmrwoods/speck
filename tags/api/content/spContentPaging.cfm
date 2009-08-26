<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfparam name="attributes.qsName" default="page"> <!--- deprecated, use paramName --->
<cfparam name="attributes.paramName" default="#attributes.qsName#">

<cfif not len(attributes.paramName)>
	<cfset attributes.paramName = "spPage">
</cfif>

<!--- string attributes used for display --->
<cfparam name="attributes.page" default="#request.speck.buildString("A_PAGING_PAGE_STRING")#">
<cfparam name="attributes.first" default="#request.speck.buildString("A_PAGING_FIRST_PAGE")#">
<cfparam name="attributes.previous" default="#request.speck.buildString("A_PAGING_PREV_PAGE")#">
<cfparam name="attributes.next" default="#request.speck.buildString("A_PAGING_NEXT_PAGE")#">
<cfparam name="attributes.last" default="#request.speck.buildString("A_PAGING_LAST_PAGE")#">

<cfparam name="attributes.format" default="long">

<cfif not listFindNoCase("long,short,search",attributes.format)>

	<cf_spError error="ATTR_INV" lParams="#attributes.format#,format"> <!--- Invalid attribute --->

</cfif>

<cfparam name="attributes.displayPerPage" default="10">

<cfparam name="attributes.basePath" default="">

<cfparam name="url.#attributes.paramName#" default="">
<cfscript>
	
	// how many items per page?
	displayPerPage = attributes.displayPerPage;

	// total number of items
	totalRows = attributes.totalRows;
	
	// total pages
	if ( totalRows mod displayPerPage ) {
		totalPages = int((totalRows / displayPerPage) + 1);
	} else {
		totalPages = int((totalRows / displayPerPage));
	}
	
	// paging querystring parameter name and value (different for each type)
	paramName = attributes.paramName;
	paramValue = evaluate("url.#paramName#");
	
	// current page
	if ( isNumeric(paramValue) ) {
		thisPage = paramValue;
	} else if ( trim(paramValue) eq "last" ) {
		thisPage = totalPages;
	} else {
		thisPage = 1;
	}
	if ( (thisPage gt totalPages) or (thisPage lt 1) ) {
		thisPage = 1;
	}
	
	// set prev and next page values
	prevPage = thisPage - 1;
	nextPage = thisPage + 1;

	// set start row
	if ( thisPage gt 1) {
		startRow = (displayPerPage * (thisPage - 1)) + 1;
	} else {
		startRow = thisPage;
	}		

	// get end row on this page (for display purposes only)
	if ( (thisPage eq totalPages) and (totalRows mod displayPerPage) ) {
		endRow = startRow + (totalRows mod displayPerPage) - 1;
	} else {
		endRow = startRow + displayPerPage - 1;
	}

	// create paging menu string
	pagingMenu = "";
	if ( totalPages gt 1 ) {
		// we need a menu
		if ( attributes.format neq "search" ) {
			pagingMenu = attributes.page & " : "; // now getting this "page" string from strings.cfg
		}
		// build the base path, this is a mess because we have to support an old deprecated rewrite url format
		// get the requested path minus paramName and paramValue
		cleanRequestedPath = reReplace(request.speck.getCleanRequestedPath(),"/#paramName#/[0-9]*","");
		// get the querystring minus paramName and paramValue
		cleanQueryString = request.speck.getCleanQueryString();
		cleanQueryString = trim(reReplaceNoCase(chr(32) & cleanQueryString,"(#chr(32)#|&)(#paramName#)=[0-9]*",""));
		cleanQueryString = trim(reReplaceNoCase(chr(32) & cleanQueryString,"(#chr(32)#|&)spPath=[^&]*",""));
		qsPrefix = "?"; 
		paramNameValueSeparator = "="; 
		sesSuffix = ""; // only used with old rewtite urls
		if ( len(attributes.basePath) ) {
			basePath = attributes.basePath; //NOTE: base path is accepted as provided, without cleaning paging related params out, this can cause problems and tbh, should probably be considered a bug
			if ( find("?",basePath) )
				qsPrefix = "&";
		} else {
			bPortalPage = listFindNoCase(getBaseTagList(),"CF_SPPAGE");
			if ( bPortalPage and request.speck.portal.rewriteEngine and structKeyExists(url,"spPath") and len(url.spPath) ) {
				cleanQueryString = trim(reReplaceNoCase(chr(32) & cleanQueryString,"(#chr(32)#|&)spKey=[^&]*",""));
				basePath = "#request.speck.appWebRoot#/#request.speck.portal.rewritePrefix##replace(request.speck.portal.keyword,".",request.speck.portal.keywordSeparator,"all")#";
				//if ( len(request.speck.portal.rewritePrefix) and right(request.speck.portal.rewritePrefix,1) eq "-" ) {
					// old rewrite url format doesn't use querystrings at all
				//	qsPrefix = "/";
				//	paramNameValueSeparator = "/";
				//	if ( isDefined("request.speck.sesSuffix") and len(request.speck.sesSuffix) ) {
				//		sesSuffix = request.speck.sesSuffix;
				//	}
				//}
			} else {
				basePath = cleanRequestedPath;
				//if ( len(cleanQueryString) ) {
				//	basePath = basePath & '?' & cleanQueryString;
				//	qsPrefix = "&";
				//}
			}
			if ( left(cleanQueryString,1) eq "&" ) {
				cleanQueryString = right(cleanQueryString,len(cleanQueryString)-1);
			}
			if ( bPortalPage and not len(cleanQueryString) and request.speck.portal.rewriteEngine and len(request.speck.portal.rewritePrefix) and right(request.speck.portal.rewritePrefix,1) eq "-" ) {
				// old rewrite url format doesn't use querystrings at all
				qsPrefix = "/";
				paramNameValueSeparator = "/";
				if ( isDefined("request.speck.sesSuffix") and len(request.speck.sesSuffix) ) {
					sesSuffix = request.speck.sesSuffix;
					basePath = reReplace(basePath,"\#sesSuffix#$",""); // FIXME so the sesSuffix break this regex
				}
			} else if ( len(cleanQueryString) ) {
				basePath = basePath & '?' & cleanQueryString;
				qsPrefix = "&";
			}
		}

		
		if ( attributes.format eq "search" and thisPage gt 1 ) {
			// link to previous page
			prevPage = thisPage - 1;
			if ( prevPage eq 1 ) {
				pagingMenu = pagingMenu & ' <a href="' & basePath & sesSuffix & '">' & attributes.previous & '</a> : ';
			} else {
				pagingMenu = pagingMenu & ' <a href="' & basePath & qsPrefix & paramName & paramNameValueSeparator & prevPage & sesSuffix & '">' & attributes.previous & '</a> : ';
			}
		}
		
		// create links to pages
		pagingMenu = pagingMenu & "[";
		// start at
		if ( thisPage lte 10 ) {
			startAt = 1;
		} else {
			if (not (thisPage mod 10) ) {
				startAt = (thisPage - 10) + 1;
			} else {
				startAt = left(thisPage,len(thisPage)-1) & "1";
			}
		}
		
		if ( thisPage lte 5 or totalPages lte 9 ) {
			startAt = 1;
		} else {
			startAt = thisPage - 4;
		}
		
		for ( i = startAt; i lt startAt+9; i = i + 1 ) { 
			if ( i eq thisPage ) {
				pagingMenu = pagingMenu & ' <strong>' & i & '</strong> ';
			} else if ( i gt totalPages ) {
				if (i lte 9 ) break;
				pagingMenu = pagingMenu & '<del>' & i & '</del> ';
			} else if ( i eq 1 ) {
				pagingMenu = pagingMenu & ' <a href="' & basePath & sesSuffix & '">' & i & '</a> ';
			} else {
				pagingMenu = pagingMenu & ' <a href="' & basePath & qsPrefix & paramName & paramNameValueSeparator & i & sesSuffix & '">' & i & '</a> ';
			}
		}
		
		pagingMenu = pagingMenu & "]";
		
		if ( attributes.format neq "search" ) {
			if ( attributes.format eq "long" and thisPage gt 6 and totalPages gt 9 ) {
				// link to first page
				pagingMenu = pagingMenu & ' : <a href="' & basePath & sesSuffix & '">' & attributes.first & '</a>';
			}
			if ( thisPage gt 1 ) {
				// link to previous page
				prevPage = thisPage - 1;
				if ( prevPage eq 1 ) {
					pagingMenu = pagingMenu & ' : <a href="' & basePath & sesSuffix & '">' & attributes.previous & '</a> ';
				} else {
					pagingMenu = pagingMenu & ' : <a href="' & basePath & qsPrefix & paramName & paramNameValueSeparator & prevPage & sesSuffix & '">' & attributes.previous & '</a> ';
				}
			}
		}
			
		if ( thisPage neq totalPages ) {
			// link to next page
			nextPage = thisPage + 1;
			pagingMenu = pagingMenu & ' : <a href="' & basePath & qsPrefix & paramName & paramNameValueSeparator & nextPage & sesSuffix & '">' & attributes.next & '</a>';
			if ( attributes.format eq "long" and totalPages gt 9 ) {
				pagingMenu = pagingMenu & ' : <a href="' & basePath & qsPrefix & paramName & paramNameValueSeparator & totalPages & sesSuffix & '">' & attributes.last & '</a>';
			}
		}
		
	}
	
	// return values to spContent
	caller.stPaging = structNew();
	caller.stPaging.menu = pagingMenu;
	caller.stPaging.startRow = startRow;
	caller.stPaging.endRow = endRow;
	caller.stPaging.totalPages = totalPages;
	caller.stPaging.thisPage = thisPage;	
	
</cfscript>
<cfsetting enablecfoutputonly="No">