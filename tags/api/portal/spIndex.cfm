<cfsetting enablecfoutputonly="true">

<!--- adds content index definition to type definition, which can be used by spContentPut, spPromote and spDelete to manage the index --->

<!--- If method is spTypeDefinition, validate attributes and create index struct and associate with type --->

<!--- If context provided to caller use that, else use request.speck --->
<cfscript>

	ca = caller.attributes;
	
	if (not isDefined("ca.context"))
		ca.context = request.speck;
	
	speckInstallRoot = ca.context.speckInstallRoot;
	fs = ca.context.fs;
	
</cfscript>

<!--- Check we are placed inside cf_spType tag --->
<cfset lBaseTags = getBaseTagList()>
<cfif listFind(lBaseTags, "CF_SPTYPE") eq 0>

	<cf_spError error="INDEX_NOT_IN_TYPE" lParams="" context=#ca.context#>	<!--- Must be placed inside cf_spType tag --->

</cfif>

<cfset stTypeVars = getBaseTagData("CF_SPTYPE")>

<cfif stTypeVars.a.method neq "spTypeDefinition">

	<cfexit method="EXITTAG">

</cfif>

<!--- validate attributes --->
		
<cfloop list="title,description,body" index="attribute">

	<cfif not structKeyExists(attributes,attribute)>
	
		<cf_spError error="ATTR_REQ" lParams="#attribute#" context=#ca.context#>	<!--- Missing attribute --->
		
	</cfif>

</cfloop>

<!--- get a list of existing properties and also date type properties --->
<cfscript>
	lProps = "";
	lDateProps = "";
	for(i=1; i le arrayLen(stTypeVars.thisTag.props); i = i + 1) {
		stPD = stTypeVars.thisTag.props[i];
		lProps = listAppend(lProps,stPD.name);
		if ( stPD.dataBaseColumnType eq "dateTime" or stPD.type eq "Date" ) {
			lDateProps = listAppend(lDateProps,stPD.name);
		}
	}
</cfscript>

<cfif not listLen(lProps)>

	<cfthrow message="CF_SPINDEX - No properties available to index. Please make sure that you call this tag after all property definitions.">

</cfif>

<cfif not structKeyExists(attributes,"date")>
	
	<cfset attributes.date = "spCreated">
	
<cfelseif not listFindNoCase(lDateProps,attributes.date)>

	<cf_spError error="ATTR_INV" lParams="#attributes.date#,date" context=#ca.context#>

</cfif>
				
<cfloop list="#attributes.title#" index="propName">

	<cfif not listFindNoCase(lProps,propName)>
	
		<cf_spError error="ATTR_INV" lParams="#propName#,title" context=#ca.context#>
	
	</cfif>
	
</cfloop>	

<cfloop list="#attributes.description#" index="propName">

	<cfif not listFindNoCase(lProps,propName)>
	
		<cf_spError error="ATTR_INV" lParams="#propName#,description" context=#ca.context#>
	
	</cfif>
	
</cfloop>

<cfloop list="#attributes.body#" index="propName">

	<cfif not listFindNoCase(lProps,propName)>
	
		<cf_spError error="ATTR_INV" lParams="#propName#,body" context=#ca.context#>
	
	</cfif>
	
</cfloop>

<cfassociate basetag="CF_SPTYPE" datacollection="contentIndex">

