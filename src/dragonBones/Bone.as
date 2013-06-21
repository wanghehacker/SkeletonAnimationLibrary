package dragonBones
{
	import dragonBones.core.DBObject;
	import dragonBones.core.dragonBones_internal;
	
	import flash.geom.Point;
	
	use namespace dragonBones_internal;
	
	public class Bone extends DBObject
	{
		//0/1/2
		public var scaleMode:int;
		
		dragonBones_internal var _defaultSlot:Slot;
		dragonBones_internal var _pivot:Point;
		
		private var _children:Vector.<DBObject>;
		
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
			if(this._armature)
			{
				this._armature.removeBoneFrom(this);
			}
			super.setArmature(value);
			if(this._armature)
			{
				this._armature.addBoneTo(this);
			}
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
				this._globalTransformMatrix.tx -= this._globalTransformMatrix.a * pivotX + this._globalTransformMatrix.c * pivotY;
				this._globalTransformMatrix.ty -= this._globalTransformMatrix.b * pivotX + this._globalTransformMatrix.d * pivotY;
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
		}
	}
}