<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com),
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- Validate attributes --->
<cfloop list="r_qContent,type" index="attribute">

	<cfif not isdefined("attributes.#attribute#")>

		<cf_spError error="ATTR_REQ" lParams="#attribute#">	<!--- Missing attribute --->

	</cfif>

</cfloop>

<cfif isDefined("attributes.revision") and isDefined("attributes.level")>

	<cf_spError error="ATTR_MUTEX" lParams="revision,level"> <!--- Mutually exclusive attributes --->

</cfif>

<cfparam name="attributes.id" default="">
<cfparam name="attributes.label" default="">
<cfparam name="attributes.keywords" default="">
<cfparam name="attributes.where" default="">
<cfparam name="attributes.orderby" default="">
<cfparam name="attributes.date" default=#request.speck.session.viewDate#>
<cfparam name="attributes.level" default=#request.speck.session.viewLevel#>
<cfparam name="attributes.editor" default=#request.speck.session.user#>
<!---
Default revision attribute according to application's enablePromotion and enableRevisions settings
Note: if revisioning enabled, but promotion disabled, we still need to retrieve content items based 
on a level to avoid retrieving removed items, i.e. content items with revision 0 promoted to live. 
Retrieving content based on a promotion level and filtering out removed items currently results in 
a pretty nasty revision where clause.
Note 2: performance hack added to revisionWhereClause - if revisioning enabled, but promotion 
disabled, we now get the tip revision where the content item has never been removed. This breaks 
the recording of a complete history for a content item. The only way to restore a deleted content 
item while this hack is in place is to removed its deleted revision from the history table, but it 
avoids that really, really nasty correlated subquery and makes a huge difference to query 
performance when revisioning is enabled but promotion disabled (up to 100x faster - honest). 
TODO: overhaul promotion model to improve performance when promotion enabled and maintain improved 
performance achieved by note2, but without breaking the nice content history feature of Speck.
Note3: performance hack, eh, hacked. Added AND ts >= content.spUpdated to condition to check if an 
item has been removed. Although I haven't tested it, this should in theory allow a content item to 
be removed and then a new revision to be created with a later updated date than the date of the 
removal and the content item will re-appear, while still recording a complete history, including 
a temporary removal. This code relies on the fact that promotion happens after content is put.
TODO: explore this idea further and see if it can be used to improve performance with promotion on.
--->
<cfif request.speck.enablePromotion or len(attributes.date)>
	<cfparam name="attributes.revision" default="">
<cfelse>
	<cfparam name="attributes.revision" default="tip">
</cfif>
<cfparam name="attributes.filterRemoved" default="true"> <!--- filter out removals which have been promoted --->
<cfparam name="attributes.bEdit" default="false" type="boolean">
<cfparam name="attributes.maxRows" default="-1" type="numeric">

<cfparam name="attributes.properties" default=""> <!--- which columns to retrieve from the database and run contentGet property handlers for --->

<cfparam name="attributes.keywordsMatch" default="any"> <!--- any|all|exact - note: exact performs comparison without first converting to uppercase --->

<!--- use the keywords index table when retrieving content based on matching keywords? --->
<cfparam name="request.speck.useKeywordsIndex" type="boolean" default="no">
<cfparam name="attributes.useKeywordsIndex" type="boolean" default=#request.speck.useKeywordsIndex#>

<!--- added to allow content from other apps to be retrieved using spContentGet --->
<cfparam name="attributes.datasource" default=#request.speck.codb#>
<cfparam name="attributes.username" default=#request.speck.database.username#>
<cfparam name="attributes.password" default=#request.speck.database.password#>

<cfif attributes.date neq "" and not isDate(attributes.date)>

	<cf_spError error="ATTR_INV" lParams="#attributes.date#,date"> <!--- Invalid attribute --->

</cfif>

<cfif attributes.maxRows neq int(attributes.maxRows)>

	<cf_spError error="ATTR_INV" lParams="#attributes.maxRows#,maxRows"> <!--- Invalid attribute --->
	
</cfif>

<cfset level = listContains("edit,review,live", attributes.level)>	<!--- Convert to number stored in spHistory.level --->

<cfif level eq 0 and request.speck.enablePromotion>

	<cf_spError error="CG_LEVEL_INV" lParams="#attributes.level#"> <!--- Invalid attribute --->

</cfif>

<cfif level eq 3>

	<cfparam name="attributes.showRemoved" default="false"> <!--- return removed items in content query? default to false for live site --->

<cfelse>

	<cfparam name="attributes.showRemoved" default="true"> <!--- return removed items in content query? --->

</cfif>

