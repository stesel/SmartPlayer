package states 
{
	import api.IState;
	import com.greensock.easing.Back;
	import com.greensock.TweenLite;
	import components.InfoText;
	import components.SimpleButton;
	import events.ButtonEvent;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.StageVideoAvailabilityEvent;
	import flash.events.StageVideoEvent;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.media.StageVideo;
	import flash.system.Capabilities;
	import org.aswing.util.AbstractImpulser;
	import utils.SmartLogger;
	/**
	 * ...
	 * @author Leonid Trofimchuk
	 */
	public class WebCamera extends Sprite implements IState 
	{
		private var video:StageVideo;
		private var cameraAspectRatio:Number = 1.33;
		private var stageAspectRatio:Number = 1.33;
		private var camera:Camera;
		
		private var numOfBut:int;									//Number of Buttons in Menu
		private var initButtonPos:int = 150;						//Initial Button Position
		private var initButHeight:int = 50;							//Initial Button Height
		private var yOffSet:int = 100;								//Button Y OffSet
		private var hMultiply:int = 50;								//Height Multiply
		private var nextX:int;										//Finite Button X value
		
		private var buttonArray:Vector.<SimpleButton>;				//Main container
		private var help:InfoText;
		
		public function WebCamera() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, checkStageVideoAvailability);
		}
		
		private function checkStageVideoAvailability(e:StageVideoAvailabilityEvent):void 
		{
			video = e.availability ? stage.stageVideos[0] : null;
			enterState();
			if(!video)
				showTip("Stage video is not available");
		}
		
		private function onStageVideoEvent(e:StageVideoEvent):void 
		{
			SmartLogger.log("StageVideoEvent: ", e.status);
		}
		
		private function onResize(e:Event):void 
		{
			if (video)
				resizeVideo();
		}
		
		private function resizeVideo():void 
		{
			var cameraWidth		:int;
			var cameraHeight	:int;
			var cameraX			:int = 0;
			var cameraY			:int = 0;
			
			stageAspectRatio = stage.stageWidth / stage.stageHeight;
			
			if (stageAspectRatio > cameraAspectRatio)
			{
				cameraHeight = stage.stageHeight;
				cameraWidth = cameraHeight * cameraAspectRatio;
			}
			else if (stageAspectRatio < cameraAspectRatio)
			{
				cameraWidth = stage.stageWidth;
				cameraHeight = cameraWidth / cameraAspectRatio;
			}
			else if (stageAspectRatio == cameraAspectRatio)
			{
				cameraWidth = stage.stageWidth;
				cameraHeight = stage.stageHeight;
			}
			
			cameraX = (stage.stageWidth - cameraWidth) >> 1;
			cameraY = (stage.stageHeight - cameraHeight) >> 1;
			
			video.viewPort = new Rectangle(cameraX, cameraY, cameraWidth, cameraHeight);
			
			SmartLogger.log("Video width: " + cameraWidth, " Video height: " + cameraHeight);
			SmartLogger.log("Video X: " + cameraX, " Video Y: " + cameraY);
		}
		
		private function initMenu():void 
		{
			var cameras:Array = Camera.names;
			
			if (cameras.length < 1)
				showTip("Web camera is not available!");
			else
			{
				buttonArray = new Vector.<SimpleButton>();
				for (var i:int = 0; i < cameras.length; i++ )
				{
					var name:String = cameras[i];
					SmartLogger.log("Available web camera: ", name)
					createButton(name);
				}
			}
		}
		
		private function showTip(text:String):void 
		{
			if(!help)
				help = new InfoText(20, 0xffba16);
			help.setText(text);
			help.x = (stage.stageWidth - help.width) >> 1;
			help.y = (stage.stageHeight - help.height) >> 1;
			addChild(help);
			SmartLogger.log(text);
		}
		
		private function createButton(st:String):void 
		{
			var button: SimpleButton = new SimpleButton(st);
			button.scaleX = 0.8;
			button.scaleY = 0.001;
			button.x = - 150;
			button.y = stage.stageHeight/4 + numOfBut * hMultiply + initButHeight; 
			addChild(button);
			nextX = stage.stageWidth / 2;
			TweenLite.to(button, 0.5, { x:nextX, y: button.y, scaleY:0.8, ease:Back.easeOut } );
			numOfBut++;
			button.addEventListener(ButtonEvent.BUTTON_PRESSED, buttonPressed);
			buttonArray.push(button);
		}
		
		private function buttonPressed(e:ButtonEvent):void 
		{
			var pressedButton:SimpleButton = e.target as SimpleButton;
			var index:int = buttonArray.indexOf(pressedButton);
			
			numOfBut = 0;
			for (var i:int = 0; i < buttonArray.length; i++)
			{	
				var button:Sprite = buttonArray[i];
				button.removeEventListener(ButtonEvent.BUTTON_PRESSED, buttonPressed);
				removeChild(button);
				button = null;
			}
			buttonArray.length = 0;
			
			if (help)
			{
				removeChild(help);
				help = null;
			}
			
			switchCamera(index.toString())
		}
		
		private function switchCamera(label:String):void 
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			camera = Camera.getCamera(label);
			camera.setMode(640, 480, 30);
			camera.setQuality(camera.bandwidth, 100);
			SmartLogger.log("camera: ", "name: " + camera.name);
			SmartLogger.log("camera: ", "width: " + camera.width);
			SmartLogger.log("camera: ", "height: " + camera.height);
			SmartLogger.log("bandwidth: ", camera.bandwidth);
			cameraAspectRatio = camera.width / camera.height;
			
			if (video)
			{
				video.addEventListener(StageVideoEvent.RENDER_STATE, onStageVideoEvent);
				resizeVideo();
				video.attachCamera(camera);
			}
		}
		
//-------------------------------------------------------------------------------------------------
//
//  Interface Methods definition
//
//-------------------------------------------------------------------------------------------------		
		
		public function enterState():void
		{
			initMenu();
		}
		
		public function leaveState():void
		{
			if (video)
			{
				video.viewPort = new Rectangle(0, 0, 0, 0);
				camera = null;
				video.attachCamera(null);
				video.removeEventListener(StageVideoEvent.RENDER_STATE, onStageVideoEvent);
				video = null;
			}
			
			buttonArray.length = 0;
			
			if (help)
			{
				removeChild(help);
				help = null;
			}
			
			stage.removeEventListener(Event.RESIZE, onResize);
			stage.removeEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, checkStageVideoAvailability);
		}
		
	}

}