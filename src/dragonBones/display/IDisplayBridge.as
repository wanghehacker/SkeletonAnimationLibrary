package dragonBones.display
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
	
	/**
	 * Provides an interface for display classes that can be used in this skeleton animation system.
	 *
	 */
	public interface IDisplayBridge
	{
		function get visible():Boolean;
		function set visible(value:Boolean):void;
		/**
		 * Indicates the original display object relative to specific display engine.
		 */
		function get display():Object;
		function set display(value:Object):void;
		/**
		 * Updates the transform of the display object
		 * @param	matrix
		 * @param	transform
		 * @param	pivot
		 * @param	colorTransform
		 */
		function update(matrix:Matrix, transform:DBTransform, colorTransform:ColorTransform):void;
		/**
		 * Adds the original display object to another display object.
		 * @param	container
		 * @param	index
		 */
		function addDisplay(container:Object, index:int = -1):void;
		/**
		 * remove the original display object from its parent.
		 */
		function removeDisplay():void;
	}
}