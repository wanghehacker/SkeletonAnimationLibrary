package dragonBones.animation
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.core.DBObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.AnimationEvent;
	import dragonBones.events.FrameEvent;
	import dragonBones.events.SoundEvent;
	import dragonBones.events.SoundEventManager;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.TransformFrame;
	import dragonBones.objects.TransformTimeline;
	import dragonBones.utils.TransformUtils;
	
	import flash.geom.Point;
	
	use namespace dragonBones_internal;
	
	public final class TimelineState
	{
		private static const HALF_PI:Number = Math.PI * 0.5;
		private static const DOUBLE_PI:Number = Math.PI * 2;
		
		private static var _soundManager:SoundEventManager = SoundEventManager.getInstance();
		
		public static function getEaseValue(value:Number, easing:Number):Number
		{
			if (easing > 1)
			{
				var valueEase:Number = 0.5 * (1 - Math.cos(value * Math.PI )) - value;
				easing -= 1;
			}
			else if (easing > 0)
			{
				valueEase = Math.sin(value * HALF_PI) - value;
			}
			else if (easing < 0)
			{
				valueEase = 1 - Math.cos(value * HALF_PI) - value;
				easing *= -1;
			}
			return valueEase * easing + value;
		}
		
		private static var _pool:Vector.<TimelineState> = new Vector.<TimelineState>;
		
		dragonBones_internal static function borrowObject():TimelineState
		{
			if(_pool.length == 0)
			{
				return new TimelineState();
			}
			return _pool.pop();
		}
		
		dragonBones_internal static function returnObject(timeline:TimelineState):void
		{
			if(_pool.indexOf(timeline) < 0)
			{
				_pool[_pool.length] = timeline;
			}
			
			timeline.clear();
		}
		
		dragonBones_internal static function clear():void
		{
			var i:int = _pool.length;
			while(i --)
			{
				_pool[i].clear();
			}
			_pool.length = 0;
		}
		
		public var transform:DBTransform;
		public var pivot:Point;
		
		public var update:Function;
		
		private var _animationState:AnimationState;
		private var _armature:Armature;
		private var _object:DBObject;
		private var _timeline:TransformTimeline;
		private var _currentFrame:TransformFrame;
		private var _currentFramePosition:Number;
		private var _currentFrameDuration:Number;
		private var _durationTransform:DBTransform;
		private var _durationPivot:Point;
		private var _originTransform:DBTransform;
		private var _originPivot:Point;
		
		private var _tweenEasing:Number;
		
		private var _totalTime:Number;
		private var _scale:Number;
		private var _offset:Number;
		
		public function TimelineState()
		{
			transform = new DBTransform();
			pivot = new Point();
			
			_durationTransform = new DBTransform();
			_durationPivot = new Point();
		}
		
		public function fadeIn(armature:Armature, object:DBObject, animationState:AnimationState, timeline:TransformTimeline):void
		{
			_armature = armature;
			_object = object;
			_animationState = animationState;
			_timeline = timeline;
			
			_originTransform = _timeline.originTransform;
			_originPivot = _timeline.originPivot;
			
			/*
			var rotation:Number = dbObject.origin.skewX + dbObject.node.skewX + dbObject._aniTransform.skewX;
			
			if(rotation * transform.skewX < 0 && (Math.abs(rotation) > Math.PI * 0.5 || Math.abs(transform.skewX) > Math.PI * 0.5))
			{
				if(rotation < 0)
				{
					//transform.skewX -= Math.PI * 2;
					//transform.skewY -= Math.PI * 2;
				}
				else
				{
					//transform.skewX += Math.PI * 2;
					//transform.skewY += Math.PI * 2;
				}
			}
			*/
			
			_totalTime = _animationState.totalTime;
			_scale = _timeline.scale;
			_offset = _timeline.offset;
			
			transform.x = 0;
			transform.y = 0;
			transform.scaleX = 0;
			transform.scaleY = 0;
			transform.skewX = 0;
			transform.skewY = 0;
			pivot.x = 0;
			pivot.y = 0;
			
			_durationTransform.x = 0;
			_durationTransform.y = 0;
			_durationTransform.scaleX = 0;
			_durationTransform.scaleY = 0;
			_durationTransform.skewX = 0;
			_durationTransform.skewY = 0;
			_durationPivot.x = 0;
			_durationPivot.y = 0;
			
			switch(_timeline.frameList.length)
			{
				case 0:
					var bone:Bone = _object as Bone;
					if(bone && bone._defaultSlot)
					{
						bone._defaultSlot.changeDisplay(-1);
					}
					update = updateNothing;
					break;
				case 1:
					update = updateSingle;
					break;
				default:
					update = updateList;
					break;
			}
		}
		
		public function fadeOut():void
		{
			transform.skewX = TransformUtils.formatRadian(transform.skewX);
			transform.skewY = TransformUtils.formatRadian(transform.skewY);
		}
		
		private function updateNothing(progress:Number):void
		{
			
		}
		
		private function updateSingle(progress:Number):void
		{
			update = updateNothing;
			transform.copy(_originTransform);
			pivot.x = _originPivot.x;
			pivot.y = _originPivot.y;
			_currentFrame = _timeline.frameList[0] as TransformFrame;
			arriveFrameData(_currentFrame, true);
		}
		
		private function updateList(progress:Number):void
		{
			progress /= _scale;
			progress += _offset;
			var loopCount:int = progress;
			progress -= loopCount;
			
			//
			var playedTime:Number = _totalTime * progress;
			while (!_currentFrame || playedTime >= _currentFramePosition + _currentFrameDuration || playedTime < _currentFramePosition)
			{
				if(isArrivedFrame)
				{
					arriveFrameData(_currentFrame, false);
				}
				var isArrivedFrame:Boolean = true;
				if(_currentFrame)
				{
					var index:int = _timeline.frameList.indexOf(_currentFrame);
					index ++;
					if(index >= _timeline.frameList.length)
					{
						index = 0;
					}
					_currentFrame = _timeline.frameList[index] as TransformFrame;
				}
				else
				{
					index = 0;
					_currentFrame = _timeline.frameList[0] as TransformFrame;
				}
				_currentFrameDuration = _currentFrame.duration;
				_currentFramePosition = _currentFrame.position;
			}
			
			if(isArrivedFrame)
			{
				index ++;
				if(index >= _timeline.frameList.length)
				{
					index = 0;
				}
				var nextFrame:TransformFrame = _timeline.frameList[index] as TransformFrame;
				
				if(index == 0 && _animationState.loop && _animationState.loopCount >= Math.abs(_animationState.loop) - 1 && ((_currentFramePosition + _currentFrameDuration) / _totalTime + loopCount - _offset) * _scale > 0.99)// >= 1
				{
					update = updateNothing;
				}
				
				if(nextFrame.displayIndex < 0 || !_animationState.tweenEnabled || update == updateNothing)
				{
					_tweenEasing = NaN;
				}
				else
				{
					_durationTransform.x = nextFrame.transform.x - _currentFrame.transform.x;
					_durationTransform.y = nextFrame.transform.y - _currentFrame.transform.y;
					_durationTransform.skewX = TransformUtils.formatRadian(nextFrame.transform.skewX - _currentFrame.transform.skewX);
					_durationTransform.skewY = TransformUtils.formatRadian(nextFrame.transform.skewY - _currentFrame.transform.skewY);
					_durationTransform.scaleX = nextFrame.transform.scaleX - _currentFrame.transform.scaleX;
					_durationTransform.scaleY = nextFrame.transform.scaleY - _currentFrame.transform.scaleY;
					
					if (nextFrame.tweenRotate)
					{
						_durationTransform.skewX += nextFrame.tweenRotate * DOUBLE_PI;
						_durationTransform.skewY += nextFrame.tweenRotate * DOUBLE_PI;
					}
					
					_durationPivot.x = nextFrame.pivot.x - _currentFrame.pivot.x;
					_durationPivot.y = nextFrame.pivot.y - _currentFrame.pivot.y;
					
					if(
						_durationTransform.x != 0 ||
						_durationTransform.y != 0 ||
						_durationTransform.skewX != 0 ||
						_durationTransform.skewY != 0 ||
						_durationTransform.scaleX != 0 ||
						_durationTransform.scaleY != 0 ||
						_durationPivot.x != 0 ||
						_durationPivot.y != 0
					)
					{
						if(isNaN(_animationState.clip.tweenEasing))
						{
							_tweenEasing = _currentFrame.tweenEasing;
						}
						else
						{
							_tweenEasing = _animationState.clip.tweenEasing;
						}
					}
					else
					{
						_tweenEasing = NaN;
					}
				}
				
				if(isNaN(_tweenEasing))
				{
					transform.x = _originTransform.x + _currentFrame.transform.x;
					transform.y = _originTransform.y + _currentFrame.transform.y;
					transform.skewX = _originTransform.skewX + _currentFrame.transform.skewX;
					transform.skewY = _originTransform.skewY + _currentFrame.transform.skewY;
					transform.scaleX = _originTransform.scaleX + _currentFrame.transform.scaleX;
					transform.scaleY = _originTransform.scaleY + _currentFrame.transform.scaleY;
					pivot.x = _originPivot.x + _currentFrame.pivot.x;
					pivot.y = _originPivot.y + _currentFrame.pivot.y;
				}
				
				arriveFrameData(_currentFrame, true);
			}
			
			if (!isNaN(_tweenEasing))
			{
				progress = (playedTime - _currentFramePosition) / _currentFrameDuration;
				if(_tweenEasing)
				{
					progress = getEaseValue(progress, _tweenEasing);
				}
				var currentTransform:DBTransform = _currentFrame.transform;
				transform.x = _originTransform.x + currentTransform.x + _durationTransform.x * progress;
				transform.y = _originTransform.y + currentTransform.y + _durationTransform.y * progress;
				transform.skewX = _originTransform.skewX + currentTransform.skewX + _durationTransform.skewX * progress;
				transform.skewY = _originTransform.skewY + currentTransform.skewY + _durationTransform.skewY * progress;
				transform.scaleX = _originTransform.scaleX + currentTransform.scaleX + _durationTransform.scaleX * progress;
				transform.scaleY = _originTransform.scaleY + currentTransform.scaleY + _durationTransform.scaleY * progress;
				
				var currentPivot:Point = _currentFrame.pivot;
				pivot.x = _originPivot.x + currentPivot.x + _durationPivot.x * progress;
				pivot.y = _originPivot.y + currentPivot.y + _durationPivot.y * progress;
			}
		}
		
		private function arriveFrameData(frame:TransformFrame, finalArrive:Boolean):void
		{
			if(_animationState._displayControl && finalArrive)
			{
				var displayIndex:int = frame.displayIndex;
				var bone:Bone = _object as Bone;
				if(bone && bone._defaultSlot)
				{
					if(displayIndex >= 0)
					{
						if(frame.zOrder != bone._defaultSlot.zOrder)
						{
							bone._defaultSlot.zOrder = frame.zOrder;
							_armature._slotsZOrderChanged = true;
						}
					}
					bone._defaultSlot.changeDisplay(displayIndex);
					bone._defaultSlot.visible = frame.visible;
				}
			}
			
			if(frame.event && _armature.hasEventListener(FrameEvent.BONE_FRAME_EVENT))
			{
				var frameEvent:FrameEvent = new FrameEvent(FrameEvent.BONE_FRAME_EVENT);
				frameEvent.object = _object;
				frameEvent.animationState = _animationState;
				frameEvent.frameLabel = frame.event;
				_armature.dispatchEvent(frameEvent);
			}
			
			if(frame.sound && _soundManager.hasEventListener(SoundEvent.SOUND))
			{
				var soundEvent:SoundEvent = new SoundEvent(SoundEvent.SOUND);
				soundEvent.armature = _armature;
				soundEvent.object = _object;
				soundEvent.animationState = _animationState;
				soundEvent.sound = frame.sound;
				_soundManager.dispatchEvent(soundEvent);
			}
			
			if(frame.action)
			{
				var childArmature:Armature = (_object as Object).childArmature;
				if(childArmature)
				{
					childArmature.animation.gotoAndPlay(frame.action);
				}
			}
		}
		
		private function clear():void
		{
			update = updateNothing;
			
			_armature = null;
			_object = null;
			_animationState = null;
			_timeline = null;
			_currentFrame = null;
			_originTransform = null;
			_originPivot = null;
		}
	}
}