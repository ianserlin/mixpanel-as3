package com.mixpanel
{
	import flash.external.ExternalInterface;

	internal class MixpanelUtils
	{
		public static function get browserProtocol():String {
			return ExternalInterface.call("document.location.protocol.toString");
		}
		
		public static function get browserReferrer():String {
			return ExternalInterface.call("document.referrer.toString");
		}
		
		public static function get inBrowser():Boolean {
			return ExternalInterface.available;
		}
	}
}