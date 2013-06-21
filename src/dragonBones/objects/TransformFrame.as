package dragonBones.objects
{
	import flash.geom.Point;

	final public class TransformFrame extends Frame
	{
		public var tweenEasing:Number;
		//
		public var tweenRotate:int;
		public var visible:Boolean;
		public var displayIndex:int;
		public var zOrder:Number;
		//public var color:Object;
		
		public var global:DBTransform;
		public var transform:DBTransform;
		public var pivot:Point;
		
		public function TransformFrame()
		{
			super();
			
			visible = true;
			tweenEasing = 0;
			tweenRotate = 0;
			displayIndex = 0;
			zOrder = 0;
			
			transform = new DBTransform();
			pivot = new Point();
		}
	}
	
}