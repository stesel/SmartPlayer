package utils 
{
	import flash.display.Sprite;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Leonid Trofimchuk
	 */
	public class SmartLogger extends Sprite
	{
		static private var text:TextField;
		static private var logger:SmartLogger;
		
		static public function getLogger():SmartLogger
		{
			if (!logger)
			{
				logger = new SmartLogger();
				initText();
			}
			return logger;
		}
		
		static private function initText():void 
		{
			text = new TextField();
			text.border = true;
			text.borderColor = 0xcccccc;
			text.textColor = 0x00ffd8;
			text.width = 300;
			text.height = 65;
			logger.addChild(text);
		}
		
		static public function log(...rest):void
		{
			if (!logger)
				return;
			for (var i:int = 0; i < rest.length; i++ )
			{
				text.appendText(String(rest[i]));
			}
			text.appendText("\n");
			text.scrollV = text.maxScrollV;
			trace(rest.join(""));
		}
		
	}

}