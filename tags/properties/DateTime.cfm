<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->

<cf_spPropertyHandler>


	<cf_spPropertyHandlerMethod method="validateAttributes">

		<cfparam name="stPD.richEdit" default="false" type="boolean">
		
		<!--- check format of yearRange, must be YYYY,YYYY --->
		<cfparam name="stPD.yearRange" default="">
		
		<cfif len(stPD.yearRange) and not reFind("^[0-9]{4},[0-9]{4}$",stPD.yearRange)>
		
			<cf_spError error="ATTR_INV" lParams="#stPD.yearRange#,yearRange" context=#caller.ca.context#>	<!--- Invalid yearRange format --->
		
		</cfif>

		<cfparam name="stPD.defaultCurrent" default="false" type="boolean">
		
		<cfparam name="stPD.defaultTimeValue" default="">
		<cfif len(stPD.defaultTimeValue)>
		
			<cfif not reFind("^[0-9]{2}:[0-9]{2}$",stPD.defaultTimeValue)>

				<cf_spError error="ATTR_INV" lParams="#stPD.defaultTimeValue#,defaultTimeValue" context=#caller.ca.context#>
						
			<cfelseif ( listFirst(stPD.defaultTimeValue,":") lt 0 or listFirst(stPD.defaultTimeValue,":") gt 23 )
				or ( listLast(stPD.defaultTimeValue,":") lt 0 or listLast(stPD.defaultTimeValue,":") gt 59 )>
			
				<cf_spError error="ATTR_INV" lParams="#stPD.defaultTimeValue#,defaultTimeValue" context=#caller.ca.context#>
			
			</cfif>		

		</cfif>		
		
		<cfparam name="stPD.time" default="">
		<cfif len(stPD.time)>
			
			<cfif not reFind("^[0-9]{2}\:[0-9]{2}$",stPD.time)>

				<cf_spError error="ATTR_INV" lParams="#stPD.time#,time" context=#caller.ca.context#>	<!--- Invalid time format --->
						
			<cfelseif ( listFirst(stPD.time,":") lt 0 or listFirst(stPD.time,":") gt 23 )
				or ( listLast(stPD.time,":") lt 0 or listLast(stPD.time,":") gt 59 )>
			
				<cf_spError error="ATTR_INV" lParams="#stPD.time#,time" context=#caller.ca.context#>	<!--- Invalid time --->
			
			</cfif>
			
			<cfif stPD.displaySize neq 0>
			
				<!--- set displaysize to hold YYYY:MM:DD date string (allow some extra space to make form field look nice :) --->
				<cfset stPD.displaySize = 14>
				
			</cfif>
			
		<cfelse>
		
			<cfif stPD.displaySize neq 0>
		
				<!--- set displaysize to hold YYYY:MM:DD HH:mm datetime string (allow some extra space to make form field look nice :) --->
				<cfset stPD.displaySize = 20>
				
			</cfif>
			
		</cfif>
		
		<cfset stPD.maxLength = 26> <!--- maxlength needs to be enough to hold ODBC timestamp string --->
		
		<cfset stPD.databaseColumnType = "datetime">
		
	</cf_spPropertyHandlerMethod>
	
 	
	<cf_spPropertyHandlerMethod method="readFormField">
	
		<cfscript>
			newValue = value;
			if ( len(trim(newValue)) ) {
				// force time?
				if ( len(stPD.time) ) { newValue = left(newValue,10) & " " & stPD.time; }
				// readFormField always returns newValue as an ODBC timestamp string
				if ( isDate(newValue) ) {
					newValue = createODBCDateTime(newValue);
				} else {
					newValue = "{ts '" & left(newValue,16) & ":00'}"; 
				}
			}
		</cfscript>
	
	</cf_spPropertyHandlerMethod>
	
	
 	<cf_spPropertyHandlerMethod method="validateValue">
	
		<cfscript>
		
			if ( len(trim(newValue)) ) {
			
				errValue = replace(replace(newValue,"{ts '",""),":00'}","");				
			
				if ( not reFind("^\{ts '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'\}$",newValue) ) {
				
					if ( len(stPD.time) )
						lErrors = request.speck.buildString("P_DATE_INVALID_FORMAT","#stPD.caption#,#errValue#");
						
					else
						lErrors = request.speck.buildString("P_DATETIME_INVALID_FORMAT","#stPD.caption#,#errValue#");
				
				} else {
	
					// split date and time
					thisDate = mid(newValue,6,10);
					thisTime = mid(newValue,17,5);
					// date parts
					thisYear = listFirst(thisDate,"-");
					thisMonth = listGetAt(thisDate,2,"-");
					thisDay = listLast(thisDate,"-");
	
					// what does the user think they are submitting, date or datetime?
					if ( len(stPD.time) ) {
						userValue = thisDate;
						userType = "date";
					} else {
						userValue = thisDate & " " & thisTime;
						userType = "datetime";
					}
						
					if ( len(stPD.yearRange) and ( thisYear lt listFirst(stPD.yearRange) or thisYear gt listLast(stPD.yearRange) ) ) {
						lErrors = request.speck.buildString("P_DATE_INVALID_YEAR","#stPD.caption#,#errValue#,#replace(stPD.yearRange,","," - ")#");
					} else if ( thisMonth lt 1 or thisMonth gt 12 ) {
						lErrors = request.speck.buildString("P_DATE_INVALID_MONTH","#stPD.caption#,#errValue#");
					} else if ( thisDay lt 1 or thisDay gt 31 ) {
						lErrors = request.speck.buildString("P_DATE_INVALID_DAY","#stPD.caption#,#errValue#");
					} else {
						setLocale("English (US)");
						if ( not isDate("#thisMonth#/#thisDay#/#thisYear# #thisTime#") )
							lErrors = request.speck.buildString("P_DATE_INVALID_DATE","#stPD.caption#,#errValue#,#userType#");
						setLocale(request.speck.locale);
					}
				}
			}
		</cfscript>
		
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="renderFormField">

		<!--- format value --->
		<cfscript>
			if ( isDate(value) )
			
				// we have a value, format it
				if ( len(stPD.time) ) 
					// time property exists, user only provides a date
					value = dateFormat(value,"YYYY-MM-DD");
				else 
					// no time property, user provides date and time
					value = dateFormat(value,"YYYY-MM-DD") & " " & timeFormat(value,"HH:mm");
				
			else if ( stPD.defaultCurrent and ( action eq "add" and cgi.request_method neq "post" ) )
			
				// no value, format current date/datetime for use in form field
				if ( len(stPD.time) ) 
					value = dateFormat(now(),"YYYY-MM-DD");
				else {
					// default according to defaultTimeValue attribute...
					if ( len(stPD.defaultTimeValue) )
						value = dateFormat(now(),"YYYY-MM-DD") & " " & stPD.defaultTimeValue;
					else
						value = dateFormat(now(),"YYYY-MM-DD") & " " & timeFormat(now(),"HH:mm");
				}
				
			if ( len(stPD.time) ) // use date calendar if user can only enter the date
				calendarURL = "/speck/properties/date/calendar.html?form=speditform&field=" & stPD.name;
			else {
				if ( len(stPD.defaultTimeValue) )
					calendarURL = "/speck/properties/datetime/calendar.html?form=speditform&field=" & stPD.name & "&defaultTime=" & URLEncodedFormat(stPD.defaultTimeValue);
				else
					calendarURL = "/speck/properties/datetime/calendar.html?form=speditform&field=" & stPD.name & "&defaultTime=" & URLEncodedFormat(timeFormat(now(),"HH:mm"));
			}
		</cfscript>
						
		<cfoutput><input type="text" name="#stPD.name#" value="#value#" size="#stPD.displaySize#" maxlength="#stPD.maxlength#" style="vertical-align:middle;"></cfoutput>			
		
		<cfif stPD.richEdit>
			<cfoutput>
			<script language="JavaScript">
				function openCalendar_#stPD.name#(e) {
					if (!e) var e = window.event;
					var calendarWindow = window.open('#calendarURL#','calendar','width=225,height=160,left=' + e.screenX +',top=' + e.screenY + ',screenX=' + e.screenX +',screenY=' + e.screenY);
					calendarWindow.focus();
					return false;
				}		
			</script>
			<a href="javascript:return false;" 
				onclick="openCalendar_#stPD.name#(event);return false"		
				title="#request.speck.buildString("P_DATE_CALENDAR_CAPTION")#"><img src="/speck/properties/datetime/calendar_blue.gif" border="0" style="vertical-align:middle;"></a>
			</cfoutput>
		</cfif>

		<cfif len(stPD.time)>
		
			<cfoutput>(#request.speck.buildString("P_DATE_FORMAT_CAPTION")#)</cfoutput>
			
		<cfelse>
		
			<cfoutput>(#request.speck.buildString("P_DATETIME_FORMAT_CAPTION")#)</cfoutput>
		
		</cfif>
			
	</cf_spPropertyHandlerMethod>
	
	
</cf_spPropertyHandler>