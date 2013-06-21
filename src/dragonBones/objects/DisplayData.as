package dragonBones.objects
{
	final public class DisplayData
	{
		public static const ARMATURE:String = "armature";
		public static const IMAGE:String = "image";
		
		public var name:String;
		public var type:String;
		public var transform:DBTransform;
		
		public function DisplayData()
		{
			transform = new DBTransform();
		}
	}
}