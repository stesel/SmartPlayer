package 
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.system.Security;
	import states.StateManager;
	import utils.SmartLogger;
	
	/**
	 * ...
	 * @author Leonid Trofimchuk
	 */
	
	[SWF(backgroundColor = "#000000", frameRate = "60", width = "640", height = "480")]
	[Frame(factoryClass = "SplashScreen")]
	
	public class Main extends Sprite 
	{
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			Security.allowDomain("*");
				
			if(CONFIG::debug)
				addChild(SmartLogger.getLogger());
				
			var stateManager:StateManager = new StateManager();
			addChild(stateManager);
		}
	}
	
}