<!--- 
old version of code, where I tried to write a standalone tag that wouldn't require hacks in spContentPut, spType, spPromote and spDelete, didn't really work tho
<cfswitch expression="#stTypeVars.a.method#">

	<cfcase value="spTypeDefinition">
	
		<!--- validate attributes --->
		
		<cfloop list="title,description,body" index="attribute">

			<cfif not structKeyExists(attributes,attribute)>
			
				<cf_spError error="ATTR_REQ" lParams="#attribute#" context=#ca.context#>	<!--- Missing attribute --->
				
			</cfif>
		
		</cfloop>
		
		<!--- get a list of existing properties and also date type properties --->
		<cfscript>
			lProps = "";
			lDateProps = "";
			for(i=1; i le arrayLen(stTypeVars.thisTag.props); i = i + 1) {
				stPD = stTypeVars.thisTag.props[i];
				lProps = listAppend(lProps,stPD.name);
				if ( stPD.dataBaseColumnType eq "dateTime" or stPD.type eq "Date" ) {
					lDateProps = listAppend(lDateProps,stPD.name);
				}
			}
		</cfscript>
		
		<cfif not listLen(lProps)>
		
			<cfthrow message="CF_SPINDEX - No properties available to index. Please make sure that you call this tag after all property definitions.">
		
		</cfif>
		
		<cfif not structKeyExists(attributes,"date")>
			
			<cfset attributes.date = "spCreated">
			
		<cfelseif not listFindNoCase(lDateProps,attributes.date)>
		
			<cf_spError error="ATTR_INV" lParams="#attributes.date#,date" context=#ca.context#>
		
		</cfif>
						
		<cfloop list="#attributes.title#" index="propName">
		
			<cfif not listFindNoCase(lProps,propName)>
			
				<cf_spError error="ATTR_INV" lParams="#propName#,title" context=#ca.context#>
			
			</cfif>
			
		</cfloop>	
		
		<cfloop list="#attributes.description#" index="propName">
		
			<cfif not listFindNoCase(lProps,propName)>
			
				<cf_spError error="ATTR_INV" lParams="#propName#,description" context=#ca.context#>
			
			</cfif>
			
		</cfloop>
		
		<cfloop list="#attributes.body#" index="propName">
		
			<cfif not listFindNoCase(lProps,propName)>
			
				<cf_spError error="ATTR_INV" lParams="#propName#,body" context=#ca.context#>
			
			</cfif>
			
		</cfloop>
		
		<!--- <cfassociate basetag="CF_SPTYPE" datacollection="contentIndex"> --->
			
	</cfcase>
	
	<cfcase value="delete">
	
		<!--- delete items from content index --->
		<cfset lIdsToDelete = valueList(ca.qContent.spId)>
		
		<cfif ca.qContent.recordCount>
		
			<cfquery name="qDelete" datasource="#request.speck.codb#">
				DELETE FROM spContentIndex WHERE id IN (#quotedValueList(ca.qContent.spId)#)
			</cfquery>
		
		</cfif>
	
	</cfcase>
	
	<cfcase value="promote">
		
		<Cfdump var="#ca#">
		<cfabort>
	
		<!--- if new level is live, loop over content query, delete items being removed from content index, update others --->
		<cfif ca.newLevel eq "live">
		
			<cfloop query="ca.qContent">
			
				<cfif ca.revision eq 0>
				
					<!--- removal --->
					<cfquery name="qDelete" datasource="#request.speck.codb#">
						DELETE FROM spContentIndex WHERE id = '#spId#'
					</cfquery>
				
				<cfelse>
					
					<!--- update the content index --->
					
					<cfscript>
						stContentIndex = structNew();
						if ( len(evaluate("#attributes.date#")) ) {
							stContentIndex.date = evaluate("#attributes.date#");
						} else {
							stContentIndex.date = spCreated;
						}
						stContentIndex.title = "";
						for (i=1; i le listLen(attributes.title); i=i+1) {
							stContentIndex.title = stContentIndex.title & evaluate("#listGetAt(attributes.title,i)#") & " ";
						}
						stContentIndex.description = "";
						for (i=1; i le listLen(attributes.description); i=i+1) {
							stContentIndex.description = stContentIndex.description & evaluate("#listGetAt(attributes.description,i)#") & " ";
						}
						stContentIndex.body = "";
						for (i=1; i le listLen(attributes.body); i=i+1) {
							stContentIndex.body = stContentIndex.body & evaluate("#listGetAt(attributes.body,i)#") & " ";
						}						
					</cfscript>
					
					<cf_spContentIndex type="#ca.type#"
						id="#spId#"
						keyword="#listFirst(spKeywords)#"
						attributeCollection="#stContentIndex#">
				
				</cfif>
			
			</cfloop>
		
		</cfif>
	
	</cfcase>
	
	<cfcase value="contentPut">
	
		<!--- if revisioning disabled, loop over content query and update items in content index --->
 		<cfif not request.speck.enableRevisions>
		
			<cfloop query="ca.qContent">		
		
				<!--- update the content index --->
				
				<cfscript>
					stContentIndex = structNew();
					if ( len(evaluate("#attributes.date#")) ) {
						stContentIndex.date = evaluate("#attributes.date#");
					} else {
						stContentIndex.date = spCreated;
					}
					stContentIndex.title = "";
					for (i=1; i le listLen(attributes.title); i=i+1) {
						stContentIndex.title = stContentIndex.title & evaluate("#listGetAt(attributes.title,i)#") & " ";
					}
					stContentIndex.description = "";
					for (i=1; i le listLen(attributes.description); i=i+1) {
						stContentIndex.description = stContentIndex.description & evaluate("#listGetAt(attributes.description,i)#") & " ";
					}
					stContentIndex.body = "";
					for (i=1; i le listLen(attributes.body); i=i+1) {
						stContentIndex.body = stContentIndex.body & evaluate("#listGetAt(attributes.body,i)#") & " ";
					}						
				</cfscript>
				
				<cf_spContentIndex type="#ca.type#"
					id="#spId#"
					keyword="#listFirst(spKeywords)#"
					attributeCollection="#stContentIndex#">
					
			</cfloop>
		
		</cfif>					
	
	</cfcase>
	
	<cfdefaultcase>
	
		<cfexit method="EXITTAG"> <!--- this is actually superflous and is really just here to make it clear that exiting is the intention --->
	
	</cfdefaultcase>

</cfswitch>
 --->
