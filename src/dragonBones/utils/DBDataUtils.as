package dragonBones.utils
{
	import dragonBones.animation.TimelineState;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.Frame;
	import dragonBones.objects.SkinData;
	import dragonBones.objects.SlotData;
	import dragonBones.objects.TransformFrame;
	import dragonBones.objects.TransformTimeline;
	import dragonBones.utils.ConstValues;
	
	import flash.geom.Point;
	
	/** @private */
	public final class DBDataUtils
	{
		private static var _helpTransform1:DBTransform = new DBTransform();
		private static var _helpTransform2:DBTransform = new DBTransform();
		
		public static function transformArmatureData(armatureData:ArmatureData):void
		{
			var i:int = armatureData.boneDataList.length;
			while(i --)
			{
				var boneData:BoneData = armatureData.boneDataList[i];
				if(boneData.parent)
				{
					var parentBoneData:BoneData = armatureData.getBoneData(boneData.parent);
					if(parentBoneData)
					{
						boneData.transform.copy(boneData.global);
						TransformUtils.transformPointWithParent(boneData.transform, parentBoneData.global);
					}
				}
			}
		}
		
		public static function transformAnimationData(armatureData:ArmatureData):void
		{
			var skinData:SkinData = armatureData.getSkinData(null);
			var i:int = armatureData.boneDataList.length;
			while(i --)
			{
				var boneData:BoneData = armatureData.boneDataList[i];
				var j:int = armatureData.animationDataList.length;
				while(j --)
				{
					var animationData:AnimationData = armatureData.animationDataList[j];
					
					var timeline:TransformTimeline = animationData.getTimeline(boneData.name);
					if(!timeline)
					{
						continue;
					}
					
					var slotData:SlotData = skinData.getSlotData(boneData.name);
					
					if(boneData.parent)
					{
						var parentTimeline:TransformTimeline = animationData.getTimeline(boneData.parent);
					}
					else
					{
						parentTimeline = null;
					}
					
					var frameList:Vector.<Frame> = timeline.frameList;
					
					var originTransform:DBTransform = null;
					var originPivot:Point = null;
					var length:uint = frameList.length;
					for(var k:int = 0;k < length;k ++)
					{
						var frame:TransformFrame = frameList[k] as TransformFrame;
						if(parentTimeline)
						{
							//tweenValues to transform.
							_helpTransform1.copy(frame.global);
							
							//get transform from parent timeline.
							getTimelineTransform(parentTimeline, frame.position, _helpTransform2);
							TransformUtils.transformPointWithParent(_helpTransform1, _helpTransform2);
							
							//transform to tweenValues.
							frame.transform.copy(_helpTransform1);
						}
						
						frame.transform.x -= boneData.transform.x;
						frame.transform.y -= boneData.transform.y;
						frame.transform.skewX -= boneData.transform.skewX;
						frame.transform.skewY -= boneData.transform.skewY;
						frame.transform.scaleX -= boneData.transform.scaleX;
						frame.transform.scaleY -= boneData.transform.scaleY;
						frame.pivot.x -= boneData.pivot.x;
						frame.pivot.y -= boneData.pivot.y;
						
						if(!originTransform)
						{
							originTransform = timeline.originTransform;
							originTransform.copy(frame.transform);
							originTransform.skewX = TransformUtils.formatRadian(originTransform.skewX);
							originTransform.skewY = TransformUtils.formatRadian(originTransform.skewY);
							originPivot = timeline.originPivot;
							originPivot.x = frame.pivot.x;
							originPivot.y = frame.pivot.y;
						}
						
						frame.transform.x -= originTransform.x;
						frame.transform.y -= originTransform.y;
						frame.transform.skewX = TransformUtils.formatRadian(frame.transform.skewX - originTransform.skewX);
						frame.transform.skewY = TransformUtils.formatRadian(frame.transform.skewY - originTransform.skewY);
						frame.transform.scaleX -= originTransform.scaleX;
						frame.transform.scaleY -= originTransform.scaleY;
						frame.pivot.x -= originPivot.x;
						frame.pivot.y -= originPivot.y;
						
						frame.zOrder -= slotData.zOrder;
					}
				}
			}
		}
		
		public static function getTimelineTransform(timeline:TransformTimeline, position:Number, retult:DBTransform):void
		{
			var frameList:Vector.<Frame> = timeline.frameList;
			var i:int = frameList.length;
			while(i --)
			{
				var currentFrame:TransformFrame = frameList[i] as TransformFrame;
				if(currentFrame.position <= position && currentFrame.position + currentFrame.duration > position)
				{
					var tweenEasing:Number = currentFrame.tweenEasing;
					var index:Number = frameList.indexOf(currentFrame);
					if(index == frameList.length - 1 || isNaN(tweenEasing) || position == currentFrame.position)
					{
						retult.copy(currentFrame.global);
					}
					else
					{
						var progress:Number = (position - currentFrame.position) / currentFrame.duration;
						progress = TimelineState.getEaseValue(progress, tweenEasing);
						
						var nextFrame:TransformFrame = timeline.frameList[index + 1] as TransformFrame;
						
						retult.x = currentFrame.global.x +  (nextFrame.global.x - currentFrame.global.x) * progress;
						retult.y = currentFrame.global.y +  (nextFrame.global.y - currentFrame.global.y) * progress;
						retult.skewX = currentFrame.global.skewX +  (nextFrame.global.skewX - currentFrame.global.skewX) * progress;
						retult.skewY = currentFrame.global.skewY +  (nextFrame.global.skewY - currentFrame.global.skewY) * progress;
						retult.scaleX = currentFrame.global.scaleX +  (nextFrame.global.scaleX - currentFrame.global.scaleX) * progress;
						retult.scaleY = currentFrame.global.scaleY +  (nextFrame.global.scaleY - currentFrame.global.scaleY) * progress;
					}
					break;
				}
			}
		}
		
		public static function addHideTimeline(animationData:AnimationData, armatureData:ArmatureData):void
		{
			var boneDataList:Vector.<BoneData> =armatureData.boneDataList;
			var i:int = boneDataList.length;
			while(i --)
			{
				var boneData:BoneData = boneDataList[i];
				var boneName:String = boneData.name;
				if(!animationData.getTimeline(boneName))
				{
					animationData.addTimeline(TransformTimeline.HIDE_TIMELINE, boneName);
				}
			}
		}
	}
}