package states 
{
	import api.IState;
	import com.greensock.easing.Back;
	import com.greensock.TweenLite;
	import components.InfoText;
	import components.SimpleButton;
	import events.ButtonEvent;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.events.ProgressEvent;
	import flash.events.StageVideoAvailabilityEvent;
	import flash.events.StageVideoEvent;
	import flash.geom.Rectangle;
	import flash.media.StageVideo;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamAppendBytesAction;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	import utils.SmartLogger;
	/**
	 * ...
	 * @author Leonid Trofimchuk
	 */
	public class MediaPlayer extends Sprite implements IState 
	{
		static public const OPEN_FILE:String = "Open file";
		static public const OPEN_URL:String = "Open url";
		
		private var video:StageVideo;
		private var videoAspectRatio:Number = 1.33;
		private var stageAspectRatio:Number = 1.33;
		
		private var numOfBut:int;									//Number of Buttons in Menu
		private var initButtonPos:int = 150;						//Initial Button Position
		private var initButHeight:int = 50;							//Initial Button Height
		private var yOffSet:int = 100;								//Button Y OffSet
		private var hMultiply:int = 60;								//Height Multiply
		private var nextX:int;										//Finite Button X value
		
		private var buttonArray:Vector.<SimpleButton>;				//Main container
		private var help:InfoText;
		private var actions:Object;
		
		///
		private var urlField:InfoText;
		private var playButton:SimpleButton;
		
		private var urlString:String = "";
		
		private var fileRef:FileReference;
		private var videoData:ByteArray;
		
		private var netConnection:NetConnection;
		private var netStream:NetStream;
		private var waitForVideo:uint;
		private const formatPattern:String = "*.flv;*.mp4;*.avi;*.mov;";;
		
		public function MediaPlayer() 
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
		
		private function onResize(e:Event):void 
		{
			if (video)
				resizeVideo();
		}
		
		private function resizeVideo():void 
		{
			var videoWidth		:int;
			var videoHeight	:int;
			var videoX			:int = 0;
			var videoY			:int = 0;
			
			stageAspectRatio = stage.stageWidth / stage.stageHeight;
			
			if (stageAspectRatio > videoAspectRatio)
			{
				videoHeight = stage.stageHeight;
				videoWidth = videoHeight * videoAspectRatio;
			}
			else if (stageAspectRatio < videoAspectRatio)
			{
				videoWidth = stage.stageWidth;
				videoHeight = videoWidth / videoAspectRatio;
			}
			else if (stageAspectRatio == videoAspectRatio)
			{
				videoWidth = stage.stageWidth;
				videoHeight = stage.stageHeight;
			}
			
			videoX = (stage.stageWidth - videoWidth) >> 1;
			videoY = (stage.stageHeight - videoHeight) >> 1;
			
			video.viewPort = new Rectangle(videoX, videoY, videoWidth, videoHeight);
			
			SmartLogger.log("Video width: " + videoWidth, " Video height: " + videoHeight);
			SmartLogger.log("Video X: " + videoX, " Video Y: " + videoY);
		}
		
		private function initActions():void 
		{
			actions = { };
			actions[OPEN_FILE] = onOpenFile;
			actions[OPEN_URL] = onOpenURL;
		}
		
		private function initMenu():void 
		{
			var buttons:Array = [OPEN_FILE, OPEN_URL];
			
			buttonArray = new Vector.<SimpleButton>();
			for (var i:int = 0; i < buttons.length; i++ )
			{
				var name:String = buttons[i];
				createButton(name);
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
			button.scaleY = 0.001;
			button.x = - 150;
			button.y = stage.stageHeight/4 + numOfBut * hMultiply + initButHeight; 
			addChild(button);
			nextX = stage.stageWidth / 2;
			TweenLite.to(button, 0.5, { x:nextX, y: button.y, scaleY:1, ease:Back.easeOut } );
			numOfBut++;
			button.addEventListener(MouseEvent.CLICK, buttonPressed);
			buttonArray.push(button);
		}
		
		private function switchCamera(label:String):void 
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			//videoAspectRatio = camera.width / camera.height;
			
			if (video)
			{
				video.addEventListener(StageVideoEvent.RENDER_STATE, onStageVideoEvent);
				resizeVideo();
			}
		}
			
		private function onOpenFile():void 
		{
			initFileBrowser();
		}
			
		private function onOpenURL():void 
		{
			removeMenu();
			initURLField();
		}
		
		private function initFileBrowser():void 
		{
			fileRef = new FileReference();
			fileRef.addEventListener(Event.SELECT, fileSelected);
			var filters:Array = [];
			fileRef.browse([new FileFilter("*Video Files",formatPattern)]);
		}
		
		private function initURLField():void 
		{
			urlField = new InfoText(20, 0x00e0c6);
			
			urlField.autoSize = TextFieldAutoSize.NONE;
			urlField.width = 460;
			urlField.height = 27;
			urlField.border = true;
			urlField.type = TextFieldType.INPUT;
			urlField.multiline = false;
			urlField.selectable = true;
			
			playButton = new SimpleButton("Play");
			playButton.addEventListener(ButtonEvent.BUTTON_PRESSED, onPlayButton);
			
			urlField.x = (stage.stageWidth - urlField.width - playButton.width - 8) >> 1;
			urlField.y = (stage.stageHeight - urlField.height) >> 1;
			
			playButton.scaleX = playButton.scaleY = 0.7;
			
			playButton.x = urlField.x + urlField.width + (playButton.height) ;
			playButton.y = (stage.stageHeight) >> 1;
			
			addChild(urlField);
			addChild(playButton);
			stage.focus = urlField;
		}
		
		private function removeMenu():void 
		{
			numOfBut = 0;
			for (var i:int = 0; i < buttonArray.length; i++)
			{	
				var button:Sprite = buttonArray[i];
				button.removeEventListener(MouseEvent.CLICK, buttonPressed);
				removeChild(button);
				button = null;
			}
			buttonArray.length = 0;
		}
		
//-------------------------------------------------------------------------------------------------
//
//  Interface Methods definition
//
//-------------------------------------------------------------------------------------------------		
		
		public function enterState():void
		{
			initActions();
			initMenu();
		}
		
		public function leaveState():void
		{
			if (fileRef)
			{
				fileRef.cancel
				fileRef = null;
			}
			if (netStream)
			{
				netStream.close();
				netStream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
				netStream.removeEventListener(NetStatusEvent.NET_STATUS, neStatusHandler);
				netStream = null;
			}
			
			if (netConnection)
			{
				netConnection.close();
				netConnection.removeEventListener(NetStatusEvent.NET_STATUS, neStatusHandler);
				netConnection = null;
			}
			
			if (video)
			{
				video.viewPort = new Rectangle(0, 0, 0, 0);
				video.attachNetStream(null);
				video.removeEventListener(StageVideoEvent.RENDER_STATE, onStageVideoEvent);
				video = null;
			}
			stage.removeEventListener(Event.RESIZE, onResize);
			stage.removeEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, checkStageVideoAvailability);
			
			buttonArray = null;
			actions = null;
			if (help)
			{
				removeChild(help)
				help = null;
			}
			clearTimeout(waitForVideo);
		}
		
//-------------------------------------------------------------------------------------------------
//
//  Stream Methods definition
//
//-------------------------------------------------------------------------------------------------	
		
		private function initStream():void
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			netConnection = new NetConnection();
			netConnection.addEventListener(NetStatusEvent.NET_STATUS, neStatusHandler);
			netConnection.connect(null);
			
			netStream = new NetStream(netConnection);
			netStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
			netStream.addEventListener(NetStatusEvent.NET_STATUS, neStatusHandler);
			var customClient:Object = new Object();
			customClient.onMetaData = metaDataHandler;
			netStream.client = customClient;
			
			waitForVideo = setTimeout(noVideo, 5000);
		}
		
		private function setPlayFile():void 
		{
			initStream();
			
			netStream.play(null);
			//netStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
			netStream.appendBytes(videoData);
			video.attachNetStream(netStream);
		}
		
		private function setPlayURL():void 
		{
			initStream();
			
			netStream.play(urlString);
			video.attachNetStream(netStream);
		}
		
		
