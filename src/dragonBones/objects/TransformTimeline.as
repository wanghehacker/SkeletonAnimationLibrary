package dragonBones.objects
{
	import flash.geom.Point;

	public final class TransformTimeline extends Timeline
	{
		public static const HIDE_TIMELINE:TransformTimeline = new TransformTimeline();
		
		public var originTransform:DBTransform;
		public var originPivot:Point;
		
		private var _value:Number = Math.random();
		
		private var _offset:Number;
		public function get offset():Number
		{
			return _offset;
		}
		public function set offset(value:Number):void
		{
			_offset = (value || 0) - int(value);
			
			/*
			if (_offset < 0)
			{
			_offset += 1;
			}
			*/
			
			if (_offset > 0)
			{
				_offset -= 1;
			}
			_offset *= -1;
		}
		
		public function TransformTimeline()
		{
			super();
			
			_offset = 0;
			originTransform = new DBTransform();
			originPivot = new Point();
		}
		
		override public function dispose():void
		{
			if(this == HIDE_TIMELINE)
			{
				return;
			}
			super.dispose();
			originTransform = null;
			originPivot = null;
		}
	}
}