package dragonBones.objects
{
	import dragonBones.core.dragonBones_internal;
	
	use namespace dragonBones_internal;
	
	final public class AnimationData extends Timeline
	{
		public var name:String;
		public var loop:int;
		public var tweenEasing:Number;
		
		private var _timelines:Object;
		public function get timelines():Object
		{
			return _timelines;
		}
		
		private var _fadeTime:Number;
		public function get fadeTime():Number
		{
			return _fadeTime;
		}
		public function set fadeTime(value:Number):void
		{
			_fadeTime = value > 0?value:0;
		}
		
		public function AnimationData()
		{
			super();
			loop = 0;
			tweenEasing = NaN;
			
			_fadeTime = 0;
			
			_timelines = {};
		}
		
		override public function dispose():void
		{
			super.dispose();
			
			for(var boneName:String in _timelines)
			{
				(_timelines[boneName] as TransformTimeline).dispose();
				delete _timelines[boneName];
			}
			//_timelines = null;
		}
		
		public function getTimeline(boneName:String):TransformTimeline
		{
			return _timelines[boneName] as TransformTimeline;
		}
		
		public function addTimeline(timeline:TransformTimeline, boneName:String):void
		{
			if(!timeline)
			{
				throw new ArgumentError();
			}
			
			_timelines[boneName] = timeline;
		}
	}
}