<cfif attributes.id neq "">

	<!--- Ids often come from client input (querystring parameters etc.) - let's tidy up any mangled input before running cfquery --->
	<cfset attributes.id = REReplace(attributes.id,"[^A-Za-z0-9\,\-]+","","all")>
	
	<cfset sIds = listQualify(attributes.id, "'", ",", "ALL")>

</cfif>

<cfif findNoCase(" ORDER BY ",attributes.where)>

	<!--- Doh! Someone added an ORDER BY clause to the where attribute, move it or remove it! --->

	<cfset orderByStartsAt = findNoCase(" ORDER BY ",attributes.where)>

	<cfset orderByEndsAt = orderByStartsAt + 9>

	<cfif not len(attributes.orderby)>

		<!--- orderby attribute has no value - copy contents of ORDER BY clause from where attribute to orderby attribute --->
		<cfset attributes.orderby = right(attributes.where, len(attributes.where) - orderByEndsAt)>

	</cfif>

	<!--- remove ORDER BY clause from where attribute --->
	<cfset attributes.where = left(attributes.where,orderByStartsAt)>

</cfif>

<!--- get type info --->
<cfmodule template=#request.speck.getTypeTemplate(attributes.type)# r_stType="stType">

<cfif not stType.revisioned and attributes.revision neq "all"> <!--- if type not revisioned set revision to "tip" --->

	<cfset attributes.revision = "tip">

</cfif>

<cfset bSave = false> <!--- by default we don't save the content query into a cache --->

<cfif isDefined("attributes.cachedWithin")>

	<cfset bSave = true>

	<!--- get unique cachename from attributes... --->
	<cfscript>
		cacheName = "";
		for ( key in attributes ) {
			cacheName = cacheName & key & "_" & attributes[key] & "_";
		}
		cacheName = "c" & hash(cacheName);
	</cfscript>

	<cflock scope="APPLICATION" type="READONLY" timeout=3>
	<cfif isDefined("application.speck.queryCache." & cacheName)>
		<cfset stCache = duplicate(application.speck.queryCache[cacheName])>
	</cfif>
	</cflock>

	<!--- only use query caching on live site and allow user to force a reset of the cache --->
	<cfif ( isdefined("url.resetCache") and request.speck.userHasPermission("spLive,spSuper") )
		or request.speck.session.viewLevel neq "live"
		or request.speck.session.showAdminLinks eq "true"
		or len(request.speck.session.viewDate)>

		<cfset bSave = false>

	</cfif>

	<cfif isDefined("stCache")>

		<cfif not bSave or ( isDate(stCache.expires) and stCache.expires lt now() )>

			<!--- flush me cache --->
			<cflock scope="APPLICATION" type="EXCLUSIVE" timeout=3>
			<cftry>
				<cfset void = structDelete(application.speck.queryCache, cacheName)>
			<cfcatch>
				<!---
				do nothing - another thread may have already deleted the cache
				and we don't really care if there's a temp difficulty getting a lock
				--->
			</cfcatch>
			</cftry>
			</cflock>

		<cfelse>

			<!--- Return query --->
			<cfset "caller.#attributes.r_qContent#" = duplicate(stCache.query)>

			<cfexit method="EXITTAG">

		</cfif>

	</cfif>

</cfif>

