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
	import flash.geom.Point;
	import flash.utils.ByteArray;

	use namespace dragonBones_internal;
	/**
	 * The XMLDataParser xlass creates and parses xml data from dragonBones generated maps.
	 */
	public class XMLDataParser
	{
		private static const ANGLE_TO_RADIAN:Number = Math.PI / 180;
		
		private static var _currentSkeletonData:SkeletonData;
		
		private static function checkVersion(skeletonXML:XML):void
		{
			var version:String = skeletonXML.@[ConstValues.A_VERSION];
			switch (version)
			{
				case "1.4":
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
			
			var skeletonData:SkeletonData = new SkeletonData();
			skeletonData.name = skeletonXML.@[ConstValues.A_NAME];
			skeletonData.frameRate = int(skeletonXML.@[ConstValues.A_FRAME_RATE]);
			
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
			
			return boneData;
		}
		
		private static function parseSkinData(armatureXML:XML):SkinData
		{
			var skinData:SkinData = new SkinData();
			//skinData.name
			var boneXMLList:XMLList = armatureXML[ConstValues.BONE];
			var i:int = boneXMLList.length();
			while(i --)
			{
				var boneXML:XML = boneXMLList[i];
				var slotData:SlotData = new SlotData();
				skinData.addSlotData(slotData);
				slotData.name = boneXML.@[ConstValues.A_NAME];
				slotData.parent = boneXML.@[ConstValues.A_NAME];
				slotData.zOrder = boneXML.@[ConstValues.A_Z];
				var displayXMLList:XMLList = boneXML[ConstValues.DISPLAY];
				var j:int = displayXMLList.length();
				while(j --)
				{
					var displayXML:XML = displayXMLList[j];
					var displayData:DisplayData = new DisplayData();
					slotData.addDisplayData(displayData, j);
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
					displayData.transform.x = Number(boneXML.@[ConstValues.A_PIVOT_X]);
					displayData.transform.y = Number(boneXML.@[ConstValues.A_PIVOT_Y]);
					displayData.transform.skewX = 0;
					displayData.transform.skewY = 0;
					displayData.transform.scaleX = 1;
					displayData.transform.scaleY = 1;
					//
					_currentSkeletonData.addSubTexturePivot(Number(displayXML.@[ConstValues.A_PIVOT_X]), Number(displayXML.@[ConstValues.A_PIVOT_Y]), displayData.name);
				}
			}
			
			return skinData;
		}
		
		private static function parseAnimationData(animationXML:XML, armatureData:ArmatureData):AnimationData
		{
			var animationData:AnimationData = new AnimationData();
			animationData.name = animationXML.@[ConstValues.A_NAME];
			animationData.loop = int(animationXML.@[ConstValues.A_LOOP]) == 1?0:1;
			animationData.fadeTime = Number(animationXML.@[ConstValues.A_DURATION_TO]) / _currentSkeletonData.frameRate;
			animationData.duration = Number(animationXML.@[ConstValues.A_DURATION])/ _currentSkeletonData.frameRate;
			animationData.scale = animationData.duration / (Number(animationXML.@[ConstValues.A_DURATION_TWEEN]) / _currentSkeletonData.frameRate);
			animationData.tweenEasing = Number(animationXML.@[ConstValues.A_TWEEN_EASING][0]);
			
			var position:Number = 0;
			for each(var frameXML:XML in animationXML[ConstValues.FRAME])
			{
				var frame:Frame = parseMainFrame(frameXML);
				frame.position = position;
				animationData.addFrame(frame);
				position += frame.duration;
			}
			
			var boneAnimationXMLList:XMLList = animationXML[ConstValues.BONE];
			var i:int = boneAnimationXMLList.length();
			while(i --)
			{
				var boneAnimationXML:XML = boneAnimationXMLList[i];
				var name:String = boneAnimationXML.@[ConstValues.A_NAME];
				var durationScale:Number = Number(boneAnimationXML.@[ConstValues.A_MOVEMENT_SCALE]);
				var durationOffset:Number = Number(boneAnimationXML.@[ConstValues.A_MOVEMENT_DELAY]);
				
				var boneTimeline:TransformTimeline = new TransformTimeline();
				boneTimeline.duration = animationData.duration;
				boneTimeline.scale = durationScale;
				boneTimeline.offset = durationOffset;
				parseTimeline(boneAnimationXML, boneTimeline, parseTransformFrame);
				animationData.addBoneTimeline(boneTimeline, name);
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
			frame.duration = Number(frameXML.@[ConstValues.A_DURATION]) / _currentSkeletonData.frameRate;
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
			var transformFrame:TransformFrame = new TransformFrame();
			parseFrame(frameXML, transformFrame);
			
			transformFrame.visible = Boolean(frameXML.@[ConstValues.A_VISIBLE] != "0");
			transformFrame.tweenEasing = Number(frameXML.@[ConstValues.A_TWEEN_EASING]);
			transformFrame.tweenRotate = Number(frameXML.@[ConstValues.A_TWEEN_ROTATE]);
			transformFrame.displayIndex = Number(frameXML.@[ConstValues.A_DISPLAY_INDEX]);
			transformFrame.zOrder = Number(frameXML.@[ConstValues.A_Z]);
			//boneFrame.color
			
			transformFrame.global = new DBTransform();
			
			transformFrame.global.x = 
				transformFrame.transform.x = Number(frameXML.@[ConstValues.A_X]);
			
			transformFrame.global.y = 
				transformFrame.transform.y =  Number(frameXML.@[ConstValues.A_Y]);
			
			transformFrame.global.skewX = 
				transformFrame.transform.skewX = Number(frameXML.@[ConstValues.A_SKEW_X]) * ANGLE_TO_RADIAN;
			
			transformFrame.global.skewY = 
				transformFrame.transform.skewY = Number(frameXML.@[ConstValues.A_SKEW_Y]) * ANGLE_TO_RADIAN;
			
			transformFrame.global.scaleX = 
				transformFrame.transform.scaleX = Number(frameXML.@[ConstValues.A_SCALE_X]);
			
			transformFrame.global.scaleY = 
				transformFrame.transform.scaleY = Number(frameXML.@[ConstValues.A_SCALE_Y]);
			
			transformFrame.pivot.x = Number(frameXML.@[ConstValues.A_PIVOT_X]);
			transformFrame.pivot.y = Number(frameXML.@[ConstValues.A_PIVOT_Y]);
			
			return transformFrame;
		}
	}
}