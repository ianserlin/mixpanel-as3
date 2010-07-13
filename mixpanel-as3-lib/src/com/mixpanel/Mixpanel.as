package com.mixpanel
{
	import com.adobe.serialization.json.JSONEncoder;
	
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Security;

	public class Mixpanel 
	{
		private var config:* = {}
		
		private var super_properties:Object = {"all": {}, "events": {}, "funnels": {}};
		
		/*
		Pre-defined funnels:
		{
		'funnel_name': ['Event1', 'Event2', 'Event3'],
		'funnel_name2': ['Event1', 'Event3'] // 'Event3' is step 2 and step 3 in two different funnels.
		}
		*/
		private var funnels:Object = {};
		
		private var token:String;
		private var api_host:String;
		
		public function Mixpanel(token:String) {
			
			var mp_protocol:String = null;
			
			if(MixpanelUtils.inBrowser) {
				var browserProtocol:String = MixpanelUtils.browserProtocol;
				mp_protocol = (("https:" == browserProtocol) ? "https://" : "http://");
			} else {
				mp_protocol = "http://";
			}
			
			this.token = token;
			api_host = mp_protocol + 'api.mixpanel.com';
			
			set_config({
				cross_subdomain_cookie: true,
				cookie_name: "mp_super_properties",
				test: false
			});
			
			try {
				get_super();
			} catch(err) {}
		}
		
		private function send_request(url, data, callback:Function=null) {

			var request:URLRequest = new URLRequest(url);
			request.method = URLRequestMethod.GET;
			
			var params:URLVariables = new URLVariables();
			for(var key in data) {
				params[key] = data[key];
			}
			if (config.test) { params.test = 1 }
			params["_"] = new Date().getTime().toString();
			request.data = params;
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE,
				function(e:Event):void {
					if(callback) {
						callback(loader.data);
					}
				});
			
			loader.load(request);
		}
		
		public function track_funnel(funnel:String, step:int, goal:String, properties:Object=null, callback:Function=null) {
			if (! properties) { properties = {}; } 
			
			properties.funnel = funnel;
			properties.step = step;
			properties.goal = goal;
			
			// If step 1 of the funnel, super property track the search keyword throughout the funnel automatically
			if (properties.step == 1) {
				// Only google for now
				if(MixpanelUtils.inBrowser) {
					var referrer:String = MixpanelUtils.browserReferrer;
					if (referrer.search('http://(.*)google.com') === 0) {
						var keyword = get_query_param(referrer, 'q');
						if (keyword.length) {
							register({'mp_keyword' : keyword}, 'funnels');
						}
					}
				}
			}
			
			track('mp_funnel', properties, callback, "funnels");
		};
		
		private function get_query_param(url, param) {
			// Expects a raw URL
			
			param = param.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
			var regexS = "[\\?&]" + param + "=([^&#]*)";
			var regex = new RegExp( regexS );
			var results = regex.exec(url);
			if (results === null || (results && typeof(results[1]) != 'string' && results[1].length)) {
				return '';
			} else {
				return unescape(results[1]).replace(/\+/g, ' ');
			}
		};
		
		public function track(event:String, properties:Object=null, callback:Function=null, type:String=null) {
			if (!type) { type = "events"; }
			if (!properties) { properties = {}; }
			if (!properties.token) { properties.token = token; }
			properties.time = get_unixtime();
			
			var p;
			
			// First add specific super props
			if (type != "all") {
				for (p in super_properties[type]) {
					if (!properties[p]) {                
						properties[p] = super_properties[type][p];
					}
				}
			}
			
			// Then add any general supers that were not in specific 
			if (super_properties.all) {
				for (p in super_properties.all) {
					if (!properties[p]) {
						properties[p] = super_properties.all[p];
					}
				}
			}
			
			var data = {
				'event' : event,
				'properties' : properties
			};
			
			var encoded_data = base64_encode(json_encode(data)); // Security by obscurity
			
			send_request(
				api_host + '/track/', 
				{
					'data' : encoded_data, 
					'ip' : 1
				},
				callback
			);
			
			track_predefined_funnels(event, properties);
		};
		
		public function identify(person:Object) {
			// Will bind a unique identifer to the user via a cookie (super properties)
			register_once({'distinct_id': person}, 'all');
		};
		
		public function register_once(props:Object, type:String=null, default_value:String=null) {
			// register properties without overriding
			if (!type || !super_properties[type]) { type = "all"; }
			if (!default_value) { default_value = "None"; }
			
			if (props) {
				for (var p in props) {
					if (p) {
						if (!super_properties[type][p] || super_properties[type][p] == default_value) {
							super_properties[type][p] = props[p];
						}
					}
				}
			}
			if (config.cross_subdomain_cookie) { clear_old_cookie(); }
			set_cookie(config.cookie_name, super_properties);
		};
		
		public function register(props:Object, type:String=null) {
			// register a set of super properties to be included in all events and funnels
			if (!type || !super_properties[type]) { type = "all"; }
			
			if (props) {
				for (var p in props) {
					if (p) {
						super_properties[type][p] = props[p];
					}
				}    
			}
			
			if (config.cross_subdomain_cookie) { clear_old_cookie(); }
			set_cookie(config.cookie_name, super_properties);
		};
		
		private function get_unixtime() {
			return parseInt(new Date().getTime().toString().substring(0,10), 10);
		};
		
		private function json_encode(mixed_val):String {    
			var encoder:JSONEncoder = new JSONEncoder(mixed_val);
			return encoder.getString();
		};
		
		private function base64_encode(data) {        
			var b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
			var o1, o2, o3, h1, h2, h3, h4, bits, i = 0, ac = 0, enc="", tmp_arr = [];
			
			if (!data) {
				return data;
			}
			
			data = utf8_encode(data+'');
			
			do { // pack three octets into four hexets
				o1 = data.charCodeAt(i++);
				o2 = data.charCodeAt(i++);
				o3 = data.charCodeAt(i++);
				
				bits = o1<<16 | o2<<8 | o3;
				
				h1 = bits>>18 & 0x3f;
				h2 = bits>>12 & 0x3f;
				h3 = bits>>6 & 0x3f;
				h4 = bits & 0x3f;
				
				// use hexets to index into b64, and append result to encoded string
				tmp_arr[ac++] = b64.charAt(h1) + b64.charAt(h2) + b64.charAt(h3) + b64.charAt(h4);
			} while (i < data.length);
			
			enc = tmp_arr.join('');
			
			switch( data.length % 3 ){
				case 1:
					enc = enc.slice(0, -2) + '==';
					break;
				case 2:
					enc = enc.slice(0, -1) + '=';
					break;
			}
			
			return enc;
		};
		
		private function utf8_encode (string) {
			string = (string+'').replace(/\r\n/g, "\n").replace(/\r/g, "\n");
			
			var utftext = "";
			var start, end;
			var stringl = 0;
			
			start = end = 0;
			stringl = string.length;
			for (var n = 0; n < stringl; n++) {
				var c1 = string.charCodeAt(n);
				var enc = null;
				
				if (c1 < 128) {
					end++;
				} else if((c1 > 127) && (c1 < 2048)) {
					enc = String.fromCharCode((c1 >> 6) | 192) + String.fromCharCode((c1 & 63) | 128);
				} else {
					enc = String.fromCharCode((c1 >> 12) | 224) + String.fromCharCode(((c1 >> 6) & 63) | 128) + String.fromCharCode((c1 & 63) | 128);
				}
				if (enc !== null) {
					if (end > start) {
						utftext += string.substring(start, end);
					}
					utftext += enc;
					start = end = n+1;
				}
			}
			
			if (end > start) {
				utftext += string.substring(start, string.length);
			}
			
			return utftext;
		};
		
		private function set_cookie(name, value) {
			
			// TODO: might be better to key on the token rather
			// than a constant, but this is how it is done in js
			var so:SharedObject = getSharedObject();
			so.data[name] = value;
			so.flush();
		};
		
		private function get_cookie(name) {
			var so:SharedObject = getSharedObject();
			return so.data[name];
		};
		
		private function delete_cookie(name, cross_subdomain) {
			var so:SharedObject = getSharedObject();
			delete so.data[name];
			so.flush();
		};
		
		private function getSharedObject():SharedObject {
			// TODO: might be better to key on the token rather
			// than a constant, but this is how it is done in js
			var so:SharedObject = SharedObject.getLocal("mixpanel");
			return so;
		}
		
		private function parse_domain(url) {
			var matches = url.match(/[a-z0-9][a-z0-9\-]+\.[a-z\.]{2,6}$/i);
			return matches ? matches[0] : '';
		};
		
		private function get_super() {
			var cookie_props = get_cookie(config.cookie_name);
			
			if (cookie_props) {
				for (var i in cookie_props) {
					if (i) { 
						super_properties[i] = cookie_props[i]; 
					}
				}
			}
			
			return super_properties;
		};
		
		public function register_funnel(funnel_name, steps) {
			funnels[funnel_name] = steps;
		};
		
		private function track_predefined_funnels(event, properties) {
			if (event && funnels) {
				for (var funnel in funnels) {
					if (funnel) {
						for (var i = 0; i < funnels[funnel].length; ++i) {
							if (funnels[funnel][i]) {
								if (funnels[funnel][i] == event) {
									// Somewhat inefficient, todo: batch requests one day?
									track_funnel(funnel, i+1, event, properties);
								}
							}
						}
					}
				}
			}
		};
		
		private function clear_old_cookie() {
			// Delete old non-crossdomain cookie
			delete_cookie(config.cookie_name, false);
			// Save the new cookie with domain=.example.com (works across subdomains)
			set_cookie(config.cookie_name, super_properties);
		};
		
		public function set_config(configuration) {
			if(configuration.cross_subdomain_cookie && configuration.cross_subdomain_cookie != config.cross_subdomain_cookie) {
				try {
					Security.exactSettings = configuration.cross_subdomain_cookie ? true : false;
				} catch(e:Error) {
					trace("Error: The config cross_subdomain_cookie can only be set once in an application.", e.getStackTrace());
				}
			}
			for (var c in configuration) {
				if (c) {
					config[c] = configuration[c];
				}
			}
		};
		
		
	}
}