//-------------------------------------------------------------------------------------------------
//
//  Handler Methods definition
//
//-------------------------------------------------------------------------------------------------	
		
		private function noVideo():void 
		{
			showTip("Video is not supported!");
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
		
		private function buttonPressed(e:MouseEvent):void 
		{
			var button:SimpleButton =  e.target as SimpleButton;
			var action:Function = actions[button.label];
			if (action) action.call(this);
		}
		
		private function onPlayButton(e:ButtonEvent):void 
		{
			if (urlField.text == "")
				return;
			urlString = urlField.text;
			removeChild(urlField);
			removeChild(playButton);
			playButton.removeEventListener(ButtonEvent.BUTTON_PRESSED, onPlayButton);
			urlField = null;
			playButton = null;
			setPlayURL();
		}
		
		private function fileSelected(e:Event):void 
		{
			removeMenu();
			SmartLogger.log("File Name: ", fileRef.name);
			SmartLogger.log("File Size: ", fileRef.size >> 10 , " KB");
			var mb:uint = fileRef.size >> 20;
			
			if (mb > 512)
			{
				showTip("Large File Size! 512MB is max.");
				return;
			}
			
			
			fileRef.addEventListener(ProgressEvent.PROGRESS, fileProgress);
			fileRef.addEventListener(IOErrorEvent.IO_ERROR, fileErrorHandler);
			fileRef.addEventListener(Event.COMPLETE, fileLoaded);
			fileRef.load();
		}
		
		private function fileErrorHandler(e:IOErrorEvent):void 
		{
			 SmartLogger.log(e.errorID);
		}
		
		private function fileProgress(e:ProgressEvent):void 
		{
			var file:FileReference = FileReference(e.target);
            SmartLogger.log("Loaded: ", e.bytesLoaded >> 10, "KB of ", e.bytesTotal >> 10, " KB");
		}
		
		private function fileLoaded(e:Event):void 
		{
			fileRef.removeEventListener(ProgressEvent.PROGRESS, fileProgress);
			fileRef.removeEventListener(IOErrorEvent.IO_ERROR, fileErrorHandler);
			fileRef.removeEventListener(Event.COMPLETE, fileLoaded);
			
			videoData = fileRef.data;
			setPlayFile();
		}
		
		private function neStatusHandler(e:NetStatusEvent):void 
		{
			SmartLogger.log(e.info.code);
			clearTimeout(waitForVideo);
			
			switch (e.info.code)
			{
				case "NetStream.Play.StreamNotFound" :
					showTip("Stream Not Found!");
				break;
			}
		}
		
		private function metaDataHandler(infoObject:Object):void 
		{
			videoAspectRatio = infoObject.width / infoObject.height;
			for (var key:String in infoObject)
				SmartLogger.log(key + ": ", infoObject[key]);
			
			resizeVideo();
		}
		
		private function asyncErrorHandler(e:AsyncErrorEvent):void 
		{
			SmartLogger.log(e.text);
		}
		
		private function ioErrorHandler(e:IOErrorEvent):void 
		{
			SmartLogger.log(e.text);
		}
		
	}

}