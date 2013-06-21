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
		
		private var _armature:Armature;
		private var _isPlaying:Boolean;
		private var _animationLayer:Vector.<Vector.<AnimationState>>;
		
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
		
		public function get movementID():String
		{
			return _lastAnimationState?_lastAnimationState.name:null;
		}
		
		private var _animationList:Vector.<String>;
		
		public function get animationList():Vector.<String>
		{
			return _animationList;
		}
		
		public function get movementList():Vector.<String>
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
			fadeTime:Number = -1, 
			timeScale:Number = -1, 
			loop:Number = NaN, 
			layer:uint = 0, 
			playMode:int = 1
		):void
		{
			if (!_animationDataList)
			{
				return;
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
				return;
			}
			
			_isPlaying = true;
			
			//
			fadeTime = fadeTime < 0?(animationData.fadeTime < 0?0.3:animationData.fadeTime):fadeTime;
			//
			timeScale = timeScale < 0?(animationData.scale < 0?1:animationData.scale):timeScale;
			//
			loop = isNaN(loop)?animationData.loop:loop;
			//
			layer = addLayer(layer);
			
			switch(playMode)
			{
				case 0:
					//playMode == 0 blend all layer
					break;
				case 1:
					//fadeOut same layer
					var animationStateList:Vector.<AnimationState> = _animationLayer[layer];
					i = animationStateList.length;
					while(i --)
					{
						animationStateList[i].fadeOut(fadeTime, true);
					}
					break;
				case 2:
					//fadeOut all layer
					var j:int = _animationLayer.length;
					while(j --)
					{
						animationStateList = _animationLayer[j];
						i = animationStateList.length;
						while(i --)
						{
							animationStateList[i].fadeOut(fadeTime, true);
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
			addState(_lastAnimationState);
			_lastAnimationState.fadeIn(_armature, animationData, fadeTime, loop, layer, timeScale, true);
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
			var lastState:Boolean;
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
							if(!lastState)
							{
								lastState = true;
								animationState._displayControl = true;
							}
							else
							{
								animationState._displayControl = false;
							}
							if(!animationState.advanceTime(passedTime))
							{
								AnimationState.returnObject(animationStateList[j]);
								animationStateList.splice(j, 1);
								if(animationStateList.length == 0 && i == _animationLayer.length - 1)
								{
									_animationLayer.length --;
								}
								continue;
							}
						}
						
						if(
							animationState._mixingBoneList.length > 0
							?
							animationState._mixingBoneList.indexOf(boneName) >= 0
							:
							true
						)
						{
							var timelineState:TimelineState = animationState._boneTimelineStates[boneName];
							
							if(timelineState)
							{
								var weight:Number = animationState.weight * weigthLeft;
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
				pivot = bone._pivot;
				
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
		
		private function addLayer(layer:uint):uint
		{
			if(layer >= _animationLayer.length)
			{
				layer = _animationLayer.length;
				_animationLayer[layer] = new Vector.<AnimationState>;
			}
			return layer;
		}
		
		private function removeState(animationState:AnimationState):void
		{
			var animationStateList:Vector.<AnimationState> = _animationLayer[animationState.layer];
			animationStateList.splice(animationStateList.indexOf(animationState), 1);
		}
		
		private function addState(animationState:AnimationState):void
		{
			var animationStateList:Vector.<AnimationState> = _animationLayer[animationState.layer];
			animationStateList[animationStateList.length] = animationState;
		}
	}
	
}