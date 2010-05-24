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
		<cfparam name="stPD.defaultYear" default="">
		
		<cfparam name="stPD.defaultDateAdd" default=""> <!--- use dateAdd to create a default date in the future, value for this attribute is datepart,number --->

		<cfif len(stPD.defaultDateAdd) and not reFind("(yyyy|q|m|y|d|w|ww|h|n|s),-?[0-9]+$",stPD.defaultDateAdd)>

			<cf_spError error="ATTR_INV" lParams="#stPD.defaultDateAdd#,defaultDateAdd" context=#caller.ca.context#>	<!--- Invalid defaultDateAdd format --->
		
		</cfif>
		
		<cfif stPD.defaultCurrent and len(stPD.defaultDateAdd)>
		
			<cf_spError error="ERR_ATTR_MUTEX" lParams="defaultCurrent,defaultDateAdd" context=#caller.ca.context#>
		
		</cfif>
		
		<cfset stPD.index = "yes"> <!--- force indexing on --->
		
		<cfif stPD.displaySize neq 0>
		
			<!--- set displaysize to hold YYYY-MM-DD date string (allow some extra space to make form field look nice :) --->
			<cfset stPD.displaySize = 14>
			
		</cfif>
		
		<cfset stPD.maxLength = 10>
	
	</cf_spPropertyHandlerMethod>
	
	
 	<cf_spPropertyHandlerMethod method="validateValue">
		
		<cfif len(trim(newValue))>
		
			<cfif not reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",newValue)>
			
				<cfset lErrors = request.speck.buildString("P_DATE_INVALID_FORMAT","#stPD.caption#,#newValue#")>
				
			<cfelse>
			
				<cfset thisYear = listFirst(newValue,"-")>
				<cfset thisMonth = listGetAt(newValue,2,"-")>
				<cfset thisDay = listLast(newValue,"-")>
				<cfif len(stPD.yearRange) and ( thisYear lt listFirst(stPD.yearRange) or thisYear gt listLast(stPD.yearRange) )>
					
					<cfset lErrors = request.speck.buildString("P_DATE_INVALID_YEAR","#stPD.caption#,#newValue#,#replace(stPD.yearRange,","," - ")#")>
					
				<cfelseif thisMonth lt 1 or thisMonth gt 12>
					
					<cfset lErrors = request.speck.buildString("P_DATE_INVALID_MONTH","#stPD.caption#,#newValue#")>
					
				<cfelseif thisDay lt 1 or thisDay gt 31>
					
					<cfset lErrors = request.speck.buildString("P_DATE_INVALID_DAY","#stPD.caption#,#newValue#")>
					
				<cfelse>

					<cfset void = setLocale("English (US)")>
					<cfif not isDate("#thisMonth#/#thisDay#/#thisYear#")>
				
						<cfset lErrors = request.speck.buildString("P_DATE_INVALID_DATE","#stPD.caption#,#newValue#,date")>

					</cfif>
					<cfset void = setLocale(request.speck.locale)>
				
				</cfif>
				
			</cfif>
			
		</cfif>
		
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="readFormField">
		
		<cfif not stPD.richEdit and isDefined("form.#stPD.name#_year")>
		
			<cfset yearValue = evaluate("form.#stPD.name#_year")>
			
			<cfif isNumeric(yearValue) and yearValue lt 100>
			
				<!--- two digit year submitted, let's just tidy it up - note hard coded two digit cutoff --->
				<cfif yearValue lt 30>
				
					<cfset yearValue = yearValue + 2000>
					
				<cfelse>
				
					<cfset yearValue = yearValue + 1900>
					
				</cfif>				
			
			</cfif>
		
			<cfset newValue = yearValue & "-" & evaluate("form.#stPD.name#_month") & "-" & evaluate("form.#stPD.name#_day")>
			
			<cfif not reFind("[0-9]{4}-[0-9]{2}-[0-9]{2}",newValue)>
			
				<cfset newValue = "">
				
			</cfif>
			
		<cfelse>
		
			<cfset newValue = value>
			
		</cfif>
	
	</cf_spPropertyHandlerMethod>
	
	
	<cf_spPropertyHandlerMethod method="renderFormField">

		<cfif trim(value) eq "" and ( action eq "add" and cgi.request_method neq "post" )>
			<cfif stPD.defaultCurrent>
				<cfset value = dateFormat(now(),"YYYY-MM-DD")>
			<cfelseif len(stPD.defaultDateAdd)>
				<cfset value = dateFormat(dateAdd(listFirst(stPD.defaultDateAdd),listLast(stPD.defaultDateAdd),now()),"YYYY-MM-DD")>
			</cfif>
		</cfif>
			
		<cfif not stPD.richEdit>
		
			<cfscript>
			/**
			 * Returns the localized version of a month.
			 * Original code + idea from Ben Forta
			 * 
			 * @param month_number 	 The month number. 
			 * @param locale 	 Locale to use. Defaults to current locale. 
			 * @return Returns a string. 
			 * @author Raymond Camden (ray@camdenfamily.com) 
			 * @version 1, July 17, 2001 
			 */
			function LSMonthAsString(month_number) {
				VAR d=CreateDate(2000, month_number, 1);
				VAR oldlocale = "";
				VAR tempstr = "";
				if(ArrayLen(Arguments) eq 2) {
					oldLocale = setLocale(arguments[2]);
					tempstr = LSDateFormat(d,"mmmm");
					setLocale(oldLocale);
				} else {
					tempstr = LSDateFormat(d,"mmmm");
				}
				return tempstr;
			}
			</cfscript>
		
			<cfif reFind("[0-9]{4}-[0-9]{2}-[0-9]{2}",value)>
				<cfparam name="form.#stPD.name#_day" default="#listGetAt(value,3,"-")#">
				<cfparam name="form.#stPD.name#_month" default="#listGetAt(value,2,"-")#">
				<cfparam name="form.#stPD.name#_year" default="#listGetAt(value,1,"-")#">
			<cfelse>
				<cfparam name="form.#stPD.name#_day" default="">
				<cfparam name="form.#stPD.name#_month" default="">
				<cfparam name="form.#stPD.name#_year" default="">
			</cfif>

			<cfset currentDay = evaluate("form.#stPD.name#_day")>
			<cfset currentMonth = evaluate("form.#stPD.name#_month")>
			<cfset currentYear = evaluate("form.#stPD.name#_year")>
			
			<cfif isNumeric(stPD.defaultYear) and not isNumeric(currentYear)>
				<cfset currentYear = stPD.defaultYear>
			</cfif>
		
			<cfoutput>
			<select name="#stPD.name#_day">
			<option value="">Day</option>
			</cfoutput>
			<cfloop from="1" to="31" index="i">
			
				<cfoutput>
				<option value="#numberFormat(i,"0_")#"<cfif i eq currentDay> selected="yes"</cfif>>#i#</option>
				</cfoutput>
			
			</cfloop>
			<cfoutput>
			</select>
			</cfoutput>
			
			<cfoutput>
			<select name="#stPD.name#_month">
			<option value="">Month</option>
			</cfoutput>
			<cfloop from="1" to="12" index="i">
				
				<cfoutput>
				<option value="#numberFormat(i,"0_")#"<cfif numberFormat(i,"0_") eq currentMonth> selected="yes"</cfif>>#lsMonthAsString(i)#</option>
				</cfoutput>
			
			</cfloop>
			<cfoutput>
			</select>
			</cfoutput>
			
			<cfif len(stPD.yearRange)>
			
				<cfoutput>
				<select name="#stPD.name#_year">
				<option value="">Year</option>
				</cfoutput>
				<cfloop from="#listFirst(stPD.yearRange)#" to="#listLast(stPD.yearRange)#" index="i">
				
					<cfoutput>
					<option value="#i#"<cfif i eq currentYear> selected="yes"</cfif>>#i#</option>
					</cfoutput>
				
				</cfloop>
				<cfoutput>
				</select>
				</cfoutput>
				
			<cfelse>
				
				<cfoutput>
				<input type="text" name="#stPD.name#_year" value="<cfif not len(currentYear)>YYYY<cfelse>#currentYear#</cfif>" size="6" maxlength="4" onfocus="if ( this.value == 'YYYY' ) { this.value = ''; }">
				</cfoutput>
				
			</cfif>

			
			<cfoutput>
			<input type="hidden" name="#stPD.name#" id="#stPD.name#" value="#value#">
			</cfoutput>
			
		<cfelse>
			
			<cfoutput>
			<input type="text" name="#stPD.name#" value="#value#" size="#stPD.displaySize#" maxlength="#stPD.maxlength#" style="vertical-align:middle;">
			</cfoutput>
			
			<cfif stPD.richEdit>
			
				<cfset calendarURL = "/speck/properties/date/calendar.html?form=speditform&field=" & stPD.name>
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
					onclick="openCalendar_#stPD.name#(event);return false;"	
					title="#request.speck.buildString("P_DATE_CALENDAR_CAPTION")#"><img src="/speck/properties/date/calendar_blue.gif" border="0" style="vertical-align:middle;"></a>
				</cfoutput>
			
			</cfif>
			
			<cfoutput>
			(#request.speck.buildString("P_DATE_FORMAT_CAPTION")#)
			</cfoutput>
			
		</cfif>
			
	</cf_spPropertyHandlerMethod>
	
	
</cf_spPropertyHandler>