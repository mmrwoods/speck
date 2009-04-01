<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cfinclude template="../../Application.cfm">


<cfparam name="url.id" default="">

<cfif request.speck.isUUID(url.id) and structKeyExists(request.speck,"portal")>
	
	<cfscript>
		if ( request.speck.userHasPermission("spSuper,spLive") ) {
			cacheTimeSpan = createTimeSpan(0,0,0,0);
		} else {
			cacheTimeSpan = createTimeSpan(0,0,15,0);
		}
	</cfscript>
	
	<cf_spContentGet type="Event" id="#url.id#" properties="spKeywords" r_qContent="qEvent" cachedwithin="#cacheTimeSpan#">

	<cfif len(qEvent.spKeywords)>
		
		<cfquery name="qKeywords" dbtype="query">
			SELECT groups FROM request.speck.qKeywords WHERE keyword IN (#quotedValueList(qEvent.spKeywords)#)
		</cfquery>
		
		<cfscript>
			lAccessGroups = valueList(qKeywords.groups);
			if ( listLen(lAccessGroups) and not request.speck.userHasPermission("spSuper") ) {
				bAccess = false;	
				if ( request.speck.session.auth eq "logon" and isDefined("request.speck.session.groups") ) {
					lUserGroups = structKeyList(request.speck.session.groups);
					// loop over groups, if group found in users group list, set access to true
					while (lAccessGroups neq "" and not bAccess) {
						group = listFirst(lAccessGroups);
						lAccessGroups = listRest(lAccessGroups);
						if ( listFindNoCase(lUserGroups,group) )
							bAccess = true;
					}
				}
			} else {
				bAccess = true;
			}
		</cfscript>
		
		<cfif not bAccess>
		
			<cfheader statuscode="403" statustext="Access Denied">
			
			<cfoutput>
			<h1>#listFirst(request.speck.buildString("ERR_ACCESS_DENIED"),".")#</h1>
			#listRest(request.speck.buildString("ERR_ACCESS_DENIED"),".")#
			</cfoutput>
			<cfabort>
		
		</cfif>
		
	</cfif>

</cfif>
