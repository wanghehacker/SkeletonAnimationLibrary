package dragonBones.events
{
	/**
	* Copyright 2012-2013. DragonBones. All Rights Reserved.
	* @playerversion Flash 10.0, Flash 10
	* @langversion 3.0
	* @version 2.0
	*/
	import dragonBones.Armature;
	import dragonBones.animation.AnimationState;
	import dragonBones.core.DBObject;
	
	import flash.events.Event;
	
	/**
	 * The FrameEvent class provides and defines all events dispatched by an Animation or Bone instance entering a new frame.
	 *
	 * 
	 * @see dragonBones.animation.Animation
	 */
	public class FrameEvent extends Event
	{
		public static function get MOVEMENT_FRAME_EVENT():String
		{
			return  ANIMATION_FRAME_EVENT;
		}
		
		public static function get BONE_FRAME_EVENT():String
		{
			return  OBJECT_FRAME_EVENT;
		}
		
		/**
		 * Dispatched when the animation of the armatrue enter a frame.
		 */
		public static const ANIMATION_FRAME_EVENT:String = "animationFrameEvent";
		
		/**
		 * 
		 */
		public static const OBJECT_FRAME_EVENT:String ="objectFrameEvent";
		
		/**
		 * The entered frame label.
		 */
		public var frameLabel:String;
		
		public var object:DBObject;
		
		/**
		 * The armature that is the target of this event.
		 */
		public function get armature():Armature
		{
			return target as Armature;
		}
		
		/**
		 * The animationState instance.
		 */
		public var animationState:AnimationState;
		
		/**
		 * Creates a new FrameEvent instance.
		 * @param	type
		 * @param	cancelable
		 */
		public function FrameEvent(type:String, cancelable:Boolean = false)
		{
			super(type, false, cancelable);
		}
		
		/**
		 * @private
		 *
		 * @return An exact duplicate of the current object.
		 */
		override public function clone():Event
		{
			var event:FrameEvent = new FrameEvent(type, cancelable);
			event.animationState = animationState;
			event.object = object;
			event.frameLabel = frameLabel;
			return event;
		}
	}
}