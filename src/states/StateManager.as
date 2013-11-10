package states
{
	import events.StateEvent;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.net.navigateToURL;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.system.fscommand;
	import flash.system.System;
	import flash.ui.Keyboard;
	import utils.SmartLogger;
	/**
	 * ...	State Manager
	 * @author Leonid Trofimchuk
	 */
	public class StateManager extends Sprite
	{
		private var _menu:Menu;
		private var _mediaPlayer:MediaPlayer;
		private var _webCamera:WebCamera;
		
		public function StateManager() 
		{
			if (stage)
				init(null);
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			initMenu();
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		}
			
//-------------------------------------------------------------------------------------------------
//
//	Methods Definition
//
//-------------------------------------------------------------------------------------------------	
			
		private function initMenu():void 
		{
			if	(_mediaPlayer)
				removeMediaPlayer();
			if (_webCamera)
				removeWebCamera();
				
			_menu = new Menu();
			_menu.addEventListener(StateEvent.STATE_CHANGED, menu_stateChanged);
			addChild(_menu);
		}
			
		private function removeMenu():void
		{
			_menu.removeEventListener(StateEvent.STATE_CHANGED, menu_stateChanged);
			removeChild(_menu);
			_menu = null;
		}
		
		private function initMediaPlayer():void
		{
			_mediaPlayer = new MediaPlayer();
			addChild(_mediaPlayer);
		}
		
		private function removeMediaPlayer():void
		{
			_mediaPlayer.leaveState();
			removeChild(_mediaPlayer);
			_mediaPlayer = null;
		}
		
		private function initWebCamera():void
		{
			_webCamera = new WebCamera();
			addChild(_webCamera);
		}
		
		private function removeWebCamera():void
		{
			_webCamera.leaveState();
			removeChild(_webCamera);
			_webCamera = null;
			
		}
			
		private function closeApp():void 
		{
			//fscommand("quit");
			System.exit(0);
		}
		
		private function tooglefullScreen():void 
		{
			if (stage.displayState == StageDisplayState.NORMAL)
			{
				SmartLogger.getLogger().visible = false;
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			}
			else
			{
				SmartLogger.getLogger().visible = true;
				stage.displayState = StageDisplayState.NORMAL
			}
			
		}
		
//-------------------------------------------------------------------------------------------------
//
//	Event Handlers Definition
//
//-------------------------------------------------------------------------------------------------	
		
		private function keyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == Keyboard.SPACE && !_menu)
			{
				if (_webCamera)
					removeWebCamera();
				initMenu();
			}
			
			if (e.keyCode == Keyboard.ENTER)
			{
				tooglefullScreen();
			}
		}
		
		private function callMenu():void 
		{
			if (_menu != null)
				return;
			initMenu();
		}
			
		private function menu_stateChanged(e:StateEvent):void 
		{
			switch (e.onState)
			{
				case Menu.MEDIA_PLAYER:
					removeMenu();
					initMediaPlayer();
					break;
				case Menu.WEB_CAMERA:
					removeMenu();
					initWebCamera();
					break;
				case "EXIT":
					removeMenu();
					closeApp();
					break;
				default:
					closeApp();
			}
		}
		
	}

}