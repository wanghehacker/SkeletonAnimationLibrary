﻿package dragonBones.display
{
	/**
	* Copyright 2012-2013. DragonBones. All Rights Reserved.
	* @playerversion Flash 10.0
	* @langversion 3.0
	* @version 2.0
	*/

	
	import dragonBones.objects.DBTransform;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	import starling.display.Image;
	
	/**
	 * The StarlingDisplayBridge class is an implementation of the IDisplayBridge interface for starling.display.DisplayObject.
	 *
	 */
	public class StarlingDisplayBridge implements IDisplayBridge
	{
		private var _display:Object;
		/**
		 * @inheritDoc
		 */
		public function get display():Object
		{
			return _display;
		}
		/**
		 * @private
		 */
		public function set display(value:Object):void
		{
			if (_display == value)
			{
				return;
			}
			
			if (_display)
			{
				var parent:* = _display.parent;
				if (parent)
				{
					var index:int = _display.parent.getChildIndex(_display);
				}
				removeDisplay();
			}
			_display = value;
			addDisplay(parent, index);
		}
		
		public function get visible():Boolean
		{
			return _display?_display.visible:false;
		}
		public function set visible(value:Boolean):void
		{
			if(_display)
			{
				_display.visible = value;
			}
		}
		
		/**
		 * Creates a new StarlingDisplayBridge instance.
		 */
		public function StarlingDisplayBridge()
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function updateTransform(matrix:Matrix, transform:DBTransform):void
		{
			var pivotX:Number = _display.pivotX;
			var pivotY:Number = _display.pivotY;
			matrix.tx -= matrix.a * pivotX + matrix.c * pivotY;
			matrix.ty -= matrix.b * pivotX + matrix.d * pivotY;
			//if(updateStarlingDisplay)
			//{
			//_display.transformationMatrix = matrix;
			//}
			//else
			//{
			_display.transformationMatrix.copyFrom(matrix);
			//}
		}
		
		/**
		 * @inheritDoc
		 */
		public function updateColor(
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
			if (_display is Quad)
			{
				(_display as Quad).alpha = aMultiplier;
				(_display as Quad).color = (uint(rMultiplier * 0xff) << 16) + (uint(gMultiplier * 0xff) << 8) + uint(bMultiplier * 0xff);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function addDisplay(container:Object, index:int = -1):void
		{
			if (container && _display)
			{
				if (index < 0)
				{
					container.addChild(_display);
				}
				else
				{
					container.addChildAt(_display, Math.min(index, container.numChildren));
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeDisplay():void
		{
			if (_display && _display.parent)
			{
				_display.parent.removeChild(_display);
			}
		}
	}
}