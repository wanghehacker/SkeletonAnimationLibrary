package dragonBones
{
	import dragonBones.animation.Animation;
	import dragonBones.animation.IAnimatable;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.ArmatureEvent;
	import dragonBones.objects.DBTransform;
	
	import flash.geom.ColorTransform;
	
	use namespace dragonBones_internal;
	/**
	 * Dispatched when the movement of animation is changed.
	 */
	[Event(name="movementChange", type="dragonBones.events.AnimationEvent")]
	
	/**
	 * Dispatched when the playback of a animation starts.
	 */
	[Event(name="start", type="dragonBones.events.AnimationEvent")]
	
	/**
	 * Dispatched when the playback of a animation stops.
	 */
	[Event(name="complete", type="dragonBones.events.AnimationEvent")]
	
	/**
	 * Dispatched when the playback of a animation completes a loop.
	 */
	[Event(name="loopComplete", type="dragonBones.events.AnimationEvent")]
	
	/**
	 * Dispatched when the animation of the armature enter a frame.
	 */
	[Event(name="movementFrameEvent", type="dragonBones.events.FrameEvent")]
	
	/**
	 * Dispatched when a bone of the armature enters a frame.
	 */
	[Event(name="boneFrameEvent", type="dragonBones.events.FrameEvent")]

	public class Armature extends Bone implements IAnimatable
	{
		private static var _helpArray:Array = [];
		
		/** @private */
		dragonBones_internal var _slotsZOrderChanged:Boolean;
		/** @private */
		dragonBones_internal var _slotList:Vector.<Slot>;
		/** @private */
		dragonBones_internal var _boneList:Vector.<Bone>;
		
		/** @private */
		protected var _display:Object;
		/**
		 * Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
		 */
		override public function get display():Object
		{
			return _display;
		}
		
		/** @private */
		protected var _animation:Animation;
		/**
		 * An Animation instance
		 * @see dragonBones.animation.Animation
		 */
		public function get animation():Animation
		{
			return _animation;
		}

		/**
		 * Creates a Armature blank instance.
		 * @param	Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
		 */
		public function Armature(display:Object)
		{
			super();
			_display = display;
			
			_animation = new Animation(this);
			_slotsZOrderChanged = false;
			
			_slotList = new Vector.<Slot>;
			_slotList.fixed = true;
			_boneList = new Vector.<Bone>;
			_boneList.fixed = true;
		}
		
		/**
		 * Cleans up resources used by this Armature instance.
		 */
		override public function dispose():void
		{
			super.dispose();
			
			_animation.dispose();
			_slotList.fixed = false;
			_slotList.length = 0;
			_boneList.fixed = false;
			_boneList.length = 0;
			
			_animation = null;
			_slotList = null;
			_boneList = null;
			
			//_display = null;
		}
		
		/**
		 * Update the animation using this method typically in an ENTERFRAME Event or with a Timer.
		 * @param	The amount of second to move the playhead ahead.
		 */
		public function advanceTime(passedTime:Number):void
		{
			_animation.advanceTime(passedTime);
			
			var i:int = _boneList.length;
			while(i --)
			{
				_boneList[i].update();
			}
			
			i = _slotList.length;
			while(i --)
			{
				var slot:Slot = _slotList[i];
				slot.update();
				if(slot._displayBridge.display)
				{
					var childArmature:Armature = slot.childArmature;
					if(childArmature)
					{
						childArmature.advanceTime(passedTime);
					}
				}
			}
			
			if(_slotsZOrderChanged)
			{
				sortSlotsZOrder();
			}
			
			update();
		}
		
		public function getSlots():Vector.<Slot>
		{
			return _slotList;
		}
		
		public function getBones():Vector.<Bone>
		{
			return _boneList;
		}
		
		public function getSlot(slotName:String):Slot
		{
			var i:int = _slotList.length;
			while(i --)
			{
				if(_slotList[i].name == slotName)
				{
					return _slotList[i];
				}
			}
			return null;
		}
		
		public function getSlotByDisplay(display:Object):Slot
		{
			var i:int = _slotList.length;
			while(i --)
			{
				if(_slotList[i].display == display)
				{
					return _slotList[i];
				}
			}
			return null;
		}
		
		public function addSlot(slot:Slot, parentName:String = null):void
		{
			if(!slot)
			{
				throw new ArgumentError();
			}
			
			if(parentName)
			{
				var boneParent:Bone = getBone(parentName);
				if (boneParent)
				{
					boneParent.addChild(slot);
				}
				else
				{
					throw new ArgumentError();
				}
			}
			else
			{
				this.addChild(slot);
			}
		}
		
		public function removeSlot(slot:Slot):void
		{
			if(!slot)
			{
				throw new ArgumentError();
			}
			
			if(_slotList.indexOf(slot) >= 0)
			{
				slot.parent.removeChild(slot);
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		public function getBone(boneName:String):Bone
		{
			var i:int = _boneList.length;
			while(i --)
			{
				if(_boneList[i].name == boneName)
				{
					return _boneList[i];
				}
			}
			return null;
		}
		
		public function getBoneByDisplay(display:Object):Bone
		{
			var slot:Slot = getSlotByDisplay(display);
			return slot?slot.parent:null;
		}
		
		public function addBone(bone:Bone, parentName:String = null):void
		{
			if(!bone)
			{
				throw new ArgumentError();
			}
			if(parentName)
			{
				var boneParent:Bone = getBone(parentName);
				if (boneParent)
				{
					boneParent.addChild(bone);
				}
				else
				{
					throw new ArgumentError();
				}
			}
			else
			{
				this.addChild(bone);
			}
		}
		
		/**
		 * Remove a Bone instance from this Armature instance.
		 * @param	The name of the Bone instance to remove.
		 * @see dragonBones.Bone
		 */
		public function removeBone(bone:Bone):void
		{
			if(!bone)
			{
				throw new ArgumentError();
			}
			
			if(_boneList.indexOf(bone) >= 0)
			{
				bone.parent.removeChild(bone);
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		public function sortSlotsZOrder():void
		{
			_slotList.fixed = false;
			_slotList.sort(sortSlot);
			_slotList.fixed = true;
			var i:int = _slotList.length;
			while(i --)
			{
				var slot:Slot = _slotList[i];
				if(slot.display)
				{
					slot._displayBridge.addDisplay(display);
				}
			}
			_slotsZOrderChanged = false;
		}
		
		/** @private */
		dragonBones_internal function addSlotTo(slot:Slot):void
		{
			if(_slotList.indexOf(slot) < 0)
			{
				_slotList.fixed = false;
				_slotList[_slotList.length] = slot;
				_slotList.fixed = true;
			}
		}
		
		/** @private */
		dragonBones_internal function removeSlotFrom(slot:Slot):void
		{
			var index:int = _slotList.indexOf(slot);
			if(index >= 0)
			{
				_slotList.fixed = false;
				_slotList.splice(index, 1);
				_slotList.fixed = true;
			}
		}
		
		/** @private */
		dragonBones_internal function addBoneTo(bone:Bone):void
		{
			if(_boneList.indexOf(bone) < 0)
			{
				_boneList.fixed = false;
				_boneList[_boneList.length] = bone;
				sortBoneList();
				_boneList.fixed = true;
			}
		}
		
		/** @private */
		dragonBones_internal function removeBoneFrom(bone:Bone):void
		{
			var index:int = _boneList.indexOf(bone);
			if(index >= 0)
			{
				_boneList.fixed = false;
				_boneList.splice(index, 1);
				_boneList.fixed = true;
			}
		}
		
		private function sortSlot(slot1:Slot, slot2:Slot):int
		{
			return slot1.zOrder < slot2.zOrder?1: -1;
		}
		
		private function sortBoneList():void
		{
			var i:int = _boneList.length;
			if(i == 0)
			{
				return;
			}
			_helpArray.length = 0;
			while(i --)
			{
				var level:int = 0;
				var bone:Bone = _boneList[i];
				var boneParent:Bone = bone;
				while(boneParent)
				{
					level ++;
					boneParent = boneParent.parent;
				}
				_helpArray[i] = {level:level, bone:bone};
			}
			
			_helpArray.sortOn("level", Array.NUMERIC|Array.DESCENDING);
			
			i = _helpArray.length;
			while(i --)
			{
				_boneList[i] = _helpArray[i].bone;
			}
			_helpArray.length = 0;
		}
		
	}
}