<!--- Construct revision SQL where clause --->
<cfscript>

	// set table alias keyword (Access requires the use of AS)
	ta = request.speck.database.tableAliasKeyword;

	error = ""; lParams = "";	// Place to save error details

	odbcdate = "";
	if (attributes.date neq "") {
		odbcDate = createODBCDateTime(attributes.date);
	}

	if ( attributes.revision neq ""  ) {
		switch (trim(attributes.revision)) {
			case "tip": {
				
				if ( not request.speck.enableRevisions and structKeyExists(stType,"containsRevisions") and not (stType.containsRevisions) ) {
					// performance hack to avoid running a subquery to get the correct revision when revisioning disabled and type never contained any revisions. 
					revisionWhereClause = "1=1";
				} else {
					// normal tip revision where clause has to run a subquery even when revisioning is disabled because it may have been enabled in the past
					revisionWhereClause = "spRevision IN (
												SELECT MAX(tip.spRevision)
												FROM #attributes.type# #ta# tip
												WHERE content.spId = tip.spId
												#iif(attributes.date neq "", DE("AND tip.spUpdated <= " & odbcdate), DE(""))#
												)";
				}
											
				// hack to avoid the really nasty correlated subquery on the history table when revisioning enabled, but promotion disabled.
				// If revisioning on, but promotion off, assume that we by default want the tip revision where the content item was never 
				// removed. Although the Speck history table in theory allows removed items to be restored, but still keep a record of the 
				// fact that they were once removed, this is never done in practice (there's no UI for it). It's basically impossible to use 
				// this hack with promotion on unless we add the promotion level to the content type tables. 
				// NOTE: code updated to compare removal timestamp and content updated timestamp, should now be possible to remove and restore 
				// items and keep a history of the removal as long as the restored content item is actually a new revision, with an updated date 
				// that occurs after the previous removal. Man, this is nasty and needs an overhaul. It works, but it's seriously ugly now.
				if ( request.speck.enableRevisions ) {
					revisionWhereClause = revisionWhereClause & "
										AND NOT EXISTS ( 
											SELECT id 
											FROM spHistory 
											WHERE id = content.spId 
												AND revision = 0
												AND ts >= content.spUpdated
											)";
				}
				break;
		 	}
			case "all": {
				revisionWhereClause = "1=1"; // don't filter by revision
				break;
			}
			default: {
				if (isNumeric(attributes.revision)) {
					revisionWhereClause = "spRevision = " & attributes.revision;
				} else {
					error = "CG_REV_INV";	// Invalid revision attribute
					lParams = attributes.revision;
				}
			}
		}
	} else if (attributes.level neq "") {
		if (level gt 1) {
			// Select most recent revision promoted to specified level that hasn't been removed* since promotion.
			// At review and live levels there will always be a row in spHistory recording the promotion to or
			// removal from that level.
			// * "Removal" is indicated in spHistory by promoting revision 0 of a content item.
			revisionWhereClause =
			"content.spRevision IN
				(
					SELECT	latestUnremovedPromotion.revision
					FROM	spHistory #ta# latestUnremovedPromotion
					WHERE	content.spId = latestUnremovedPromotion.id AND
							latestUnremovedPromotion.ts =
							(
								SELECT	MAX(latestPromotion.ts)
								FROM	spHistory #ta# latestPromotion
								WHERE	latestUnremovedPromotion.id = latestPromotion.id AND
										latestPromotion.promoLevel = #level#
										#iif(attributes.date neq "", DE("AND latestPromotion.ts <= " & odbcdate), DE(""))#
										#iif(attributes.showRemoved, DE("AND latestPromotion.revision <> 0"), DE(""))#
							)
				)";
		} else {
			// At edit level the editor only sees edit level content being edited by themseleves, and other content comes from review level.
			// Because of this we only retrieve edit level content being edited by the user (ts should always be greater than review level ts),
			// and include review level.
			revisionWhereClause =
			"content.spRevision IN
				(
					SELECT	latestUnremovedPromotion.revision
					FROM	spHistory #ta# latestUnremovedPromotion
					WHERE	content.spId = latestUnremovedPromotion.id AND
							latestUnremovedPromotion.ts =
							(
								SELECT	MAX(latestPromotion.ts)
								FROM	spHistory #ta# latestPromotion
								WHERE	latestUnremovedPromotion.id = latestPromotion.id AND
										(
											(
												latestPromotion.promoLevel = 1 AND latestPromotion.editor = '" & attributes.editor & "'
											) OR
											latestPromotion.promoLevel = 2
										)
										#iif(attributes.date neq "", DE("AND latestPromotion.ts <= " & odbcdate), DE(""))#
										#iif(attributes.showRemoved, DE("AND latestPromotion.revision <> 0"), DE(""))#
							)
				)";
		}
	}

</cfscript>

<cfif error neq "">

	<!--- Report error that occured in cfscript block --->
	<cf_spError error="#error#" lParams="#lParams#">

</cfif>

