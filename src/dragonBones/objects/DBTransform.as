package dragonBones.objects
{
	/**
	* Copyright 2012-2013. DragonBones. All Rights Reserved.
	* @playerversion Flash 10.0
	* @langversion 3.0
	* @version 2.0
	*/

	/**
	 * The BoneTransform class provides transformation properties and methods for Bone instances.
	 * @example
	 * <p>Download the example files <a href='http://dragonbones.github.com/downloads/DragonBones_Tutorial_Assets.zip'>here</a>: </p>
	 * <p>This example gets the BoneTransform of the head bone and adjust the x and y registration by 60 pixels.</p>
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
	 * 				var bone:Bone = armature.getBone("head");
	 * 				bone.origin.pivotX = 60;//origin BoneTransform
	 *				bone.origin.pivotY = 60;//origin BoneTransform
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
	 * @see dragonBones.animation.Animation
	 */
	public class DBTransform
	{
		/**
		 * Position on the x axis.
		 */
		public var x:Number;
		/**
		 * Position on the y axis.
		 */
		public var y:Number;
		/**
		 * Skew on the x axis.
		 */
		public var skewX:Number;
		/**
		 * skew on the y axis.
		 */
		public var skewY:Number;
		/**
		 * Scale on the x axis.
		 */
		public var scaleX:Number;
		/**
		 * Scale on the y axis.
		 */
		public var scaleY:Number;
		/**
		 * The rotation of that BoneTransform instance.
		 */
		public function get rotation():Number
		{
			return skewX;
		}
		public function set rotation(value:Number):void
		{
			skewX = skewY = value;
		}
		/**
		 * Creat a new BoneTransform instance.
		 */
		public function DBTransform()
		{
			x = 0;
			y = 0;
			skewX = 0;
			skewY = 0;
			scaleX = 1
			scaleY = 1;
		}
		/**
		 * Copy all properties from this BoneTransform instance to the passed BoneTransform instance.
		 * @param	node
		 */
		public function copy(transform:DBTransform):void
		{
			x = transform.x;
			y = transform.y;
			skewX = transform.skewX;
			skewY = transform.skewY;
			scaleX = transform.scaleX;
			scaleY = transform.scaleY;
		}
		/**
		 * Get a string representing all BoneTransform property values.
		 * @return String All property values in a formatted string.
		 */
		public function toString():String
		{
			var string:String = "x:" + x + " y:" + y + " skewX:" + skewX + " skewY:" + skewY + " scaleX:" + scaleX + " scaleY:" + scaleY;
			return string;
		}
	}
}