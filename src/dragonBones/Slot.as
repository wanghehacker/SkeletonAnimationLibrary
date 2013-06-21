package dragonBones
{
	import dragonBones.core.DBObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.display.IDisplayBridge;
	import dragonBones.objects.DisplayData;
	
	use namespace dragonBones_internal;
	
	public class Slot extends DBObject
	{
		public var zOrder:Number;
		
		/** @private */
		dragonBones_internal var _dislayDataList:Vector.<DisplayData>;
		/** @private */
		dragonBones_internal var _displayBridge:IDisplayBridge;
		
		private var _displayIndex:int;
		
		public function get display():Object
		{
			var display:Object = _displayList[_displayIndex];
			if(display is Armature)
			{
				return display.display;
			}
			return display;
		}
		public function set display(value:Object):void
		{
			_displayList[_displayIndex] = value;
			_displayBridge.display = value;
		}
		
		public function get childArmature():Armature
		{
			return _displayList[_displayIndex] as Armature;
		}
		public function set childArmature(value:Armature):void
		{
			_displayList[_displayIndex] = value;
			if(value)
			{
				_displayBridge.display = value.display;
			}
		}
		
		private var _displayList:Array;
		public function get displayList():Array
		{
			return _displayList;
		}
		public function set displayList(value:Array):void
		{
			if(!value)
			{
				throw new ArgumentError();
			}
			var i:int = _displayList.length = value.length;
			while(i --)
			{
				_displayList[i] = value[i];
			}
			
			if(_displayIndex >= 0)
			{
				_displayIndex = -1;
				changeDisplay(_displayIndex);
			}
		}
		
		/** @private */
		dragonBones_internal function changeDisplay(displayIndex:int):void
		{
			if(displayIndex < 0)
			{
				if(_displayBridge.display)
				{
					_displayBridge.display = null;
					if(childArmature)
					{
						childArmature.animation.stop();
						childArmature.animation._lastAnimationState = null;
					}
				}
			}
			else if(_displayIndex != displayIndex || !_displayBridge.display)
			{
				var length:uint = _displayList.length;
				if(displayIndex >= length && length > 0)
				{
					displayIndex = length - 1;
				}
				_displayIndex = displayIndex;
				var content:Object = _displayList[_displayIndex];
				if(content is Armature)
				{
					_displayBridge.display = (content as Armature).display;
				}
				else
				{
					_displayBridge.display = content;
				}
				
				if(_dislayDataList && _displayIndex <= _dislayDataList.length)
				{
					this._origin.copy(_dislayDataList[_displayIndex].transform);
				}
				
				if(this._armature)
				{
					_displayBridge.addDisplay(this._armature.display, this._armature._slotList.indexOf(this));
					this._armature._slotsZOrderChanged = true;
					if(childArmature)
					{
						childArmature.animation.play();
					}
				}
			}
		}
		
		override public function set visible(value:Boolean):void
		{
			if(value != this._visible)
			{
				_displayBridge.visible = this._visible = value;
			}
		}
		
		override dragonBones_internal function setArmature(value:Armature):void
		{
			if(this._armature)
			{
				this._armature.removeSlotFrom(this);
			}
			super.setArmature(value);
			if(this._armature)
			{
				this._armature.addSlotTo(this);
				_displayBridge.addDisplay(this._armature.display);
			}
			else
			{
				_displayBridge.removeDisplay();
			}
		}
		
		public function Slot(displayBrideg:IDisplayBridge)
		{
			super();
			_displayBridge = displayBrideg;
			_displayList = [];
			_displayIndex = -1;
			_scaleType = 1;
			zOrder = 0;
		}
		
		override public function dispose():void
		{
			super.dispose();
			
			_displayBridge.display = null;
			_displayList.length = 0;
			
			_displayBridge = null;
			_displayList = null;
			_dislayDataList = null;
		}
		
		override dragonBones_internal function update():void
		{
			super.update();
			
			if(_displayBridge.display)
			{
				/*
				var colorTransform:ColorTransform;
				
				if(_tween._differentColorTransform)
				{
				if(_armature.colorTransform)
				{
				_tweenColorTransform.concat(_armature.colorTransform);
				}
				colorTransform = _tweenColorTransform;
				}
				else if(_armature._colorTransformChange)
				{
				colorTransform = _armature.colorTransform;
				}
				*/
				_displayBridge.update(
					this._globalTransformMatrix,
					this._global,
					null
				);
			}
		}
	}
}