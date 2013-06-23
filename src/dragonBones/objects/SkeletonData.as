package dragonBones.objects 
{
	final public class SkeletonData
	{
		public var name:String;
		
		public var frameRate:uint;
		
		public function get armatureNames():Vector.<String>
		{
			var nameList:Vector.<String> = new Vector.<String>;
			for each(var armatureData:ArmatureData in _armatureDataList)
			{
				nameList[nameList.length] = armatureData.name;
			}
			return nameList;
		}
		
		private var _armatureDataList:Vector.<ArmatureData>;
		public function get armatureDataList():Vector.<ArmatureData>
		{
			return _armatureDataList;
		}
		
		public function SkeletonData()
		{
			_armatureDataList = new Vector.<ArmatureData>(0, true);
		}
		
		public function dispose():void
		{
			for each(var armatureData:ArmatureData in _armatureDataList)
			{
				armatureData.dispose();
			}
			_armatureDataList.fixed = false;
			_armatureDataList.length = 0;
			//_armatureDataList = null;
		}
		
		public function getArmatureData(armatureName:String):ArmatureData
		{
			var i:int = _armatureDataList.length;
			while(i --)
			{
				if(_armatureDataList[i].name == armatureName)
				{
					return _armatureDataList[i];
				}
			}
			
			return null;
		}
		
		public function addArmatureData(armatureData:ArmatureData):void
		{
			if(!armatureData)
			{
				throw new ArgumentError();
			}
			
			if(_armatureDataList.indexOf(armatureData) < 0)
			{
				_armatureDataList.fixed = false;
				_armatureDataList[_armatureDataList.length] = armatureData;
				_armatureDataList.fixed = true;
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		public function removeArmatureData(armatureData:ArmatureData):void
		{
			var index:int = _armatureDataList.indexOf(armatureData);
			if(index >= 0)
			{
				_armatureDataList.fixed = false;
				_armatureDataList.splice(index, 1);
				_armatureDataList.fixed = true;
			}
		}
		
		public function removeArmatureDataByName(armatureName:String):void
		{
			var i:int = _armatureDataList.length;
			while(i --)
			{
				if(_armatureDataList[i].name == armatureName)
				{
					_armatureDataList.fixed = false;
					_armatureDataList.splice(i, 1);
					_armatureDataList.fixed = true;
				}
			}
		}
	}
}