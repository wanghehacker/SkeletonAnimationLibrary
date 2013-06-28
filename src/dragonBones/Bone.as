package dragonBones
{
	import dragonBones.animation.AnimationState;
	import dragonBones.animation.TimelineState;
	import dragonBones.core.DBObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.FrameEvent;
	import dragonBones.objects.Frame;
	import dragonBones.objects.TransformFrame;
	
	import flash.geom.Point;
	
	use namespace dragonBones_internal;
	
	public class Bone extends DBObject
	{
		//0/1/2
		public var scaleMode:int;
		
		dragonBones_internal var _tweenPivot:Point;
		
		private var _children:Vector.<DBObject>;
		
		private var _slot:Slot;
		public function get slot():Slot
		{
			return _slot;
		}
		
		public function get childArmature():Armature
		{
			return _slot?_slot.childArmature:null; 
		}
		
		public function get display():Object
		{
			return _slot?_slot.display:null;
		}
		public function set display(value:Object):void
		{
			if(_slot)
			{
				_slot.display = value;
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
			
			_tweenPivot = new Point();
			
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
			_slot = null;
			_tweenPivot = null;
		}
		
		override dragonBones_internal function update():void
		{
			super.update();
			
			var pivotX:Number = _tweenPivot.x;
			var pivotY:Number = _tweenPivot.y;
			if(pivotX || pivotY)
			{
				this._globalTransformMatrix.tx += this._globalTransformMatrix.a * pivotX + this._globalTransformMatrix.c * pivotY;
				this._globalTransformMatrix.ty += this._globalTransformMatrix.b * pivotX + this._globalTransformMatrix.d * pivotY;
			}
		}
		
		/** @private */
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
			_slot._displayBridge.updateColor(
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
		override dragonBones_internal function arriveAtFrame(frame:Frame, timelineState:TimelineState, animationState:AnimationState, isCross:Boolean):void
		{
			if(frame)
			{
				var mixingType:int = animationState.getMixingTransform(name);
				if(animationState.displayControl && (mixingType == 2 || mixingType == -1))
				{
					var tansformFrame:TransformFrame = frame as TransformFrame;
					if(_slot)
					{
						var displayIndex:int = tansformFrame.displayIndex;
						if(displayIndex >= 0)
						{
							if(tansformFrame.zOrder != _slot._tweenZorder)
							{
								_slot._tweenZorder = tansformFrame.zOrder;
								_armature._slotsZOrderChanged = true;
							}
						}
						_slot.changeDisplay(displayIndex);
						_slot.visible = tansformFrame.visible;
					}
				}
				
				if(frame.event && _armature.hasEventListener(FrameEvent.OBJECT_FRAME_EVENT))
				{
					var frameEvent:FrameEvent = new FrameEvent(FrameEvent.OBJECT_FRAME_EVENT);
					frameEvent.object = this;
					frameEvent.animationState = animationState;
					frameEvent.frameLabel = frame.event;
					_armature.dispatchEvent(frameEvent);
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
				if(_slot)
				{
					_slot.changeDisplay(-1);
				}
			}
		}
		
		public function contains(child:DBObject):Boolean
		{
			if(!child)
			{
				throw new ArgumentError();
			}
			if(child == this)
			{
				return false;
			}
			var ancestor:DBObject = child;
			while (!(ancestor == this || ancestor == null))
			{
				ancestor = ancestor.parent;
			}
			return ancestor == this;
		}
		
		public function addChild(child:DBObject):void
		{
			if(!child)
			{
				throw new ArgumentError();
			}
			
			var bone:Bone = child as Bone;
			if(child == this || (bone && bone.contains(this)))
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
			
			if(!_slot && child is Slot)
			{
				_slot = child as Slot;
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
				
				if(_slot && child == _slot)
				{
					_slot = null;
				}
			}
			else
			{
				throw new ArgumentError();
			}
		}
	}
}