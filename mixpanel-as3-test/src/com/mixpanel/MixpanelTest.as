package com.mixpanel
{
	public class MixpanelTest
	{
		private static function newMixpanel():Mixpanel {
			var mp:Mixpanel = new Mixpanel("79792ef1d49fab67180ce43b6410e4b5");
			mp.set_config({test: 1});
			return mp;
		}
		
		private static const mixpanel:Mixpanel = newMixpanel();
		
		[BeforeClass]
		public static function registerProperties():void {
			mixpanel.register({
				testDate: new Date().toLocaleString(),
				testRegisterProp: "testRegister"
			});
		}
		
		[Test]
		public function testTrack():void {
			mixpanel.track("testTrack: testEvent");
		}
		
		[Test]
		public function testTrackWithProps():void {
			mixpanel.track("testTrackWithProps: testEvent", {testProp: "test"});
		}
		
		[Test]
		public function testTrackWithCallback():void {
			mixpanel.track("testTrackWithCallback: testEvent", null, function(result:*):void {
				trace("callback hit!", result);
			});
		}
		
		[Test]
		public function testFunnel():void {
			mixpanel.track_funnel("testFunnel: Testing Funnel", 1, "Test Completion");
			mixpanel.track_funnel("testFunnel: Testing Funnel", 2, "Test Completion");
			mixpanel.track_funnel("testFunnel: Testing Funnel", 3, "Test Completion");
			mixpanel.track_funnel("testFunnel: Testing Funnel", 4, "Test Completion");
			mixpanel.track_funnel("testFunnel: Testing Funnel", 5, "Test Completion");
			mixpanel.track_funnel("testFunnel: Testing Funnel", 6, "Test Completion");
		}
		
		[Test]
		public function testRegister():void {
			mixpanel.track("testRegister: testRegisterProp should equal 'testRegister'");
			mixpanel.register({testRegisterProp: "testRegister2"});
			mixpanel.track("testRegister: testRegisterProp should equal 'testRegister2'");
			mixpanel.register({testRegisterProp: "testRegister"});
			mixpanel.track("testRegister: testRegisterProp should equal 'testRegister'");
		}
		
		[Test]
		public function testRegisterOnce():void {
			mixpanel.register_once({testRegisterProp: "thisValueWillNeverBeSet"});
			mixpanel.track("testRegisterOnce: testRegisterProp should equal 'testRegister'");
		}
		
		[Test]
		public function testLocalStorage():void {
			var otherMP:Mixpanel = newMixpanel();
			otherMP.track("testLocalStorage: testRegisterProp should equal 'testRegister'");
		}
		
	}
}