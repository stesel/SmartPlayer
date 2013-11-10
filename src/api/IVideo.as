package api 
{
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.net.NetStream;
	
	/**
	 * ...
	 * @author Leonid Trofimchuk
	 */
	public interface IVideo 
	{
		public function attachCamera (theCamera:Camera) : void;
		public function attachNetStream (netStream:NetStream) : void;
		
		public function get viewPort () : flash.geom.Rectangle;
		public function set viewPort (rect:Rectangle) : void;
	}
	
}