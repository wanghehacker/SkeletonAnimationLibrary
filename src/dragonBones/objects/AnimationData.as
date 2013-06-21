package dragonBones.objects
{
	import dragonBones.core.dragonBones_internal;
	
	use namespace dragonBones_internal;
	
	final public class AnimationData extends Timeline
	{
		public var name:String;
		public var loop:int;
		public var tweenEasing:Number;
		
		private var _boneAnimations:Object;
		public function get boneAnimations():Object
		{
			return _boneAnimations;
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
			
			_boneAnimations = {};
		}
		
		override public function dispose():void
		{
			super.dispose();
			
			for(var boneName:String in _boneAnimations)
			{
				_boneAnimations[boneName].dispose();
				delete _boneAnimations[boneName];
			}
			//_boneAnimations = null;
		}
		
		public function getBoneTimeline(boneName:String):TransformTimeline
		{
			return _boneAnimations[boneName] as TransformTimeline;
		}
		
		public function addBoneTimeline(timeline:TransformTimeline, boneName:String):void
		{
			if(!timeline)
			{
				throw new ArgumentError();
			}
			
			_boneAnimations[boneName] = timeline;
		}
	}
}