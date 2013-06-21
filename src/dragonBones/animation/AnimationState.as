package dragonBones.animation
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.AnimationEvent;
	import dragonBones.events.FrameEvent;
	import dragonBones.events.SoundEvent;
	import dragonBones.events.SoundEventManager;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.Frame;
	import dragonBones.objects.TransformTimeline;
	
	use namespace dragonBones_internal;

	final public class AnimationState
	{
		private static var _soundManager:SoundEventManager = SoundEventManager.getInstance();
		
		private static var _pool:Vector.<AnimationState> = new Vector.<AnimationState>;
		
		/** @private */
		dragonBones_internal static function borrowObject():AnimationState
		{
			if(_pool.length == 0)
			{
				return new AnimationState();
			}
			return _pool.pop();
		}
		
		/** @private */
		dragonBones_internal static function returnObject(animationState:AnimationState):void
		{
			animationState.clear();
			
			if(_pool.indexOf(animationState) < 0)
			{
				_pool[_pool.length] = animationState;
			}
		}
		
		/** @private */
		dragonBones_internal static function clear():void
		{
			var i:int = _pool.length;
			while(i --)
			{
				_pool[i].clear();
			}
			_pool.length = 0;
			
			TimelineState.clear();
		}
		
		public var enabled:Boolean;
		public var tweenEnabled:Boolean;
		public var weight:Number;
		
		/** @private */
		dragonBones_internal var _boneTimelineStates:Object;
		/** @private */
		dragonBones_internal var _mixingBoneList:Vector.<String>;
		/** @private */
		dragonBones_internal var _displayControl:Boolean;
		
		private var _armature:Armature;
		private var _currentFrame:Frame;
		
		private var _fadeState:int;
		private var _fadeInLength:Number;
		private var _fadeOutLength:Number;
		private var _fadeOutStart:Number;
		private var _fadeOutWeight:Number;
		private var _fadeIn:Boolean;
		private var _fadeOut:Boolean;
		private var _pauseBeforeFadeInComplete:Boolean;
		private var _action:Boolean;
		
		public function get name():String
		{
			return _clip?_clip.name:null;
		}
		
		private var _clip:AnimationData;
		public function get clip():AnimationData
		{
			return _clip;
		}
		
		private var _loopCount:int;
		public function get loopCount():int
		{
			return _loopCount;
		}
		
		private var _loop:int;
		public function get loop():int
		{
			return _loop;
		}
		
		private var _layer:uint;
		public function get layer():uint
		{
			return _layer;
		}
		
		private var _totalTime:Number;
		public function get totalTime():Number
		{
			return _totalTime;
		}
		
		private var _currentTime:Number;
		public function get currentTime():Number
		{
			return _currentTime;
		}
		public function set currentTime(value:Number):void
		{
			if(value < 0 || isNaN(value))
			{
				value = 0;
			}
			_currentTime = value;
		}
		
		private var _timeScale:Number;
		public function get timeScale():Number
		{
			return _timeScale;
		}
		public function set timeScale(value:Number):void
		{
			if(value < 0)
			{
				value = 0;
			}
			else if(isNaN(value))
			{
				value = 1;
			}
			_timeScale = value;
		}
		
		private var _isPlaying:Boolean;
		public function get isPlaying():Boolean
		{
			return _isPlaying; 
		}
		
		private var _isComplete:Boolean;
		public function get isComplete():Boolean
		{
			return _isComplete; 
		}
		
		private var _blendMode:String;
		public function get blendMode():String
		{
			return _blendMode;
		}
		public function set blendMode(value:String):void
		{
			_blendMode = value;
		}
		
		public function AnimationState()
		{ 
			//_blendMode
			
			_boneTimelineStates = {};
			_mixingBoneList = new Vector.<String>;
		}
		
		dragonBones_internal function fadeIn(armature:Armature, clip:AnimationData, fadeInTime:Number, loopEnd:int, layer:uint, timeScale:Number, pauseBeforeFadeInComplete:Boolean):void
		{
			_armature = armature;
			_clip = clip;
			_pauseBeforeFadeInComplete = pauseBeforeFadeInComplete;
			
			_timeScale = timeScale;
			_loop = loopEnd;
			_layer = layer;
			_fadeInLength = fadeInTime * _timeScale;
			
			_totalTime = _clip.duration;
			_loopCount = -1;
			_fadeState = 1;
			_fadeOutStart = 0;
			_currentTime = 0;
			_fadeOutWeight = 1;
			_action = false;
			_isPlaying = true;
			_isComplete = false;
			_displayControl = false;
			_fadeIn = true;
			_fadeOut = false;
			
			weight = 0;
			
			if(_totalTime <= 0 && Math.abs(_loop) != 1)
			{
				if(_loop >= 0)
				{
					_loop = 1;
				}
				else
				{
					_loop = -1;
				}
			}
			
			for(var boneName:String in _clip.boneAnimations)
			{
				var timelineState:TimelineState = TimelineState.borrowObject();
				var bone:Bone = _armature.getBone(boneName);
				var timeline:TransformTimeline = _clip.getBoneTimeline(boneName);
				timelineState.fadeIn(_armature, bone, this, timeline);
				_boneTimelineStates[boneName] = timelineState;
			}
			
			enabled = true;
			tweenEnabled = true;
		}
		
		public function fadeOut(fadeOutTime:Number, pause:Boolean = false):void
		{
			_fadeOutWeight = weight;
			_fadeOutLength = fadeOutTime * _timeScale;
			_fadeState = -1;
			_fadeOutStart = _currentTime;
			_isPlaying = !pause;
			_fadeOut = true;
			
			for each(var timelineState:TimelineState in _boneTimelineStates)
			{
				timelineState.fadeOut();
			}
			
			enabled = true;
		}
		
		public function play():void
		{
			_isPlaying = true;
		}
		
		public function stop():void
		{
			_isPlaying = false;
		}
		
		public function addMixing(boneName:String):void
		{
			//
			if(_clip.getBoneTimeline(boneName))
			{
				if(_mixingBoneList.indexOf(boneName) < 0)
				{
					_mixingBoneList[_mixingBoneList.length] = boneName;
				}
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		public function removeMixing(boneName:String = null):void
		{
			if(boneName)
			{
				var index:int = _mixingBoneList.indexOf(boneName);
				if(index >= 0)
				{
					_mixingBoneList.splice(index, 1);
				}
			}
			else
			{
				_mixingBoneList.length = 0;
			}
		}
		
		public function advanceTime(passedTime:Number):Boolean
		{
			if(!enabled)
			{
				return true;
			}
			
			if(_fadeIn)
			{	
				_fadeIn = false;
				if(_armature.hasEventListener(AnimationEvent.FADE_IN))
				{
					var event:AnimationEvent = new AnimationEvent(AnimationEvent.FADE_IN);
					event.animationState = this;
					_armature.dispatchEvent(event);
					event = null;
				};
			}
			
			if(_fadeOut)
			{	
				_fadeOut = false;
				if(_armature.hasEventListener(AnimationEvent.FADE_OUT))
				{
					event = new AnimationEvent(AnimationEvent.FADE_OUT);
					event.animationState = this;
					_armature.dispatchEvent(event);
					event = null;
				}
			}
			
			_currentTime += passedTime * _timeScale;
			
			if(_isPlaying && !_isComplete)
			{
				if(_pauseBeforeFadeInComplete)
				{
					_pauseBeforeFadeInComplete = false;
					_isPlaying = false;
					progress = 0;
					var loopCount:int = progress;
				}
				else
				{
					if(_totalTime > 0)
					{
						var progress:Number = _currentTime / _totalTime;
					}
					else
					{
						progress = 1;
					}
					
					//update loopCount
					loopCount = progress;
					if(loopCount != _loopCount)
					{
						_loopCount = loopCount;
						if(_loopCount == 0)
						{
							if(_armature.hasEventListener(AnimationEvent.START))
							{
								event = new AnimationEvent(AnimationEvent.START);
								event.animationState = this;
								_armature.dispatchEvent(event);
								event = null;
							}
						}
						else if(_loop != 0 && _loopCount * _loopCount >= _loop * _loop - 1)//_loopCount >= Math.abs(_loop) - 1
						{
							_isComplete = true;
							if(_armature.hasEventListener(AnimationEvent.COMPLETE))
							{
								event = new AnimationEvent(AnimationEvent.COMPLETE);
								event.animationState = this;
							}
						}
						else
						{
							if(_armature.hasEventListener(AnimationEvent.LOOP_COMPLETE))
							{
								event = new AnimationEvent(AnimationEvent.LOOP_COMPLETE);
								event.animationState = this;
							}
						}
					}
				}
				
				
				for each(var timeline:TimelineState in _boneTimelineStates)
				{
					timeline.update(progress);
				}
				
				//
				if(_clip.frameList.length > 0)
				{
					var playedTime:Number = _totalTime * (progress - loopCount);
					while(!_currentFrame || playedTime >= _currentFrame.position + _currentFrame.duration || playedTime < _currentFrame.position)
					{
						if(isArrivedFrame)
						{
							arriveFrameData(_currentFrame);
						}
						var isArrivedFrame:Boolean = true;
						if(_currentFrame)
						{
							var index:int = _clip.frameList.indexOf(_currentFrame);
							index ++;
							if(index >= _clip.frameList.length)
							{
								index = 0;
							}
							_currentFrame = _clip.frameList[index];
						}
						else
						{
							_currentFrame = _clip.frameList[0];
						}
					}
					
					if(isArrivedFrame)
					{
						arriveFrameData(_currentFrame);
						/*
						index ++;
						if(index >= _clip.frameList.length)
						{
						index = 0;
						}
						var nextFrame:Frame = _clip.frameList[index];
						
						if(index == 0 && _loop && _loopCount >= Math.abs(_loop) && (nextFrame.position / _totalTime + _loopCount - _offset) * _scale >= 1)
						{
						updateTimeline = updateNothing;
						}
						*/
						//_moveable.arriveAtFrame(_currentFrame);
					}
				}
				
				if(event)
				{
					_armature.dispatchEvent(event);
				}
			}
			
			//update weight and fadeState
			if(_fadeState > 0)
			{
				if(_fadeInLength == 0)
				{
					weight = 1;
					_fadeState = 0;
					_isPlaying = true;
					if(_armature.hasEventListener(AnimationEvent.FADE_IN_COMPLETE))
					{
						event = new AnimationEvent(AnimationEvent.FADE_IN_COMPLETE);
						event.animationState = this;
						_armature.dispatchEvent(event);
					}
				}
				else
				{
					weight = _currentTime / _fadeInLength;
					if(weight >= 1)
					{
						weight = 1;
						_fadeState = 0;
						if(!_isPlaying)
						{
							_currentTime -= _fadeInLength;
						}
						_isPlaying = true;
						if(_armature.hasEventListener(AnimationEvent.FADE_IN_COMPLETE))
						{
							event = new AnimationEvent(AnimationEvent.FADE_IN_COMPLETE);
							event.animationState = this;
							_armature.dispatchEvent(event);
						}
					}
				}
			}
			else if(_fadeState < 0)
			{
				if(_fadeOutLength == 0)
				{
					weight = 0;
					_fadeState = 0;
					if(_armature.hasEventListener(AnimationEvent.FADE_OUT_COMPLETE))
					{
						event = new AnimationEvent(AnimationEvent.FADE_OUT_COMPLETE);
						event.animationState = this;
						_armature.dispatchEvent(event);
					}
					return false;
				}
				else
				{
					weight = (1 - (_currentTime - _fadeOutStart) / _fadeOutLength) * _fadeOutWeight;
					if(weight <= 0)
					{
						weight = 0;
						_fadeState = 0;
						if(_armature.hasEventListener(AnimationEvent.FADE_OUT_COMPLETE))
						{
							event = new AnimationEvent(AnimationEvent.FADE_OUT_COMPLETE);
							event.animationState = this;
							_armature.dispatchEvent(event);
						}
						return false;
					}
				}
			}
			
			return true;
		}
		
		private function arriveFrameData(frame:Frame):void
		{
			if(frame.event && _armature.hasEventListener(FrameEvent.ANIMATION_FRAME_EVENT))
			{
				var frameEvent:FrameEvent = new FrameEvent(FrameEvent.ANIMATION_FRAME_EVENT);
				frameEvent.animationState = this;
				frameEvent.frameLabel = frame.event;
				_armature.dispatchEvent(frameEvent);
			}
			
			if(frame.sound && _soundManager.hasEventListener(SoundEvent.SOUND))
			{
				var soundEvent:SoundEvent = new SoundEvent(SoundEvent.SOUND);
				soundEvent.armature = _armature;
				soundEvent.animationState = this;
				soundEvent.sound = frame.sound;
				_soundManager.dispatchEvent(soundEvent);
			}
			if(frame.action && !_action)
			{
				_armature.animation.gotoAndPlay(frame.action);
				_action = true;
			}
		}
		
		private function clear():void
		{
			_armature = null;
			_currentFrame = null;
			_clip = null;
			
			for(var i:String in _boneTimelineStates)
			{
				TimelineState.returnObject(_boneTimelineStates[i] as TimelineState);
				delete _boneTimelineStates[i];
			}
			
			_mixingBoneList.length = 0;
		}
	}
}