<cfscript>
	// limit properties returned in qContent query??
	lDatabaseProperties = "";
	// if ( len(attributes.properties) and not listFind(getBaseTagList(),"CF_SPCONTENT") and isDefined("stType.props") ) {
	if ( len(attributes.properties) and isDefined("stType.props") ) {

		// remove spaces from properties list before we check for matches
		attributes.properties = replace(attributes.properties,chr(32),"","all");

		// loop over properties array, if property found in attributes.properties
		// and is saved to database, append to lDatabaseProperties list
		for(i=1; i le arrayLen(stType.props); i = i + 1)
			if ( listFindNoCase(attributes.properties,stType.props[i].name) and stType.props[i].saveToDatabase )
				lDatabaseProperties = listAppend(lDatabaseProperties,stType.props[i].name);

	}
	// keywords where clause
	keywordsWhere = "";
	if ( len(attributes.keywords) ) {
		escapedKeywords = replace(attributes.keywords,"'","''","all");
		if ( attributes.keywordsMatch eq "exact" ) {
				keywordsWhere = " spKeywords = '#escapedKeywords#' AND ";
		} else if ( attributes.useKeywordsIndex and request.speck.session.viewLevel eq "live" and not len(request.speck.session.viewDate) ) {
			if ( attributes.keywordsMatch eq "any" ) {
				keywordsWhere = " spId IN ( SELECT id FROM spKeywordsIndex WHERE keyword IN (#uCase(listQualify(escapedKeywords,"'"))#) AND contentType = '#uCase(stType.name)#' ) AND ";
			} else {
				for ( i=1; i le keywordsCount; i = i+1 ) {
					keywordsWhere = keywordsWhere &  " spId IN ( SELECT id FROM spKeywordsIndex WHERE keyword = '#uCase(trim(listGetAt(escapedKeywords,i)))#' AND contentType = '#uCase(stType.name)#' ) AND ";
				}
			}
		} else {
			if ( attributes.keywordsMatch eq "any" )
				logicalOperator = "OR";
			else
				logicalOperator = "AND";
			if ( request.speck.dbtype eq "access" )
				keywordIdentifier = "spKeywords";
			else
				keywordIdentifier = "UPPER(spKeywords)";
			keywordsCount = listLen(attributes.keywords);
			for ( i=1; i le keywordsCount; i = i+1 ) {
				keywordsWhere = keywordsWhere & request.speck.dbConcat("','",keywordIdentifier,"','") & " LIKE '%," & uCase(trim(listGetAt(attributes.keywords,i))) & ",%'";
				if(i lt keywordsCount) keywordsWhere = keywordsWhere & " " & logicalOperator & " ";
			}
			keywordsWhere = " (" & keywordsWhere & ") AND ";
		}
	}
</cfscript>

