package com.mixpanel
{
	import flash.external.ExternalInterface;
	
	internal class MixpanelUtils
	{
		public static function get browserProtocol():String {
			var https:String = 'https:';
			if (ExternalInterface.available) {
				try {
					return ExternalInterface.call("document.location.protocol.toString") || https;
				} catch (err:Error) {}
			}
			return https;
		}
		
//		public static function pr(obj:*, level:int = 0, output:String = ""):* {
//		    var tabs:String = "";
//		    for(var i:int = 0; i < level; i++, tabs += "\t");
//		    
//		    for(var child:* in obj) {
//		        output += tabs +"["+ child +"] => "+ obj[child];
//		        
//		        var childOutput:String = pr(obj[child], level+1);
//		        if(childOutput != '') output += ' {\n'+ childOutput + tabs +'}';
//		        
//		        output += "\n";
//		    }
//		    
//		    if(level == 0) trace(output);
//		    else return output;
//		 }

	}
}