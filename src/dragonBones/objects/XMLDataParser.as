package dragonBones.objects
{
	/**
	* Copyright 2012-2013. DragonBones. All Rights Reserved.
	* @playerversion Flash 10.0, Flash 10
	* @langversion 3.0
	* @version 2.0
	*/
	import dragonBones.animation.Animation;
	import dragonBones.animation.AnimationState;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.utils.BytesType;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.DBDataUtils;
	import dragonBones.utils.TransformUtils;
	
	import flash.geom.ColorTransform;
	import flash.utils.ByteArray;

	use namespace dragonBones_internal;
	/**
	 * The XMLDataParser xlass creates and parses xml data from dragonBones generated maps.
	 */
	public class XMLDataParser
	{
		private static const ANGLE_TO_RADIAN:Number = Math.PI / 180;
		
		private static var _frameRate:uint;
		private static var _helpTransform1:DBTransform = new DBTransform();
		private static var _helpTransform2:DBTransform = new DBTransform();
		private static var _currentSkeletonData:SkeletonData;
		
		private static function checkVersion(skeletonXML:XML):void
		{
			var version:String = skeletonXML.@[ConstValues.A_VERSION];
			switch (version)
			{
				case "1.5":
				case "2.0":
				case "2.1":
				case "2.1.1":
				case "2.1.2":
				case ConstValues.VERSION:
					break;
				default: 
					throw new Error("Nonsupport version!");
			}
		}
		/**
		 * Compress all data into a ByteArray for serialization.
		 * @param	skeletonXML The Skeleton data.
		 * @param	textureAtlasXML The TextureAtlas data.
		 * @param	byteArray The ByteArray representing the map.
		 * @return ByteArray. A DragonBones compatible ByteArray.
		 */
		public static function compressData(skeletonXML:XML, textureAtlasXML:XML, byteArray:ByteArray):ByteArray
		{
			var byteArrayCopy:ByteArray = new ByteArray();
			byteArrayCopy.writeBytes(byteArray);
			
			var xmlBytes:ByteArray = new ByteArray();
			xmlBytes.writeUTFBytes(textureAtlasXML.toXMLString());
			xmlBytes.compress();
			
			byteArrayCopy.position = byteArrayCopy.length;
			byteArrayCopy.writeBytes(xmlBytes);
			byteArrayCopy.writeInt(xmlBytes.length);
			
			xmlBytes.length = 0;
			xmlBytes.writeUTFBytes(skeletonXML.toXMLString());
			xmlBytes.compress();
			
			byteArrayCopy.position = byteArrayCopy.length;
			byteArrayCopy.writeBytes(xmlBytes);
			byteArrayCopy.writeInt(xmlBytes.length);
			
			return byteArrayCopy;
		}
		/**
		 * Decompress a compatible DragonBones data.
		 * @param	compressedByteArray The ByteArray to decompress.
		 * @return A DecompressedData instance.
		 */
		public static function decompressData(compressedByteArray:ByteArray):DecompressedData
		{
			var dataType:String = BytesType.getType(compressedByteArray);
			switch (dataType)
			{
				case BytesType.SWF: 
				case BytesType.PNG: 
				case BytesType.JPG: 
				case BytesType.ATF: 
					try
					{
						compressedByteArray.position = compressedByteArray.length - 4;
						var strSize:int = compressedByteArray.readInt();
						var position:uint = compressedByteArray.length - 4 - strSize;
						
						var xmlBytes:ByteArray = new ByteArray();
						xmlBytes.writeBytes(compressedByteArray, position, strSize);
						xmlBytes.uncompress();
						compressedByteArray.length = position;
						
						var skeletonXML:XML = XML(xmlBytes.readUTFBytes(xmlBytes.length));
						
						compressedByteArray.position = compressedByteArray.length - 4;
						strSize = compressedByteArray.readInt();
						position = compressedByteArray.length - 4 - strSize;
						
						xmlBytes.length = 0;
						xmlBytes.writeBytes(compressedByteArray, position, strSize);
						xmlBytes.uncompress();
						compressedByteArray.length = position;
						var textureAtlasXML:XML = XML(xmlBytes.readUTFBytes(xmlBytes.length));
					}
					catch (e:Error)
					{
						throw new Error("Data error!");
					}
					var decompressedData:DecompressedData = new DecompressedData(skeletonXML, textureAtlasXML, compressedByteArray);
					decompressedData.dataType = dataType;
					return decompressedData;
				case BytesType.ZIP:
					throw new Error("Can not decompress zip!");
				default: 
					throw new Error("Nonsupport data!");
			}
			return null;
		}
		/**
		 * Parse the SkeletonData.
		 * @param	skeletonXML The Skeleton xml to parse.
		 * @return A SkeletonData instance.
		 */
		public static function parseSkeletonData(skeletonXML:XML):SkeletonData
		{
			checkVersion(skeletonXML);
			_frameRate = int(skeletonXML.@[ConstValues.A_FRAME_RATE]);
			
			var skeletonData:SkeletonData = new SkeletonData();
			skeletonData.name = skeletonXML.@[ConstValues.A_NAME];
			
			_currentSkeletonData = skeletonData;
			
			var armatureXMLList:XMLList = skeletonXML[ConstValues.ARMATURES][ConstValues.ARMATURE];
			var i:int = armatureXMLList.length();
			while(i --)
			{
				skeletonData.addArmatureData(parseArmatureData(armatureXMLList[i]));
			}
			
			var animationsXMLList:XMLList = skeletonXML[ConstValues.ANIMATIONS][ConstValues.ANIMATION];
			i = animationsXMLList.length();
			while(i --)
			{
				var animationsXML:XML = animationsXMLList[i];
				var armatureData:ArmatureData = skeletonData.getArmatureData(animationsXML.@[ConstValues.A_NAME]);
				if(armatureData)
				{
					for each(var animationXML:XML in animationsXML[ConstValues.MOVEMENT])
					{
						armatureData.addAnimationData(parseAnimationData(animationXML, armatureData));
					}
				}
			}
			
			_currentSkeletonData = null;
			
			return skeletonData;
		}
		
		private static function parseArmatureData(armatureXML:XML):ArmatureData
		{
			var armatureData:ArmatureData = new ArmatureData();
			armatureData.name = armatureXML.@[ConstValues.A_NAME];
			
			var boneXMLList:XMLList = armatureXML[ConstValues.BONE];
			var i:int = boneXMLList.length();
			while(i --)
			{
				armatureData.addBoneData(parseBoneData(boneXMLList[i]));
			}
			
			armatureData.addSkinData(parseSkinData(armatureXML));
			
			armatureData.sortBoneDataList();
			
			DBDataUtils.transformArmatureData(armatureData);
			
			return armatureData;
		}
		
		private static function parseBoneData(boneXML:XML):BoneData
		{
			var boneData:BoneData = new BoneData();
			boneData.name = boneXML.@[ConstValues.A_NAME];
			boneData.parent = boneXML.@[ConstValues.A_PARENT];
			
			boneData.global = new DBTransform();
			boneData.global.x = boneData.transform.x = Number(boneXML.@[ConstValues.A_X]);
			boneData.global.y = boneData.transform.y = Number(boneXML.@[ConstValues.A_Y]);
			
			boneData.global.skewX = boneData.transform.skewX = Number(boneXML.@[ConstValues.A_SKEW_X]) * ANGLE_TO_RADIAN;
			boneData.global.skewY = boneData.transform.skewY = Number(boneXML.@[ConstValues.A_SKEW_Y]) * ANGLE_TO_RADIAN;
			
			boneData.global.scaleX = boneData.transform.scaleX = Number(boneXML.@[ConstValues.A_SCALE_X]);
			boneData.global.scaleY = boneData.transform.scaleY = Number(boneXML.@[ConstValues.A_SCALE_Y]);
			
			boneData.pivot.x = -Number(boneXML.@[ConstValues.A_PIVOT_X]);
			boneData.pivot.y = -Number(boneXML.@[ConstValues.A_PIVOT_Y]);
			
			return boneData;
		}
		
		private static function parseSkinData(armatureXML:XML):SkinData
		{
			var skinData:SkinData = new SkinData();
			//skinData.name
			for each(var boneXML:XML in armatureXML[ConstValues.BONE])
			{
				var slotData:SlotData = new SlotData();
				skinData.addSlotData(slotData);
				slotData.name = boneXML.@[ConstValues.A_NAME];
				slotData.parent = boneXML.@[ConstValues.A_NAME];
				slotData.zOrder = boneXML.@[ConstValues.A_Z];
				for each(var displayXML:XML in boneXML[ConstValues.DISPLAY])
				{
					var displayData:DisplayData = new DisplayData();
					slotData.addDisplayData(displayData);
					displayData.name = displayXML.@[ConstValues.A_NAME];
					
					if(displayXML.@[ConstValues.A_IS_ARMATURE] == "1")
					{
						displayData.type = DisplayData.ARMATURE;
					}
					else
					{
						displayData.type = DisplayData.IMAGE;
					}
					//
					displayData.transform.x = -Number(boneXML.@[ConstValues.A_PIVOT_X]);
					displayData.transform.y = -Number(boneXML.@[ConstValues.A_PIVOT_Y]);
					displayData.transform.scaleX = 1;
					displayData.transform.scaleY = 1;
					displayData.transform.skewX = 0;
					displayData.transform.skewY = 0;
					
					_currentSkeletonData.addSubTexturePivot(
						Number(displayXML.@[ConstValues.A_PIVOT_X]), 
						Number(displayXML.@[ConstValues.A_PIVOT_Y]), 
						displayData.name
					);
					
					displayData.pivot = _currentSkeletonData.getSubTexturePivot(displayData.name);
				}
			}
			
			return skinData;
		}
		
		private static function parseAnimationData(animationXML:XML, armatureData:ArmatureData):AnimationData
		{
			var animationData:AnimationData = new AnimationData();
			animationData.name = animationXML.@[ConstValues.A_NAME];
			animationData.frameRate = _frameRate;
			animationData.loop = int(animationXML.@[ConstValues.A_LOOP]) == 1?0:1;
			animationData.fadeTime = Number(animationXML.@[ConstValues.A_DURATION_TO]) / _frameRate;
			animationData.duration = Number(animationXML.@[ConstValues.A_DURATION])/ _frameRate;
			animationData.scale = animationData.duration / (Number(animationXML.@[ConstValues.A_DURATION_TWEEN]) / _frameRate);
			animationData.tweenEasing = Number(animationXML.@[ConstValues.A_TWEEN_EASING][0]);
			
			parseTimeline(animationXML, animationData, parseMainFrame);
			
			var timelineXMLList:XMLList = animationXML[ConstValues.BONE];
			var i:int = timelineXMLList.length();
			while(i --)
			{
				var timelineXML:XML = timelineXMLList[i];
				var timelineName:String = timelineXML.@[ConstValues.A_NAME];
				var durationScale:Number = Number(timelineXML.@[ConstValues.A_MOVEMENT_SCALE]);
				var durationOffset:Number = Number(timelineXML.@[ConstValues.A_MOVEMENT_DELAY]);
				
				var timeline:TransformTimeline = new TransformTimeline();
				timeline.duration = animationData.duration;
				timeline.scale = durationScale;
				timeline.offset = durationOffset;
				parseTimeline(timelineXML, timeline, parseTransformFrame);
				animationData.addTimeline(timeline, timelineName);
			}
			
			DBDataUtils.addHideTimeline(animationData, armatureData);
			
			DBDataUtils.transformAnimationData(animationData, armatureData);
			
			return animationData;
		}
		
		private static function parseTimeline(timelineXML:XML, timeline:Timeline, frameParser:Function):void
		{
			var position:Number = 0;
			for each(var frameXML:XML in timelineXML[ConstValues.FRAME])
			{
				var frame:Frame = frameParser(frameXML);
				frame.position = position;
				timeline.addFrame(frame);
				position += frame.duration;
			}
		}
		
		private static function parseFrame(frameXML:XML, frame:Frame):void
		{
			frame.duration = Number(frameXML.@[ConstValues.A_DURATION]) / _frameRate;
			frame.action = frameXML.@[ConstValues.A_MOVEMENT];
			frame.event = frameXML.@[ConstValues.A_EVENT];
			frame.sound = frameXML.@[ConstValues.A_SOUND];
		}
		
		private static function parseMainFrame(frameXML:XML):Frame
		{
			var frame:Frame = new Frame();
			parseFrame(frameXML, frame);
			return frame;
		}
		
		private static function parseTransformFrame(frameXML:XML):TransformFrame
		{
			var frame:TransformFrame = new TransformFrame();
			parseFrame(frameXML, frame);
			
			frame.visible = Boolean(frameXML.@[ConstValues.A_VISIBLE] != "0");
			frame.tweenEasing = Number(frameXML.@[ConstValues.A_TWEEN_EASING]);
			frame.tweenRotate = Number(frameXML.@[ConstValues.A_TWEEN_ROTATE]);
			frame.displayIndex = Number(frameXML.@[ConstValues.A_DISPLAY_INDEX]);
			frame.zOrder = Number(frameXML.@[ConstValues.A_Z]);
			
			frame.global = new DBTransform();
			
			frame.global.x = 
				frame.transform.x = Number(frameXML.@[ConstValues.A_X]);
			
			frame.global.y = 
				frame.transform.y =  Number(frameXML.@[ConstValues.A_Y]);
			
			frame.global.skewX = 
				frame.transform.skewX = Number(frameXML.@[ConstValues.A_SKEW_X]) * ANGLE_TO_RADIAN;
			
			frame.global.skewY = 
				frame.transform.skewY = Number(frameXML.@[ConstValues.A_SKEW_Y]) * ANGLE_TO_RADIAN;
			
			frame.global.scaleX = 
				frame.transform.scaleX = Number(frameXML.@[ConstValues.A_SCALE_X]);
			
			frame.global.scaleY = 
				frame.transform.scaleY = Number(frameXML.@[ConstValues.A_SCALE_Y]);
			
			frame.pivot.x = -Number(frameXML.@[ConstValues.A_PIVOT_X]);
			frame.pivot.y = -Number(frameXML.@[ConstValues.A_PIVOT_Y]);
			
			var colorTransformXML:XML = frameXML[ConstValues.COLOR_TRANSFORM][0];
			if(colorTransformXML)
			{
				frame.color = new ColorTransform();
				frame.color.alphaOffset = Number(colorTransformXML.@[ConstValues.A_ALPHA]);
				frame.color.redOffset = Number(colorTransformXML.@[ConstValues.A_RED]);
				frame.color.greenOffset = Number(colorTransformXML.@[ConstValues.A_GREEN]);
				frame.color.blueOffset = Number(colorTransformXML.@[ConstValues.A_BLUE]);
				
				frame.color.alphaMultiplier = Number(colorTransformXML.@[ConstValues.A_ALPHA_MULTIPLIER]) * 0.01;
				frame.color.redMultiplier = Number(colorTransformXML.@[ConstValues.A_RED_MULTIPLIER]) * 0.01;
				frame.color.greenMultiplier = Number(colorTransformXML.@[ConstValues.A_GREEN_MULTIPLIER]) * 0.01;
				frame.color.blueMultiplier = Number(colorTransformXML.@[ConstValues.A_BLUE_MULTIPLIER]) * 0.01;
			}
			
			return frame;
		}
	}
}