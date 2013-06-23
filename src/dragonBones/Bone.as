package dragonBones
{
	import dragonBones.animation.AnimationState;
	import dragonBones.core.DBObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.FrameEvent;
	import dragonBones.events.SoundEvent;
	import dragonBones.objects.Frame;
	import dragonBones.objects.TransformFrame;
	
	import flash.geom.Point;
	
	use namespace dragonBones_internal;
	
	public class Bone extends DBObject
	{
		//0/1/2
		public var scaleMode:int;
		
		dragonBones_internal var _pivot:Point;
		
		private var _children:Vector.<DBObject>;
		private var _defaultSlot:Slot;
		
		public function get childArmature():Armature
		{
			return _defaultSlot?_defaultSlot.childArmature:null; 
		}
		
		public function get display():Object
		{
			return _defaultSlot?_defaultSlot.display:null;
		}
		public function set display(value:Object):void
		{
			if(_defaultSlot)
			{
				_defaultSlot.display = value;
			}
		}
		
		override dragonBones_internal function setArmature(value:Armature):void
		{
			super.setArmature(value);
			var i:int = _children.length;
			while(i --)
			{
				_children[i].setArmature(this._armature);
			}
		}
		
		public function Bone()
		{
			super();
			_children = new Vector.<DBObject>(0, true);
			_scaleType = 2;
			
			_pivot = new Point();
			
			scaleMode = 1;
		}
		
		override public function dispose():void
		{
			super.dispose();
			
			var i:int = _children.length;
			while(i --)
			{
				_children[i].dispose();
			}
			_children.fixed = false;
			_children.length = 0;
			
			_children = null;
			_defaultSlot = null;
			_pivot = null;
		}
		
		override dragonBones_internal function update():void
		{
			super.update();
			
			var pivotX:Number = _pivot.x;
			var pivotY:Number = _pivot.y;
			if(pivotX || pivotY)
			{
				this._globalTransformMatrix.tx += this._globalTransformMatrix.a * pivotX + this._globalTransformMatrix.c * pivotY;
				this._globalTransformMatrix.ty += this._globalTransformMatrix.b * pivotX + this._globalTransformMatrix.d * pivotY;
			}
		}
		
		override dragonBones_internal function updateColor(
			aOffset:Number, 
			rOffset:Number, 
			gOffset:Number, 
			bOffset:Number, 
			aMultiplier:Number, 
			rMultiplier:Number, 
			gMultiplier:Number, 
			bMultiplier:Number
		):void
		{
			_defaultSlot._displayBridge.updateColor(
				aOffset, 
				rOffset, 
				gOffset, 
				bOffset, 
				aMultiplier, 
				rMultiplier, 
				gMultiplier, 
				bMultiplier
			);
		}
		
		/** @private */
		override dragonBones_internal function arriveAtFrame(frame:Frame, endArrive:Boolean, animationState:AnimationState):void
		{
			if(frame)
			{
				if(endArrive)
				{
					var tansformFrame:TransformFrame = frame as TransformFrame;
					if(_defaultSlot)
					{
						var displayIndex:int = tansformFrame.displayIndex;
						if(displayIndex >= 0)
						{
							if(tansformFrame.zOrder != _defaultSlot._tweenZorder)
							{
								_defaultSlot._tweenZorder = tansformFrame.zOrder;
								_armature._slotsZOrderChanged = true;
							}
						}
						_defaultSlot.changeDisplay(displayIndex);
						_defaultSlot.visible = tansformFrame.visible;
					}
				}
				
				if(frame.event && _armature.hasEventListener(FrameEvent.BONE_FRAME_EVENT))
				{
					var frameEvent:FrameEvent = new FrameEvent(FrameEvent.BONE_FRAME_EVENT);
					frameEvent.object = this;
					frameEvent.animationState = animationState;
					frameEvent.frameLabel = frame.event;
					_armature.dispatchEvent(frameEvent);
				}
				
				if(frame.sound && _soundManager.hasEventListener(SoundEvent.SOUND))
				{
					var soundEvent:SoundEvent = new SoundEvent(SoundEvent.SOUND);
					soundEvent.armature = _armature;
					soundEvent.object = this;
					soundEvent.animationState = animationState;
					soundEvent.sound = frame.sound;
					_soundManager.dispatchEvent(soundEvent);
				}
				
				if(frame.action)
				{
					var childArmature:Armature = this.childArmature;
					if(childArmature)
					{
						childArmature.animation.gotoAndPlay(frame.action);
					}
				}
			}
			else
			{
				if(_defaultSlot)
				{
					_defaultSlot.changeDisplay(-1);
				}
			}
		}
		
		public function contains(child:DBObject):Boolean
		{
			if(!child)
			{
				throw new ArgumentError();
			}
			
			var ancestor:DBObject = this;
			while (ancestor != child && ancestor != null)
			{
				ancestor = ancestor.parent;
			}
			return ancestor == child;
		}
		
		public function addChild(child:DBObject):void
		{
			if(!child)
			{
				throw new ArgumentError();
			}
			
			if((child is Bone) && (child as Bone).contains(this))
			{
				throw new ArgumentError("An Bone cannot be added as a child to itself or one of its children (or children's children, etc.)");
			}
			if(child.parent)
			{
				child.parent.removeChild(child);
			}
			_children.fixed = false;
			_children[_children.length] = child;
			_children.fixed = true;
			child.setParent(this);
			
			if(!_defaultSlot && child is Slot)
			{
				_defaultSlot = child as Slot;
			}
		}
		
		public function removeChild(child:DBObject):void
		{
			if(!child)
			{
				throw new ArgumentError();
			}
			
			var index:int = _children.indexOf(child);
			if (index >= 0)
			{
				_children.fixed = false;
				_children.splice(index, 1);
				_children.fixed = true;
				child.setParent(null);
				
				if(_defaultSlot && child == _defaultSlot)
				{
					_defaultSlot = null;
				}
			}
			else
			{
				throw new ArgumentError();
			}
		}
	}
}