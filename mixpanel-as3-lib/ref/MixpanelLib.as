package {
	import flash.external.ExternalInterface;
	
	public class MixpanelLib {
		private var name:String;
		
		public function MixpanelLib(token:String) {
			/*
				Initialize Mixpanel object.  Automatically called when new object is 
				created with 'var a = new MixpanelLib('sdfsdf');
				
				Required:
					@token: Your unique project token
			*/
			
			// Randomized name - allows multiple flash objects on one page with no 
			// possible overlap.
			name = "mpmetrics_flash" + Math.abs(int(Math.random() * 9999999999));
			init(token);
		}
		
		public function init(token:String):void {
			/*
				Create the mpmetrics JS object and inject it into the page.
				This way, you don't have to initialize it in JS if you just 
				want to use it in flash.
			*/
			var reg:String = "(function(token) { window." + this.name + " = new MixpanelLib(token, '" + this.name + "');})";
			ExternalInterface.call(reg, token);
		}
		
		public function track(event:String, properties:Object=null):void {
			/*
				Track an event.
				
				Required:
					@event: Name of event
				Optional:
					@properties: Properties for this event.
					
				Example: mpmetrics.track("Open slideshow", {'show': 'Xmas'}, function():void { myfunction() });
			*/
			if (!properties) { properties = {}; }
			ExternalInterface.call(this.name + '.track', event, properties);
		}
		
		public function track_funnel(funnel:String, step:int, goal:String, properties:Object=null):void {
			/*
				Track a funnel step.
				
				Required:
					@funnel: Funnel name, same for all steps of a single funnel
					@step: Step number, starting with 1
					@goal: Human readable name for this step
				Optional:
					@properties: Properties for this funnel step.
					
				Example: mpmetrics.track_funnel("Signup", 1, "Landing page", {'from': 'Google'});
			*/
			if (!properties) { properties = {}; }
			ExternalInterface.call(this.name + '.track_funnel', funnel, step, goal, properties);
		}
		
		public function register(properties:Object, type:String="all", days:int=7):void {
			/*
				Register a set of super properties.  This will overwrite previous super property 
				values.
				
				Required: 
					@properties: associative array of properties to store about the user
				Optional:
					@type: "all", "events", or "funnels".  Determines the types of events to send this data with.
							Default "all".
					@days: Age of cookie in days. The cookie is set frequently so this has little effect.
							Default 7.
					
				Example: mpmetrics.register({'user type': 'free trial', 'status': 4}, "all");
			*/
			ExternalInterface.call(this.name + '.register', properties, type, days);
		}
		
		public function register_once(properties:Object, type:String="all", default_value:String ="None", days:int=7):void {
			/*
				Register a set of super properties only once.  This will not overwrite previous super property 
				values, unlike register(). However, if default_value is specified, current super properties 
				with that value *will* be overwritten.
				
				Required: 
					@properties: associative array of properties to store about the user
				Optional:
					@type: "all", "events", or "funnels".  Determines the types of events to send this data with.
							Default "all".
					@default_value: Value to override if already set in super properties (ex "False")
							Default "None".
					@days: Age of cookie in days. The cookie is set frequently so this has little effect.
							Default 7.
			*/
			ExternalInterface.call(this.name + '.register_once', properties, type, default_value, days);
		}
		
		public function register_funnel(funnel:String, steps:Array):void {
            /*
                Register a funnel.

                Required:
                  @funnel: Funnel name
                  @step: Array of steps in order
                
                Example: mpmetrics.register_funnel('purchase item', ['log in', 'create character', 'purchase']);
            */
            ExternalInterface.call(this.name + '.register_funnel', funnel, steps);
        }

        public function identify(id:String):void {
          	ExternalInterface.call(this.name + '.identify', id);
        }
	}
}