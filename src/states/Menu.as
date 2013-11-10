package states
{
	import api.IState;
	import com.greensock.easing.Back;
	import com.greensock.TweenLite;
	import components.InfoText;
	import components.SimpleButton;
	import events.ButtonEvent;
	import events.StateEvent;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.system.System;
	/**
	 * ...This class creates Menu
	 * @author Leonid Trofumchuk
	 */
	public class Menu extends Sprite implements IState
	{
		static public const MEDIA_PLAYER	:String = "MEDIA PLAYER";		
		static public const WEB_CAMERA		:String = "WEB CAMERA";				 
		static public const EXIT			:String = "EXIT";					
		
		private var numOfBut:int;									//Number of Buttons in Menu
			
		private var buttonActions:Object = {};						//Menu Actions
		
		private var initButtonPos:int = 150;						//Initial Button Position
		private var initButHeight:int = 50;							//Initial Button Height
		private var yOffSet:int = 100;								//Button Y OffSet
		private var hMultiply:int = 60;								//Height Multiply
		private var nextX:int;										//Finite Button X value
		
		private var buttonArray:Vector.<SimpleButton>;				//Main container
		private var help:InfoText;
		private var stesel:InfoText;
		/**
		 * Constructor
		 * @param	sFlag		Sound Button Flag
		 * @param	rFlag		Resume Game Availability
		 */
		public function Menu() 
		{
			
			if (stage)
				init(null);
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.align = "";
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			
			enterState();
		}

//-------------------------------------------------------------------------------------------------
//
//  Interface Methods definition
//
//-------------------------------------------------------------------------------------------------	
		
		public function enterState():void
		{
			//Help Text
			help = new InfoText(16, 0xffba16);
			help.setText("«Space» - Menu. «Enter» - Full Screen");
			help.x = (stage.stageWidth - help.width) / 2;
			help.y = stage.stageHeight - help.height;
			addChild(help);
			
			stesel = new InfoText(12, 0x00e0c6);
			stesel.setText("vk.com/stesel23");
			stesel.x = stage.stageWidth - stesel.width - 2;
			stesel.selectable = true;
			addChild(stesel)
			
			initActions();
			initMenu();
		}
		
		public function leaveState():void
		{
			numOfBut = 0;
			for (var i:int = 0; i < buttonArray.length; i++)
			{	
				var button:Sprite = buttonArray[i];
				button.removeEventListener(ButtonEvent.BUTTON_PRESSED, buttonPressed);
				removeChild(button);
				button = null;
			}
			buttonArray.length = 0;
			removeChild(help);
			help = null;
		}
		
//-------------------------------------------------------------------------------------------------
//
//  Methods
//
//-------------------------------------------------------------------------------------------------
		/**
		 * Actions Initialization
		 */
		private function initActions():void 
		{
			buttonActions[MEDIA_PLAYER] = onPlayer;
			buttonActions[WEB_CAMERA] = onWebCamera;
			buttonActions[EXIT] = onExit;
		}
		
		/**
		 * Menu Initialization
		 */
		private function initMenu():void
		{
			buttonArray = new Vector.<SimpleButton>();
			createButton(MEDIA_PLAYER);
			createButton(WEB_CAMERA);
			if (CONFIG::debug)
				createButton(EXIT);
		}
		
		/**
		 * @param	st	Button Name
		 * Create Button
		 */
		private function createButton(st:String):void 
		{
			var button: SimpleButton = new SimpleButton(st);
			button.scaleY = 0.001;
			button.x = - 150;
			button.y = stage.stageHeight/3.5 + numOfBut * hMultiply + initButHeight; 
			addChild(button);
			nextX = stage.stageWidth / 2;
			TweenLite.to(button, 0.5, { x:nextX, y: button.y, scaleY:1, ease:Back.easeOut } );
			numOfBut++;
			button.addEventListener(ButtonEvent.BUTTON_PRESSED, buttonPressed);
			buttonArray.push(button);
		}
			
		private function onPlayer(): void
		{
			dispatchEvent(new StateEvent(StateEvent.STATE_CHANGED, false, false, Menu.MEDIA_PLAYER));
			leaveState();
		}
		
		private function onWebCamera(): void
		{
			dispatchEvent(new StateEvent(StateEvent.STATE_CHANGED, false, false, Menu.WEB_CAMERA));
			leaveState();
		}
		
		public function onExit(): void
		{
			dispatchEvent(new StateEvent(StateEvent.STATE_CHANGED, false, false, Menu.EXIT));
			leaveState();
		}
		
//-------------------------------------------------------------------------------------------------
//
//  Events handlers
//
//-------------------------------------------------------------------------------------------------	
		
		private function buttonPressed(e:ButtonEvent):void 
		{
			var method:Function = buttonActions[e.label];
			if (method != null) method.call(this);
		}
	}

}