<cfquery name="qContent"
	dataSource=#attributes.datasource#
	username=#attributes.username#
	password=#attributes.password#
	maxRows=#attributes.maxRows#>
	SELECT
	<cfif attributes.maxRows neq -1>
		<cfif request.speck.dbtype eq "sqlserver">
			TOP #attributes.maxRows#
		<cfelseif request.speck.dbtype eq "oracle">
			* FROM ( SELECT 
		<cfelseif listFind("informix,firebird,interbase",request.speck.dbtype)>
			FIRST #attributes.maxRows#
		</cfif>
	</cfif>
	<cfif len(lDatabaseProperties)>#lDatabaseProperties#, spId, spRevision, spLabel, spCreated, spCreatedBy, spUpdated, spUpdatedBy, spKeywords, spSequenceId<cfelse>*</cfif>
	FROM #request.speck.dbIdentifier(attributes.type)# #ta# content
	WHERE
	<cfif attributes.id neq "">
		spId IN (#preserveSingleQuotes(sIds)#) AND
	</cfif>
	<cfif attributes.label neq "">
		spLabelIndex = '#uCase(attributes.label)#' AND
	</cfif>
	<cfif attributes.where neq "">
		#preserveSingleQuotes(attributes.where)# AND
	</cfif>
	#preserveSingleQuotes(keywordsWhere)#
	#preserveSingleQuotes(revisionWhereClause)#
 	<cfif stType.revisioned and attributes.showRemoved and attributes.filterRemoved and level lt 3>
		<!--- only return removed items that have not been promoted --->
		<cfset nextLevel = level + 1>
		AND 0 = (
			SELECT COUNT(promotedRemoval.id)
			FROM spHistory #ta# promotedRemoval
			WHERE promotedRemoval.id = content.spId
				AND promotedRemoval.revision = 0
				AND promotedRemoval.promoLevel = #nextLevel#
				AND promotedRemoval.ts > (
					SELECT MAX(latestPromo.ts)
					FROM spHistory #ta# latestPromo
					WHERE latestPromo.id = content.spId
						AND latestPromo.revision = content.spRevision
				)
			)
	</cfif>
	<cfif attributes.orderby neq "">
		ORDER BY #preserveSingleQuotes(attributes.orderby)#
	</cfif>
	<cfif attributes.maxRows neq -1>
		<cfif listFindNoCase("postgresql,mysql,sqlite",request.speck.dbtype)>
			LIMIT #attributes.maxRows#
		<cfelseif request.speck.dbtype eq "oracle">
			) content_all WHERE ROWNUM <= #attributes.maxRows#
		<cfelseif request.speck.dbtype eq "db2">
			FETCH FIRST #attributes.maxRows# ROWS ONLY
		</cfif>
	</cfif>
</cfquery>

<cfparam name="attributes.orderByIds" default="false" type="boolean">
<cfif listLen(attributes.id) gt 1 and attributes.orderByIds>

	<!--- 
	Durty hack to force query ordering to match the list of ids.
	Picker property stores collections of content items as a list 
	of UUIDs. It wasn't initially designed to allow items in the 
	list to be sorted, but it does now. It should really use a 
	separate table to record the collections and sort order, but 
	it doesn't. This performance hack just avoids having to hit 
	the db multiple times in order to sort by a list of ids.
	--->
	
	<cfset qSorted = queryNew(qContent.columnList)>
	
	<cfloop list="#attributes.id#" index="i">

		<cfquery name="qRow" dbtype="query">
			SELECT * FROM qContent WHERE spId = '#i#'
		</cfquery>
		
		<cfif qRow.recordCount>
		
			<cfset void = queryAddRow(qSorted)>
			
			<cfloop list="#qContent.columnList#" index="col">
			
				<cfset void = querySetCell(qSorted,col,qRow[col][1])>
	
			</cfloop>
			
		</cfif>
		
	</cfloop>
	
	<cfset qContent = qSorted>
	
</cfif>

<!--- Call contentGet property handlers --->

<cfif isDefined("stType.props") and qContent.recordCount>

	<cfloop from=1 to=#arrayLen(stType.props)# index="prop">

		<cfset stPD = stType.props[prop]>

		<!--- Create column if it didn't come from database --->
		<!--- note: this is done regardless of whether the property is in attributes.properties because we should
			ensure that all properties have a corresponding query column to avoid potential problems with contentGet
			type methods barfing trying to read the value for a key that doesn't exist in the content structure --->
		<cfif listFindNoCase(qContent.columnList, stPD.name) eq 0>

			<cfset void = QueryAddColumn(qContent, stPD.name, arrayNew(1))>

		</cfif>

		<cfif structKeyExists(stPD.methods, "contentGet")
			and ( len(attributes.properties) eq 0 or listFindNoCase(attributes.properties,stPD.name) )> <!--- do not run contentGet method for properties not in attributes.properties --->

			<!--- property has a contentGet method, run the handler with this method --->

			<cfif listFirst(request.speck.cfVersion,",.") gte 7>

				<!--- querySetCell() in CFMX7 requires that the column data type be compatible with the value to be set --->
				<cf_spQueryCastColumn query="qContent" column="#stPD.name#" type="VARCHAR">

			</cfif>

			<cfloop from=1 to=#qContent.RecordCount# index="item">

				<cfmodule template=#stPD.methods.contentGet#
					method="contentGet"
					stPD=#stPD#
					type=#stType.name#
					id=#qContent.spId[item]#
					revision=#qContent.spRevision[item]#
					keywords=#qContent.spKeywords[item]#
					value=#qContent[stPD.name][item]#
					r_newValue="newValue"
					bEdit=#attributes.bEdit#>

				<cfset void = QuerySetCell(qContent, stPD.name, newValue, item)>

			</cfloop>

		</cfif>

	</cfloop>

</cfif>

<cfif structKeyExists(stType.methods, "contentGet")>

	<!--- call contentGet method --->

	<cfmodule template=#stType.methods.contentGet#
		qContent=#qContent#
		type=#stType.name#
		method="contentGet"
		updateContent="yes">

</cfif>


<!--- call spWasCached - doesn't matter if any content was returned,
	we want to record the attributes passed to any spContentGet
	calls within spCacheThis tags, that way when content is put
	or promoted to the live version of the site, we can flush
	any caches which could contain the new live content --->
<cfif listFind(getBaseTagList(),"CF_SPCACHETHIS")
	and request.speck.session.viewLevel eq "live"
	and request.speck.session.showAdminLinks neq "true"
	and request.speck.session.viewDate eq "">

	<cfmodule template="/speck/api/content/spWasCached.cfm"
		type=#attributes.type#
		id=#attributes.id#
		label=#attributes.label#
		keywords=#attributes.keywords#>

</cfif>

<cfif bSave>

	<!--- save the query into an application wide query cache... --->
	<cflock scope="APPLICATION" type="EXCLUSIVE" timeout="3" throwontimeout="Yes">
	<cfset application.speck.queryCache[cacheName] = structNew()>
	<cfset application.speck.queryCache[cacheName].query = duplicate(qContent)>
	<cfset application.speck.queryCache[cacheName].created = now()>
	<cfset application.speck.queryCache[cacheName].expires = createODBCDateTime(now() + attributes.cachedWithin)>
	</cflock>

</cfif>

<!--- Return query --->
<cfset "caller.#attributes.r_qContent#" = qContent>
