package dragonBones.utils
{
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.Frame;
	import dragonBones.objects.TransformFrame;
	import dragonBones.objects.TransformTimeline;
	import dragonBones.utils.ConstValues;
	
	import flash.geom.Point;
	
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
						TransformUtils.transformPointWithParent(boneData.transform, parentBoneData.global);
					}
				}
			}
		}
		
		public static function transformAnimationData(animationData:AnimationData, armatureData:ArmatureData):void
		{
			var i:int = armatureData.boneDataList.length;
			
			while(i --)
			{
				var boneData:BoneData = armatureData.boneDataList[i];
				var boneTimeline:TransformTimeline = animationData.getTimeline(boneData.name);
				if(!boneTimeline)
				{
					continue;
				}
				
				if(boneData.parent)
				{
					var parentTimeline:TransformTimeline = animationData.getTimeline(boneData.parent);
				}
				else
				{
					parentTimeline = null;
				}
				
				var frameList:Vector.<Frame> = boneTimeline.frameList;
				
				var originTransform:DBTransform = null;
				var originPivot:Point = null;
				var length:uint = frameList.length;
				for(var j:int = 0;j < length;j ++)
				{
					var boneFrame:TransformFrame = frameList[j] as TransformFrame;
					if(parentTimeline)
					{
						//tweenValues to transform.
						_helpTransform1.copy(boneFrame.global);
						
						//get transform from parent timeline.
						getTimelineTransform(parentTimeline, boneFrame.position, _helpTransform2);
						TransformUtils.transformPointWithParent(_helpTransform1, _helpTransform2);
						
						//transform to tweenValues.
						boneFrame.transform.copy(_helpTransform1);
					}
					
					boneFrame.transform.x -= boneData.transform.x;
					boneFrame.transform.y -= boneData.transform.y;
					boneFrame.transform.skewX -= boneData.transform.skewX;
					boneFrame.transform.skewY -= boneData.transform.skewY;
					boneFrame.transform.scaleX -= boneData.transform.scaleX;
					boneFrame.transform.scaleY -= boneData.transform.scaleY;
					
					if(!originTransform)
					{
						originTransform = boneTimeline.originTransform;
						originTransform.copy(boneFrame.transform);
						originTransform.skewX = TransformUtils.formatRadian(originTransform.skewX);
						originTransform.skewY = TransformUtils.formatRadian(originTransform.skewY);
						originPivot = boneTimeline.originPivot;
						originPivot.x = boneFrame.pivot.x;
						originPivot.y = boneFrame.pivot.y;
					}
					
					boneFrame.transform.x -= originTransform.x;
					boneFrame.transform.y -= originTransform.y;
					boneFrame.transform.skewX -= originTransform.skewX;
					boneFrame.transform.skewY -= originTransform.skewY;
					boneFrame.transform.scaleX -= originTransform.scaleX;
					boneFrame.transform.scaleY -= originTransform.scaleY;
					boneFrame.pivot.x -= originPivot.x;
					boneFrame.pivot.y -= originPivot.y;
					
					boneFrame.transform.skewX = TransformUtils.formatRadian(boneFrame.transform.skewX);
					boneFrame.transform.skewY = TransformUtils.formatRadian(boneFrame.transform.skewY);
				}
			}
		}
		
		public static function getTimelineTransform(timeline:TransformTimeline, position:Number, retult:DBTransform):void
		{
			var frameList:Vector.<Frame> = timeline.frameList;
			var i:int = frameList.length;
			while(i --)
			{
				var boneFrame:TransformFrame = frameList[i] as TransformFrame;
				if(boneFrame.position <= position && boneFrame.position + boneFrame.duration > position)
				{
					var progress:Number = (position - boneFrame.position) / boneFrame.duration;
					var index:Number = frameList.indexOf(boneFrame);
					if(index == frameList.length - 1)
					{
						retult.copy(boneFrame.global);
					}
					else
					{
						//var nextFrame:BoneFrame = timeline.frameList[index + 1] as BoneFrame;
						//AnimationState.setOffsetTransform(boneFrame, nextFrame, retult);
						//TransformUtils.setTweenNode(boneFrame.transformGlobal, retult, retult, progress);
						retult.copy(boneFrame.global);
					}
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