// hacked version of sleight that no longer requires x.gif file and adds code to fix unclickable links issue in IE
// Not exhaustively tested, may not work in certain circumstances
var bgsleight	= function() {
	
	function addLoadEvent(func) {
		var oldonload = window.onload;
		if (typeof window.onload != 'function') {
			window.onload = func;
		} else {
			window.onload = function() {
				if (oldonload) {
					oldonload();
				}
				func();
			}
		}
	}
	
	function fnLoadPngs() {
		var rslt = navigator.appVersion.match(/MSIE (\d+\.\d+)/, '');
		var itsAllGood = (rslt != null && Number(rslt[1]) >= 5.5);
		for (var i = document.all.length - 1, obj = null; (obj = document.all[i]); i--) {
			if (itsAllGood && obj.currentStyle.backgroundImage.match(/\.png/i) != null) {
				fnFixPng(obj);
				obj.attachEvent("onpropertychange", fnPropertyChanged);
			}
		}
	}

	function fnPropertyChanged() {
		if (window.event.propertyName == "style.backgroundImage") {
			var el = window.event.srcElement;
			if (!el.currentStyle.backgroundImage.match(/x\.gif/i)) {
				var bg	= el.currentStyle.backgroundImage;
				var src = bg.substring(5,bg.length-2);
				el.filters.item(0).src = src;
				//el.style.backgroundImage = "url(/speck/javascripts/x.gif)";
				el.style.backgroundImage = "none";
			}
		}
	}

	function fnFixPng(obj) {
		var bg	= obj.currentStyle.backgroundImage;
		var src = bg.substring(5,bg.length-2);
		obj.style.filter = "progid:DXImageTransform.Microsoft.AlphaImageLoader(src='" + src + "', sizingMethod='scale')";
		//obj.style.backgroundImage = "url(/speck/javascripts/x.gif)";
		obj.style.backgroundImage = "none";
		if (obj.currentStyle.width == 'auto' && obj.currentStyle.height == 'auto')
    		obj.style.width = obj.offsetWidth + 'px';
		// IE link fix.
		for (var n = 0; n < obj.childNodes.length; n++)
    		if (obj.childNodes[n].style) obj.childNodes[n].style.position = 'relative';
		
	}
	
	
	return {
		
		init: function() {
			
			if (navigator.platform == "Win32" && navigator.appName == "Microsoft Internet Explorer" && window.attachEvent) {
				addLoadEvent(fnLoadPngs);
			}
			
		}
	}
	
}();

bgsleight.init();