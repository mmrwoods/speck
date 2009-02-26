<cfsetting enablecfoutputonly="Yes">
<!---
This collective work is Copyright (C) 2001-2007 by Robin Hilliard (robin@zeta.org.au) and Mark Woods (mark@thickpaddy.com), 
All Rights Reserved. Individual portions may be copyright by individual contributors, and are included in this collective 
work with permission of the copyright owners.

Licensed under the Academic Free License version 2.1
--->
<!---
a simple login script example, move it to the application web root 
and there'll be no need to provide the app name as a url parameter

Attributes:
	url.app(string, required): name of app
--->

<cfparam name="form.spLogonUser" default="">
<cfparam name="form.spLogonPassword" default="">
<cfparam name="url.redirect_to" default="#request.speck.appWebRoot#/">
<cfparam name="form.redirect_to" default="#url.redirect_to#">

<cfoutput>
<html>
<head>
	<title>Login</title>
	<link rel="stylesheet" href="#request.speck.adminStylesheet#" type="text/css" />
	<style type="text/css">
	body { text-align:center; }
	##container{
		width:350px;
		margin-top:100px;
		margin-left:auto;
		margin-right:auto;
		text-align:left;
	}
	</style>
</head>
<body>
<div id="container">
</cfoutput>

<cfif request.speck.session.auth eq "logon" 
	and cgi.request_method eq "post" 
	and not isDefined("request.speck.failedLogon")>
	
	<cfheader name="Refresh" value="2;url=#form.redirect_to#">
	<cfoutput>
	<h1>Login successful, please wait...</h1>
	<p>If the next page does not load automatically, <a href="#form.redirect_to#">click here</a></p>
	</cfoutput>

<cfelse>

	<cfoutput>
	<script type="text/javascript">
		<!--
		//<![CDATA[
		window.onload = function () { document.spLogonForm.spLogonUser.focus() };
		//]]>
		//-->
	</script>
	<form name="spLogonForm" action="#cgi.script_name#?#cgi.query_string#" method="post">
	<input type="hidden" name="redirect_to" value="#form.redirect_to#" />
	<p>Enter your username and password to login:</p>
	<cfif isDefined("request.speck.failedLogon")>
		<cfif structKeyExists(request.speck,"failedLogonMessage")>
			<strong style="color:red;">Login failed, #lCase(request.speck.failedLogonMessage)#</strong>
		<cfelse>
			<strong style="color:red;">Login failed, please try again...</strong>
		</cfif>
	</cfif>
	<table>
		<tr>
		<td style="vertical-align:middle;"><label for="spLogonUser">Username</label></td>
		<td><input type="text" name="spLogonUser" id="spLogonUser" value="#form.spLogonUser#" size="25" maxlength="20"></td>
		</tr>
		<tr>
		<td style="vertical-align:middle;"><label for="spLogonPassword">Password</label></td>
		<td><input type="password" name="spLogonPassword" id="spLogonPassword" value="#form.spLogonPassword#" size="25" maxlength="100"></td>
		</tr>
		<tr>
		<td colspan="2" align="right"><input type="submit" value="Login" class="button"></td>
		</tr>	
	</table>
	</form>
	</cfoutput>

</cfif>

<cfoutput>
</div>
</body>
</html>
</cfoutput>
