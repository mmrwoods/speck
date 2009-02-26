<cfsetting enablecfoutputonly="Yes">

<cf_spPropertyHandler>


	<cf_spPropertyHandlerMethod method="validateAttributes">
		
		<cfparam name="stPD.defaultValue" default="">
		
		<cfset stPD.maxLength = 3>
		<cfset stPD.index = true>
		
		<cfif stPD.defaultValue neq "" and ( stPD.defaultValue lt 1 or stPD.defaultValue gt 12 )>
		
			<cf_spError error="ATTR_INV" lParams="#stPD.defaultValue#,defaultValue" context=#caller.ca.context#>
		
		</cfif>
	
		<cfset stPD.databaseColumnType = "integer">
		
		<cfset stPD.maxLength = 2>
			
	</cf_spPropertyHandlerMethod>


	<cf_spPropertyHandlerMethod method="renderFormField">
	
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

		<cfscript>
			size = int(val(listLast(stPD.displaySize)));
			if ( size lt 1 )
				size = stPD.displaySize;
			if ( size gt 10 )
				size = 10;
			
			selectedValue = value;
			if ( not len(selectedValue) and len(stPD.defaultValue) and ( action eq "add" and cgi.request_method neq "post" ) ) {
				selectedValue = stPD.defaultValue;
			}
		</cfscript>
		
		<cfoutput>
		<select name="#stPD.name#">
		</cfoutput>
		
		<cfset forceWidth = "">
		<cfif listLen(stPD.displaySize) eq 2>
		
			<cfscript>
				width = int(val(listFirst(stPD.displaySize)));
				forceWidth = "";
				for (i=1; i lte width; i = i+1)
					forceWidth = forceWidth & "&nbsp;";
			</cfscript>
		
		</cfif>
		
		<!--- throw in an empty option/value --->
		<cfoutput><option value="">#forceWidth#</option></cfoutput>
		
		<cfloop from="1" to="12" index="i">
			
			<cfoutput><option value="#i#"<cfif selectedValue eq i> selected="yes"</cfif>>#lsMonthAsString(i)#</option>#chr(13)##chr(10)#</cfoutput>

		</cfloop>
		
		<cfoutput>
		</select>
		</cfoutput>

	</cf_spPropertyHandlerMethod>
	
	
</cf_spPropertyHandler>