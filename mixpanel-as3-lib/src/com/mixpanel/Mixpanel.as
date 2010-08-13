package com.mixpanel
{
	import com.adobe.serialization.json.JSONEncoder;
	
	import flash.events.Event;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Security;

	public class Mixpanel {
		
		private var config:* = {}
		private var super_properties:Object = {"all": {}, "events": {}, "funnels": {}};
		private var token:String;
		private var api_host:String;
		
		public function Mixpanel(token:String) {
			this.token = token;
			var protocol:String = MixpanelUtils.browserProtocol;
			api_host = protocol + '//api.mixpanel.com';
			
			set_config({
				cross_subdomain_cookie: true,
				cookie_name: token,
				test: false
			});
			
			get_super();
		}
		
		public function track(event:String, properties:Object=null, callback:Function=null, type:String=null):void {
			if (!type) { type = "events"; }
			if (!properties) { properties = {}; }
			if (!properties.token) { properties.token = token; }
			properties.time = get_unixtime();
			properties.mp_lib = 'as3';
			var p:*;

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
			
			var data:Object = {
				'event' : event,
				'properties' : properties
			};
			
			var encoded_data:String = base64_encode(json_encode(data)); // Security by obscurity
			
			send_request(
				api_host + '/track/', 
				{
					'data' : encoded_data, 
					'ip' : 1
				},
				callback
			);			
		};
		

		
		public function track_funnel(funnel:String, step:int, goal:String, properties:Object=null, callback:Function=null):void {
			properties = properties || {};
			properties.funnel = funnel;
			properties.step = step;
			properties.goal = goal;
			set_config({'cross_subdomain_cookie': false});
			track('mp_funnel', properties, callback, "funnels");
		};
		

		
		public function identify(person:String):void {
			// Will bind a unique identifer to the user via a cookie (super properties)
			register_once({'distinct_id': person}, 'all');
		};
		
		public function register_once(props:Object, type:String=null, default_value:String=null):void {
			// register properties without overriding
			if (!type || !super_properties[type]) { type = "all"; }
			if (!default_value) { default_value = "None"; }
			
			if (props) {
				for (var p:* in props) {
					if (!super_properties[type][p] || super_properties[type][p] == default_value) {
						super_properties[type][p] = props[p];
					}
				}
			}

			set_cookie(config.cookie_name, super_properties);
		};
		
		public function register(props:Object, type:String=null):void {
			// register a set of super properties to be included in all events and funnels
			if (!type || !super_properties[type]) { type = "all"; }
			
			if (props) {
				for (var p:* in props) {
					super_properties[type][p] = props[p];
				}    
			}
			
			set_cookie(config.cookie_name, super_properties);
		};
		
		private function get_unixtime():int {
			return parseInt(new Date().getTime().toString().substring(0,10), 10);
		};
		
		private function json_encode(mixed_val:*):String {    
			var encoder:JSONEncoder = new JSONEncoder(mixed_val);
			return encoder.getString();
		};
		
		private function base64_encode(data:*):String {        
			var b64:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
			var o1:int, o2:int, o3:int, h1:int, h2:int, h3:int, h4:int, bits:int, i:int = 0, ac:int = 0, enc:String="", tmp_arr:Array = [];
			
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
		
		private function utf8_encode(string:String):String {
			string = (string+'').replace(/\r\n/g, "\n").replace(/\r/g, "\n");
			
			var utftext:String = "";
			var start:int, end:int;
			var stringl:int = 0;
			
			start = end = 0;
			stringl = string.length;
			for (var n:int = 0; n < stringl; n++) {
				var c1:int = string.charCodeAt(n);
				var enc:String = null;
				
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
		
		private function set_cookie(name:String, value:*):void {
			var so:SharedObject = getSharedObject();
			so.data[name] = value;
			so.flush();
		};
		
		private function get_cookie(name:String):Object {
			var so:SharedObject = getSharedObject();
			return so.data[name];
		};
		
		private function delete_cookie(name:String):void {
			var so:SharedObject = getSharedObject();
			delete so.data[name];
			so.flush();
		};
		
		private function getSharedObject():SharedObject {
			// TODO: might be better to key on the token rather
			// than a constant, but this is how it is done in js
			var so:SharedObject = SharedObject.getLocal("mixpanel");
			return so;
		};
		
		private function get_super():Object {
			var cookie_props:Object = get_cookie(config.cookie_name);
			
			if (cookie_props) {
				for (var i:* in cookie_props) {
					super_properties[i] = cookie_props[i]; 
				}
			}
			
			return super_properties;
		};
		
		public function set_config(configuration:Object):void {
			if(configuration.cross_subdomain_cookie != config.cross_subdomain_cookie) {
				try {
					Security.exactSettings = !configuration.cross_subdomain_cookie;
				} catch(e:Error) {}
				
			}
			for (var c:* in configuration) {
				config[c] = configuration[c];
			}
		};
		
		private function send_request(url:String, data:*, callback:Function=null):void {			
			var request:URLRequest = new URLRequest(url);
			request.method = URLRequestMethod.GET;
			var params:URLVariables = new URLVariables();
			
			var key:String = '';
			for(key in data) {
				params[key] = data[key];
			}
			
			if (config.test) { params.test = 1 }
			params["_"] = new Date().getTime().toString();
			request.data = params;
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE,
				function(e:Event):void {
					if(callback != null) {
						callback(loader.data);
					}
				});
			
			loader.load(request);
		};
	}
}