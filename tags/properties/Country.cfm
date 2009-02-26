<cfsetting enablecfoutputonly="Yes">

<cf_spPropertyHandler>

	<cf_spPropertyHandlerMethod method="validateAttributes">
		
		<cfparam name="stPD.defaultValue" default="">
		
		<cfset stPD.maxLength = 3>
		<cfset stPD.index = true>
			
	</cf_spPropertyHandlerMethod>


	<cf_spPropertyHandlerMethod method="renderFormField">
	
		<!--- ISO 3166-1 Alpha2 Country Codes - possible TODO: allow these to be loaded from a countries config file --->
		<cfscript>
			stCountries = structNew();
			stCountries.af = "Afghanistan";
			stCountries.ax = "&Aring;land Islands";
			stCountries.al = "Albania";
			stCountries.dz = "Algeria";
			stCountries.as = "American Samoa";
			stCountries.ad = "Andorra";
			stCountries.ao = "Angola";
			stCountries.ai = "Anguilla";
			stCountries.aq = "Antarctica";
			stCountries.ag = "Antigua And Barbuda";
			stCountries.ar = "Argentina";
			stCountries.am = "Armenia";
			stCountries.aw = "Aruba";
			stCountries.au = "Australia";
			stCountries.at = "Austria";
			stCountries.az = "Azerbaijan";
			stCountries.bs = "Bahamas";
			stCountries.bh = "Bahrain";
			stCountries.bd = "Bangladesh";
			stCountries.bb = "Barbados";
			stCountries.by = "Belarus";
			stCountries.be = "Belgium";
			stCountries.bz = "Belize";
			stCountries.bj = "Benin";
			stCountries.bm = "Bermuda";
			stCountries.bt = "Bhutan";
			stCountries.bo = "Bolivia";
			stCountries.ba = "Bosnia And Herzegovina";
			stCountries.bw = "Botswana";
			stCountries.bv = "Bouvet Island";
			stCountries.br = "Brazil";
			stCountries.io = "British Indian Ocean Territory";
			stCountries.bn = "Brunei Darussalam";
			stCountries.bg = "Bulgaria";
			stCountries.bf = "Burkina Faso";
			stCountries.bi = "Burundi";
			stCountries.kh = "Cambodia";
			stCountries.cm = "Cameroon";
			stCountries.ca = "Canada";
			stCountries.cv = "Cape Verde";
			stCountries.ky = "Cayman Islands";
			stCountries.cf = "Central African Republic";
			stCountries.td = "Chad";
			stCountries.cl = "Chile";
			stCountries.cn = "China";
			stCountries.cx = "Christmas Island";
			stCountries.cc = "Cocos (Keeling) Islands";
			stCountries.co = "Colombia";
			stCountries.km = "Comoros";
			stCountries.cg = "Congo";
			stCountries.cd = "Congo, The Democratic Republic Of The";
			stCountries.ck = "Cook Islands";
			stCountries.cr = "Costa Rica";
			stCountries.ci = "Cote D'Ivoire";
			stCountries.hr = "Croatia";
			stCountries.cu = "Cuba";
			stCountries.cy = "Cyprus";
			stCountries.cz = "Czech Republic";
			stCountries.dk = "Denmark";
			stCountries.dj = "Djibouti";
			stCountries.dm = "Dominica";
			stCountries.do = "Dominican Republic";
			stCountries.ec = "Ecuador";
			stCountries.eg = "Egypt";
			stCountries.sv = "El Salvador";
			stCountries.gq = "Equatorial Guinea";
			stCountries.er = "Eritrea";
			stCountries.ee = "Estonia";
			stCountries.et = "Ethiopia";
			stCountries.fk = "Falkland Islands (Malvinas)";
			stCountries.fo = "Faroe Islands";
			stCountries.fj = "Fiji";
			stCountries.fi = "Finland";
			stCountries.fr = "France";
			stCountries.gf = "French Guiana";
			stCountries.pf = "French Polynesia";
			stCountries.tf = "French Southern Territories";
			stCountries.ga = "Gabon";
			stCountries.gm = "Gambia";
			stCountries.ge = "Georgia";
			stCountries.de = "Germany";
			stCountries.gh = "Ghana";
			stCountries.gi = "Gibraltar";
			stCountries.gr = "Greece";
			stCountries.gl = "Greenland";
			stCountries.gd = "Grenada";
			stCountries.gp = "Guadeloupe";
			stCountries.gu = "Guam";
			stCountries.gt = "Guatemala";
			stCountries.gg = "Guernsey";
			stCountries.gn = "Guinea";
			stCountries.gw = "Guinea-Bissau";
			stCountries.gy = "Guyana";
			stCountries.ht = "Haiti";
			stCountries.hm = "Heard Island And Mcdonald Islands";
			stCountries.va = "Holy See (Vatican City State)";
			stCountries.hn = "Honduras";
			stCountries.hk = "Hong Kong";
			stCountries.hu = "Hungary";
			stCountries.is = "Iceland";
			stCountries.in = "India";
			stCountries.id = "Indonesia";
			stCountries.ir = "Iran, Islamic Republic Of";
			stCountries.iq = "Iraq";
			stCountries.ie = "Ireland";
			stCountries.im = "Isle Of Man";
			stCountries.il = "Israel";
			stCountries.it = "Italy";
			stCountries.jm = "Jamaica";
			stCountries.jp = "Japan";
			stCountries.je = "Jersey";
			stCountries.jo = "Jordan";
			stCountries.kz = "Kazakhstan";
			stCountries.ke = "Kenya";
			stCountries.ki = "Kiribati";
			stCountries.kp = "Korea, Democratic People'S Republic Of";
			stCountries.kr = "Korea, Republic Of";
			stCountries.kw = "Kuwait";
			stCountries.kg = "Kyrgyzstan";
			stCountries.la = "Lao People'S Democratic Republic";
			stCountries.lv = "Latvia";
			stCountries.lb = "Lebanon";
			stCountries.ls = "Lesotho";
			stCountries.lr = "Liberia";
			stCountries.ly = "Libyan Arab Jamahiriya";
			stCountries.li = "Liechtenstein";
			stCountries.lt = "Lithuania";
			stCountries.lu = "Luxembourg";
			stCountries.mo = "Macao";
			stCountries.mk = "Macedonia, The Former Yugoslav Republic Of";
			stCountries.mg = "Madagascar";
			stCountries.mw = "Malawi";
			stCountries.my = "Malaysia";
			stCountries.mv = "Maldives";
			stCountries.ml = "Mali";
			stCountries.mt = "Malta";
			stCountries.mh = "Marshall Islands";
			stCountries.mq = "Martinique";
			stCountries.mr = "Mauritania";
			stCountries.mu = "Mauritius";
			stCountries.yt = "Mayotte";
			stCountries.mx = "Mexico";
			stCountries.fm = "Micronesia, Federated States Of";
			stCountries.md = "Moldova, Republic Of";
			stCountries.mc = "Monaco";
			stCountries.mn = "Mongolia";
			stCountries.me = "Montenegro";
			stCountries.ms = "Montserrat";
			stCountries.ma = "Morocco";
			stCountries.mz = "Mozambique";
			stCountries.mm = "Myanmar";
			stCountries.na = "Namibia";
			stCountries.nr = "Nauru";
			stCountries.np = "Nepal";
			stCountries.nl = "Netherlands";
			stCountries.an = "Netherlands Antilles";
			stCountries.nc = "New Caledonia";
			stCountries.nz = "New Zealand";
			stCountries.ni = "Nicaragua";
			stCountries.ne = "Niger";
			stCountries.ng = "Nigeria";
			stCountries.nu = "Niue";
			stCountries.nf = "Norfolk Island";
			stCountries.mp = "Northern Mariana Islands";
			stCountries.no = "Norway";
			stCountries.om = "Oman";
			stCountries.pk = "Pakistan";
			stCountries.pw = "Palau";
			stCountries.ps = "Palestinian Territory, Occupied";
			stCountries.pa = "Panama";
			stCountries.pg = "Papua New Guinea";
			stCountries.py = "Paraguay";
			stCountries.pe = "Peru";
			stCountries.ph = "Philippines";
			stCountries.pn = "Pitcairn";
			stCountries.pl = "Poland";
			stCountries.pt = "Portugal";
			stCountries.pr = "Puerto Rico";
			stCountries.qa = "Qatar";
			stCountries.re = "Reunion";
			stCountries.ro = "Romania";
			stCountries.ru = "Russian Federation";
			stCountries.rw = "Rwanda";
			stCountries.sh = "Saint Helena";
			stCountries.kn = "Saint Kitts And Nevis";
			stCountries.lc = "Saint Lucia";
			stCountries.pm = "Saint Pierre And Miquelon";
			stCountries.vc = "Saint Vincent And The Grenadines";
			stCountries.ws = "Samoa";
			stCountries.sm = "San Marino";
			stCountries.st = "Sao Tome And Principe";
			stCountries.sa = "Saudi Arabia";
			stCountries.sn = "Senegal";
			stCountries.rs = "Serbia";
			stCountries.sc = "Seychelles";
			stCountries.sl = "Sierra Leone";
			stCountries.sg = "Singapore";
			stCountries.sk = "Slovakia";
			stCountries.si = "Slovenia";
			stCountries.sb = "Solomon Islands";
			stCountries.so = "Somalia";
			stCountries.za = "South Africa";
			stCountries.gs = "South Georgia And The South Sandwich Islands";
			stCountries.es = "Spain";
			stCountries.lk = "Sri Lanka";
			stCountries.sd = "Sudan";
			stCountries.sr = "Suriname";
			stCountries.sj = "Svalbard And Jan Mayen";
			stCountries.sz = "Swaziland";
			stCountries.se = "Sweden";
			stCountries.ch = "Switzerland";
			stCountries.sy = "Syrian Arab Republic";
			stCountries.tw = "Taiwan, Province Of China";
			stCountries.tj = "Tajikistan";
			stCountries.tz = "Tanzania, United Republic Of";
			stCountries.th = "Thailand";
			stCountries.tl = "Timor-Leste";
			stCountries.tg = "Togo";
			stCountries.tk = "Tokelau";
			stCountries.to = "Tonga";
			stCountries.tt = "Trinidad And Tobago";
			stCountries.tn = "Tunisia";
			stCountries.tr = "Turkey";
			stCountries.tm = "Turkmenistan";
			stCountries.tc = "Turks And Caicos Islands";
			stCountries.tv = "Tuvalu";
			stCountries.ug = "Uganda";
			stCountries.ua = "Ukraine";
			stCountries.ae = "United Arab Emirates";
			stCountries.gb = "United Kingdom";
			stCountries.us = "United States";
			stCountries.um = "United States Minor Outlying Islands";
			stCountries.uy = "Uruguay";
			stCountries.uz = "Uzbekistan";
			stCountries.vu = "Vanuatu";
			stCountries.ve = "Venezuela";
			stCountries.vn = "Viet Nam";
			stCountries.vg = "Virgin Islands, British";
			stCountries.vi = "Virgin Islands, U.S.";
			stCountries.wf = "Wallis And Futuna";
			stCountries.eh = "Western Sahara";
			stCountries.ye = "Yemen";
			stCountries.zm = "Zambia";
			stCountries.zw = "Zimbabwe";
			
			aCodes = structSort(stCountries);
			
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
		
		<cfloop from="1" to="#arrayLen(aCodes)#" index="i">
		
			<cfset code = lCase(aCodes[i])>
			
			<cfoutput><option value="#code#"<cfif listFind(selectedValue,code)> selected="yes"</cfif>>#stCountries[code]#</option>#chr(13)##chr(10)#</cfoutput>

		</cfloop>
		
		<cfoutput>
		</select>
		</cfoutput>

	</cf_spPropertyHandlerMethod>
	
	
</cf_spPropertyHandler>