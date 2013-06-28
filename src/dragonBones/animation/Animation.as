package dragonBones.animation
{
	/**
	 * Copyright 2012-2013. DragonBones. All Rights Reserved.
	 * @playerversion Flash 10.0
	 * @langversion 3.0
	 * @version 2.0
	 */
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.AnimationEvent;
	import dragonBones.events.FrameEvent;
	import dragonBones.events.SoundEvent;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.DBTransform;
	
	import flash.geom.Point;
	
	use namespace dragonBones_internal;
	
	/**
	 * An Animation instance is used to control the animation state of an Armature.
	 * @example
	 * <p>Download the example files <a href='http://dragonbones.github.com/downloads/DragonBones_Tutorial_Assets.zip'>here</a>: </p>
	 * <listing>	
	 *	package  
	 *	{
	 *		import dragonBones.Armature;
	 *		import dragonBones.factorys.BaseFactory;
	 *  	import flash.display.Sprite;
	 *		import flash.events.Event;	
	 *
	 *		public class DragonAnimation extends Sprite 
	 *		{		
	 *			[Embed(source = "Dragon1.swf", mimeType = "application/octet-stream")]  
	 *			private static const ResourcesData:Class;
	 *			
	 *			private var factory:BaseFactory;
	 *			private var armature:Armature;		
	 *			
	 *			public function DragonAnimation() 
	 *			{				
	 *				factory = new BaseFactory();
	 *				factory.addEventListener(Event.COMPLETE, handleParseData);
	 *				factory.parseData(new ResourcesData(), 'Dragon');
	 *			}
	 *			
	 *			private function handleParseData(e:Event):void 
	 *			{			
	 *				armature = factory.buildArmature('Dragon');
	 *				addChild(armature.display as Sprite); 			
	 *				armature.animation.play();
	 *				addEventListener(Event.ENTER_FRAME, updateAnimation);			
	 *			}
	 *			
	 *			private function updateAnimation(e:Event):void 
	 *			{
	 *				armature.advanceTime(stage.frameRate / 1000);
	 *			}		
	 *		}
	 *	}
	 * </listing>
	 * @see dragonBones.Bone
	 * @see dragonBones.Armature
	 */
	final public class Animation
	{
		//public static var defaultTweenEnabled:Boolean = true;
		
		public static const FADE_OUT_NONE:String = "fadeOutNone";
		public static const FADE_OUT_SAME_LAYER:String = "fadeOutSameLayer";
		public static const FADE_OUT_ALL_LAYER:String = "fadeOutAllLayer";
		
		private var _armature:Armature;
		private var _isPlaying:Boolean;
		private var _animationLayer:Vector.<Vector.<AnimationState>>;
		
		public function get movementList():Vector.<String>
		{
			return _animationList;
		}
		
		public function get movementID():String
		{
			return _lastAnimationState?_lastAnimationState.name:null;
		}
		
		public function get isPlaying():Boolean
		{
			return _isPlaying && !isComplete;
		}
		
		public function get isComplete():Boolean
		{
			if(_lastAnimationState)
			{
				if(!_lastAnimationState.isComplete)
				{
					return false;
				}
				var j:int = _animationLayer.length;
				while(j --)
				{
					var animationStateList:Vector.<AnimationState> = _animationLayer[j];
					var i:int = animationStateList.length;
					while(i --)
					{
						if(!animationStateList[i].isComplete)
						{
							return false;
						}
					}
				}
				return true;
			}
			return false;
		}
		
		private var _timeScale:Number = 1;
		public function get timeScale():Number
		{
			return _timeScale;
		}
		public function set timeScale(value:Number):void
		{
			if (value < 0)
			{
				value = 0;
			}
			_timeScale = value;
		}
		
		dragonBones_internal var _lastAnimationState:AnimationState
		public function get lastAnimationState():AnimationState
		{
			return _lastAnimationState;
		}
		
		private var _animationList:Vector.<String>;
		
		public function get animationList():Vector.<String>
		{
			return _animationList;
		}
		
		private var _animationDataList:Vector.<AnimationData>;
		public function get animationDataList():Vector.<AnimationData>
		{
			return _animationDataList;
		}
		public function set animationDataList(value:Vector.<AnimationData>):void
		{
			_animationDataList = value;
			_animationList.length = 0;
			for each(var animationData:AnimationData in _animationDataList)
			{
				_animationList[_animationList.length] = animationData.name;
			}
		}
		
		/**
		 * Creates a new Animation instance and attaches it to the passed Arnature.
		 * @param	An Armature to attach this Animation instance to.
		 */
		public function Animation(armature:Armature)
		{
			_armature = armature;
			_animationLayer = new Vector.<Vector.<AnimationState>>;
			_animationList = new Vector.<String>;
		}
		
		/**
		 * Qualifies all resources used by this Animation instance for garbage collection.
		 */
		public function dispose():void
		{
			stop();
			var i:int = _animationLayer.length;
			while(i --)
			{
				var animationStateList:Vector.<AnimationState> = _animationLayer[i];
				var j:int = animationStateList.length;
				while(j --)
				{
					AnimationState.returnObject(animationStateList[j]);
				}
				animationStateList.length = 0;
			}
			_animationLayer.length = 0;
			_animationList.length = 0;
			
			_armature = null;
			_animationLayer = null;
			_animationDataList = null;
			_animationList = null;
		}
		
		/**
		 * Move the playhead to that AnimationData
		 * @param	The name of the AnimationData to play.
		 * @param	A fade time to apply (> 0)
		 * @param	The duration in seconds of that MovementData.
		 * @param	Whether that MovementData should loop or play only once (true/false).
		 * @see dragonBones.objects.MovementData.
		 */
		public function gotoAndPlay(
			animationName:String, 
			fadeInTime:Number = -1, 
			durationScale:Number = -1, 
			loop:Number = NaN, 
			layer:uint = 0, 
			playMode:String = FADE_OUT_SAME_LAYER,
			displayControl:Boolean = true,
			pauseFadeOut:Boolean = true,
			pauseFadeIn:Boolean = true
		):AnimationState
		{
			if (!_animationDataList)
			{
				return null;
			}
			var i:int = _animationDataList.length;
			while(i --)
			{
				if(_animationDataList[i].name == animationName)
				{
					var animationData:AnimationData = _animationDataList[i];
					break;
				}
			}
			if (!animationData)
			{
				return null;
			}
			
			_isPlaying = true;
			
			//
			fadeInTime = fadeInTime < 0?(animationData.fadeTime < 0?0.3:animationData.fadeTime):fadeInTime;
			durationScale = (durationScale < 0?1:durationScale) * (animationData.scale < 0?1:animationData.scale);
			loop = isNaN(loop)?animationData.loop:loop;
			layer = addLayer(layer);
			
			//autoSync = autoSync && !pauseFadeOut && !pauseFadeIn;
			switch(playMode)
			{
				case FADE_OUT_NONE:
					break;
				case FADE_OUT_SAME_LAYER:
					var animationStateList:Vector.<AnimationState> = _animationLayer[layer];
					i = animationStateList.length;
					while(i --)
					{
						var animationState:AnimationState = animationStateList[i];
						if(!animationState.group)
						{
							animationState.fadeOut(fadeInTime, pauseFadeOut);
						}
					}
					break;
				case FADE_OUT_ALL_LAYER:
					var j:int = _animationLayer.length;
					while(j --)
					{
						animationStateList = _animationLayer[j];
						i = animationStateList.length;
						while(i --)
						{
							animationState = animationStateList[i];
							if(!animationState.group)
							{
								animationState.fadeOut(fadeInTime, pauseFadeOut);
							}
						}
					}
					break;
				default:
					var group:String = playMode;
					j = _animationLayer.length;
					while(j --)
					{
						animationStateList = _animationLayer[j];
						i = animationStateList.length;
						while(i --)
						{
							animationState = animationStateList[i];
							if(animationState.group == group)
							{
								animationState.fadeOut(fadeInTime, pauseFadeOut);
							}
						}
					}
					break;
			}
			
			
			var boneList:Vector.<Bone> = _armature._boneList;
			i = boneList.length;
			while(i --)
			{
				var bone:Bone = boneList[i];
				if(bone.childArmature)
				{
					bone.childArmature.animation.gotoAndPlay(animationName);
				}
			}
			
			
			_lastAnimationState = AnimationState.borrowObject();
			_lastAnimationState.group = group;
			_lastAnimationState.fadeIn(_armature, animationData, fadeInTime, 1 / durationScale, loop, layer, displayControl, pauseFadeIn);
			
			addState(_lastAnimationState);
			return _lastAnimationState;
		}
		
		/**
		 * Play the animation from the current position.
		 */
		public function play():void
		{
			if (!_animationDataList || _animationDataList.length == 0)
			{
				return;
			}
			if(!_lastAnimationState)
			{
				gotoAndPlay(_animationDataList[0].name);
			}
			else if (!_isPlaying)
			{
				_isPlaying = true;
			}
			else
			{
				gotoAndPlay(_lastAnimationState.name);
			}
		}
		
		/**
		 * Stop the playhead.
		 */
		public function stop():void
		{
			_isPlaying = false;
		}
		
		public function getState(name:String, layer:uint = 0):AnimationState
		{
			var l:int = _animationLayer.length;
			if(l == 0)
			{
				return null;
			}
			else if(layer >= l)
			{
				layer = l - 1;
			}
			
			var animationStateList:Vector.<AnimationState> = _animationLayer[layer];
			if(!animationStateList)
			{
				return null;
			}
			var i:int = animationStateList.length;
			while(i --)
			{
				if(animationStateList[i].name == name)
				{
					return animationStateList[i];
				}
			}
			
			return null;
		}
		
		public function advanceTime(passedTime:Number):void
		{
			if(!_isPlaying)
			{
				return;
			}
			passedTime *= _timeScale;
			
			var l:int = _armature._boneList.length;
			var k:int = l;
			l --;
			while(k --)
			{
				var bone:Bone = _armature._boneList[k];
				var boneName:String = bone.name;
				var weigthLeft:Number = 1;
				
				var x:Number = 0;
				var y:Number = 0;
				var skewX:Number = 0;
				var skewY:Number = 0;
				var scaleX:Number = 0;
				var scaleY:Number = 0;
				var pivotX:Number = 0;
				var pivotY:Number = 0;
				
				var i:int = _animationLayer.length;
				while(i --)
				{
					var layerTotalWeight:Number = 0;
					var animationStateList:Vector.<AnimationState> = _animationLayer[i];
					var j:int = animationStateList.length;
					while(j --)
					{
						var animationState:AnimationState = animationStateList[j];
						if(k == l)
						{
							if(animationState.advanceTime(passedTime))
							{
								removeState(animationState);
								continue;
							}
						}
						
						var timelineState:TimelineState = animationState._timelineStates[boneName];
						
						if(timelineState)
						{
							var weight:Number = animationState._fadeWeight * animationState.weight * weigthLeft;
							var transform:DBTransform = timelineState.transform;
							var pivot:Point = timelineState.pivot;
							x += transform.x * weight;
							y += transform.y * weight;
							skewX += transform.skewX * weight;
							skewY += transform.skewY * weight;
							scaleX += transform.scaleX * weight;
							scaleY += transform.scaleY * weight;
							pivotX += pivot.x * weight;
							pivotY += pivot.y * weight;
							
							layerTotalWeight += weight;
						}
					}
					
					if(layerTotalWeight >= weigthLeft)
					{
						break;
					}
					else
					{
						weigthLeft -= layerTotalWeight;
					}
				}
				transform = bone._tween;
				pivot = bone._tweenPivot;
				
				transform.x = x;
				transform.y = y;
				transform.skewX = skewX;
				transform.skewY = skewY;
				transform.scaleX = scaleX;
				transform.scaleY = scaleY;
				pivot.x = pivotX;
				pivot.y = pivotY;
			}
		}
		
		/** @private */
		dragonBones_internal function setStatesDisplayControl(animationState:AnimationState):void
		{
			var i:int = _animationLayer.length;
			while(i --)
			{
				var animationStateList:Vector.<AnimationState> = _animationLayer[i];
				var j:int = animationStateList.length;
				while(j --)
				{
					animationStateList[j].displayControl = animationStateList[j] == animationState;
				}
			}
		}
		
		private function addLayer(layer:uint):uint
		{
			if(layer >= _animationLayer.length)
			{
				layer = _animationLayer.length;
				_animationLayer[layer] = new Vector.<AnimationState>;
			}
			return layer;
		}
		
		private function addState(animationState:AnimationState):void
		{
			var animationStateList:Vector.<AnimationState> = _animationLayer[animationState.layer];
			animationStateList[animationStateList.length] = animationState;
		}
		
		private function removeState(animationState:AnimationState):void
		{
			var layer:int = animationState.layer;
			var animationStateList:Vector.<AnimationState> = _animationLayer[layer];
			animationStateList.splice(animationStateList.indexOf(animationState), 1);
			
			AnimationState.returnObject(animationState);
			
			if(animationStateList.length == 0 && layer == _animationLayer.length - 1)
			{
				_animationLayer.length --;
			}
		}
	}
	
}