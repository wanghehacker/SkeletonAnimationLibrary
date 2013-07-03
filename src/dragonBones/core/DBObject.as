package dragonBones.core
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.animation.AnimationState;
	import dragonBones.animation.TimelineState;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.Frame;
	
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	
	use namespace dragonBones_internal;
	
	public class DBObject extends EventDispatcher
	{	
		
		public var name:String;
		public var userData:Object;
		public var fixedRotation:Boolean;
		
		/** @private */
		protected var _globalTransformMatrix:Matrix;
		/** @private */
		protected var _scaleType:int;
		/** @private */
		dragonBones_internal var _isColorChanged:Boolean;
		
		/** @private */
		protected var _global:DBTransform;
		public function get global():DBTransform
		{
			return _global;
		}
		
		/** @private */
		protected var _origin:DBTransform;
		public function get origin():DBTransform
		{
			return _origin;
		}
		
		/** @private */
		protected var _node:DBTransform;
		public function get node():DBTransform
		{
			return _node;
		}
		
		/** @private */
		dragonBones_internal var _tween:DBTransform;
		
		/** @private */
		protected var _visible:Boolean;
		public function get visible():Boolean
		{
			return _visible;
		}
		public function set visible(value:Boolean):void
		{
			_visible = value;
		}
		
		/** @private */
		protected var _parent:Bone;
		public function get parent():Bone
		{
			return _parent;
		}
		/** @private */
		dragonBones_internal function setParent(value:Bone):void
		{
			_parent = value;
			if(_parent)
			{
				if(_parent is Armature)
				{
					setArmature(_parent as Armature);
				}
				else
				{
					setArmature(_parent.armature);
				}
			}
			else
			{
				setArmature(null);
			}
		}
		
		/** @private */
		protected var _armature:Armature;
		public function get armature():Armature
		{
			return _armature;
		}
		/** @private */
		dragonBones_internal function setArmature(value:Armature):void
		{
			if(_armature)
			{
				_armature.removeDBObject(this);
			}
			_armature = value;
			if(_armature)
			{
				_armature.addDBObject(this);
			}
		}
		
		public function DBObject()
		{
			super(this);
			
			_global = new DBTransform();
			_origin = new DBTransform();
			_node = new DBTransform();
			_tween = new DBTransform();
			_tween.scaleX = _tween.scaleY = 0;
			
			_globalTransformMatrix = new Matrix();
			
			_visible = true;
		}
		
		public function dispose():void
		{
			userData = null;
			_parent = null;
			_armature = null;
			_global = null;
			_origin = null;
			_node = null;
			_tween = null;
			_globalTransformMatrix = null;
		}
		
		/** @private */
		dragonBones_internal function update():void
		{
			_global.scaleX = (_origin.scaleX + _tween.scaleX) * _node.scaleX;
			_global.scaleY = (_origin.scaleY + _tween.scaleY) * _node.scaleY;
			
			if(_parent != _armature)
			{
				var x:Number = _origin.x + _node.x + _tween.x;
				var y:Number = _origin.y + _node.y + _tween.y;
				var parentMatrix:Matrix = _parent._globalTransformMatrix;
				
				_globalTransformMatrix.tx = _global.x = parentMatrix.a * x + parentMatrix.c * y + parentMatrix.tx;
				_globalTransformMatrix.ty = _global.y = parentMatrix.d * y + parentMatrix.b * x + parentMatrix.ty;
				
				if(fixedRotation)
				{
					_global.skewX = _origin.skewX + _node.skewX + _tween.skewX;
					_global.skewY = _origin.skewY + _node.skewY + _tween.skewY;
				}
				else
				{
					_global.skewX = _origin.skewX + _node.skewX + _tween.skewX + _parent._global.skewX;
					_global.skewY = _origin.skewY + _node.skewY + _tween.skewY + _parent._global.skewY;
				}
				
				if(_parent.scaleMode >= _scaleType)
				{
					_global.scaleX *= _parent._global.scaleX;
					_global.scaleY *= _parent._global.scaleY;
				}
			}
			else
			{
				_globalTransformMatrix.tx = _global.x = _origin.x + _node.x + _tween.x;
				_globalTransformMatrix.ty = _global.y = _origin.y + _node.y + _tween.y;
				
				_global.skewX = _origin.skewX + _node.skewX + _tween.skewX;
				_global.skewY = _origin.skewY + _node.skewY + _tween.skewY;
			}
			
			_globalTransformMatrix.a = _global.scaleX * Math.cos(_global.skewY);
			_globalTransformMatrix.b = _global.scaleX * Math.sin(_global.skewY);
			_globalTransformMatrix.c = -_global.scaleY * Math.sin(_global.skewX);
			_globalTransformMatrix.d = _global.scaleY * Math.cos(_global.skewX);
		}
		
		/** @private */
		dragonBones_internal function updateColor(
			aOffset:Number,
			rOffset:Number,
			gOffset:Number,
			bOffset:Number,
			aMultiplier:Number,
			rMultiplier:Number,
			gMultiplier:Number,
			bMultiplier:Number,
			isColorChanged:Boolean
		):void
		{
			 
		}
			
		/** @private */
		dragonBones_internal function arriveAtFrame(frame:Frame, timelineState:TimelineState, animationState:AnimationState, isCross:Boolean):void
		{
		}
	}
}