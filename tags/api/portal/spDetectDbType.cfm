<cfsetting enablecfoutputonly="true">

<cfparam name="attributes.context">
<cfparam name="attributes.r_dbtype">

<cfset dbtype = "ansicompliant"> <!--- start with ansi compliant, only change if we can detect type from database connection metadata --->

<cftry>

	<cfscript>
		serviceFactory = createObject("java", "coldfusion.server.ServiceFactory");
		dataSourceService = serviceFactory.getDataSourceService();
		dataSource = dataSourceService.getDataSource(attributes.context.codb);
		connection = dataSource.getConnection();
		metadata = connection.getMetaData();
		dbname = metadata.getDatabaseProductName();
		if ( findNoCase("MySQL",dbname)  ) {
			dbtype = "mysql";
		} else if ( findNoCase("PostgreSQL",dbname) ) {
			dbtype = "postgresql";
		} else if ( findNoCase("Microsoft",dbname) and findNoCase("SQL Server",dbname) ) {
			dbtype = "sqlserver";
		} else if ( findNoCase("Oracle",dbname) ) {
			dbtype = "oracle";			
		} else if ( findNoCase("Firebird",dbname) ) {
			dbtype = "firebird";
		} else if ( findNoCase("DB2",dbname) ) {
			dbtype = "db2";
		} else if ( findNoCase("Interbase",dbname) ) {
			dbtype = "interbase";
		} else if ( findNoCase("Access",dbname) ) {
			dbtype = "access";
		}
		connection.close();
	</cfscript>
	
<cfcatch>
	
	<cflog type="information" 
		file="#context.appName#" 
		application="no"
		text="CF_SPDETECTDBTYPE: Failed to detect dbtype due to exception #cfcatch.message#.">
	
</cfcatch>
</cftry>

<cfset "caller.#attributes.r_dbtype#" = dbtype>
