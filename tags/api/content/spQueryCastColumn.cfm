<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<!--- 
note: this custom tag is a CFMX7 hack which will barf if called from CFMX6
DO NOT CALL THIS TAG FROM CF VERSIONS EARLIER THAN 7!!!

Q. Why do we need this tag?
A. querySetCell() in CFMX7 requires that the column data type be compatible with the value to be set.
   So, if you call querySetCell() on a column containing numbers and set the value to a string, CFMX7 
   will throw a wobbler. Using the CAST() query of query function (newly available in CFMX7) is not 
   reliable because QofQ in CFMX7 fails when one of the columns in the original query is a CLOB (Query 
   Of Queries runtime error. Unsupported SQL type "java.sql.Types.CLOB"). So, to get around that, I'm 
   now creating a new query, initially just with the column whose data type we need to change. The values 
   from the old query for this column are added to the new query one row at a time. The values for all 
   other columns are added using queryAddColumn(). I can't use queryAddColumn() for all columns because 
   you can't create an empty query in CF and populate it with queryAddColumn(). I'm guessing, wildly, 
   that this is more efficient than populating all columns one row at a time. Finally, I can't include a 
   call to queryNew() with the columntypelist parameter specified anywhere in a code block that will be 
   compiled by CFMX6, even if it's within a condition that says only execute this bit if the CF product 
   version is gte 7. This is because CFMX6 doesn't recognise the method signature and will return a 
   parameter validation error. Moving the call to queryNew with the columntypelist parameter specified 
   into a separate custom tag does not result in the same error, presumably because the tag is compiled 
   separately and the parameter validation error will only be picked up if that tag is called by CFMX6.
   Damn, this is messy!!!
 --->
<cfparam name="attributes.query" type="string">
<cfparam name="attributes.column" type="string">
<cfparam name="attributes.type" type="string" default="VARCHAR">

<cfscript>
	// grab a copy of the old query
	qOldContent = duplicate(caller[attributes.query]);
	// create new query, initially with one column, the one we want to cast as varchar
	caller[attributes.query] = queryNew(attributes.column,attributes.type);
	queryAddRow(caller[attributes.query],qOldContent.recordCount);
	for ( i=1; i lte qOldContent.recordCount; i = i+1 ) {
		querySetCell(caller[attributes.query],attributes.column,qOldContent[attributes.column][i],i);
	}
	// add columns to new qContent from qOldContent
	lCols = listDeleteAt(qOldContent.columnList,listFindNoCase(qOldContent.columnList,attributes.column));
	while (lCols neq "") {
		col = listFirst(lCols); lCols = listRest(lCols);
		queryAddColumn(caller[attributes.query],col,qOldContent[col]);
	}
</cfscript>