package dragonBones.factorys
{
	
	/**
	* Copyright 2012-2013. DragonBones. All Rights Reserved.
	* @playerversion Flash 10.0, Flash 10
	* @langversion 3.0
	* @version 2.0
	*/
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.display.NativeDisplayBridge;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DecompressedData;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.SkinData;
	import dragonBones.objects.SlotData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.textures.ITextureAtlas;
	import dragonBones.textures.NativeTextureAtlas;
	import dragonBones.utils.BytesType;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	use namespace dragonBones_internal;
	
	/** Dispatched after a sucessful call to parseData(). */
	[Event(name="complete", type="flash.events.Event")]
	
	/**
	 * A BaseFactory instance manages the set of armature resources for the tranditional Flash DisplayList. It parses the raw data (ByteArray), stores the armature resources and creates armature instances.
	 * <p>Create an instance of the BaseFactory class that way:</p>
	 * <listing>
	 * import flash.events.Event; 
	 * import dragonBones.factorys.BaseFactory;
	 * 
	 * [Embed(source = "../assets/Dragon1.swf", mimeType = "application/octet-stream")]  
	 *	private static const ResourcesData:Class;
	 * var factory:BaseFactory = new BaseFactory(); 
	 * factory.addEventListener(Event.COMPLETE, textureCompleteHandler);
	 * factory.parseData(new ResourcesData());
	 * </listing>
	 * @see dragonBones.Armature
	 */
	public class BaseFactory extends EventDispatcher
	{
		private static var _loaderContext:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
		/** @private */
		protected static var _helpMatirx:Matrix = new Matrix();
		/** @private */
		protected var _skeletonDataDic:Object;
		/** @private */
		protected var _textureAtlasDic:Object;
		/** @private */
		protected var _textureAtlasLoadingDic:Object;	
		/** @private */
		protected var _currentSkeletonName:String;
		/** @private */
		protected var _currentTextureAtlasName:String;
		
		/**
		 * Create a Basefactory instance.
		 * 
		 * @example 
		 * <listing>		
		 * import dragonBones.factorys.BaseFactory;
		 * var factory:BaseFactory = new BaseFactory(); 
		 * </listing>
		 */
		public function BaseFactory()
		{
			super();
			_skeletonDataDic = {};
			_textureAtlasDic = {};
			_textureAtlasLoadingDic = {};			
			_loaderContext.allowCodeImport = true;
		}
		
		/**
		 * Parses the raw data and returns a SkeletonData instance.	
		 * @example 
		 * <listing>
		 * import flash.events.Event; 
		 * import dragonBones.factorys.BaseFactory;
		 * 
		 * [Embed(source = "../assets/Dragon1.swf", mimeType = "application/octet-stream")]  
		 *	private static const ResourcesData:Class;
		 * var factory:BaseFactory = new BaseFactory(); 
		 * factory.addEventListener(Event.COMPLETE, textureCompleteHandler);
		 * factory.parseData(new ResourcesData());
		 * </listing>
		 * @param	ByteArray. Represents the raw data for the whole skeleton system.
		 * @param	String. (optional) The SkeletonData instance name.
		 * @return A SkeletonData instance.
		 */
		public function parseData(bytes:ByteArray, skeletonName:String = null):SkeletonData
		{
			if(!bytes)
			{
				throw new ArgumentError();
			}
			var decompressedData:DecompressedData = XMLDataParser.decompressData(bytes);
			var skeletonData:SkeletonData = XMLDataParser.parseSkeletonData(decompressedData.skeletonXML);
			skeletonName = skeletonName || skeletonData.name;
			addSkeletonData(skeletonData, skeletonName);
			var loader:Loader = new Loader();
			loader.name = skeletonName;
			_textureAtlasLoadingDic[skeletonName] = decompressedData.textureAtlasXML;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderCompleteHandler);
			loader.loadBytes(decompressedData.textureBytes, _loaderContext);
			decompressedData.dispose();
			return skeletonData;
		}
		
		/**
		 * Returns a SkeletonData instance.
		 * @example 
		 * <listing>
		 * var skeleton:SkeletonData = factory.getSkeletonData('dragon');
		 * </listing>
		 * @param	The name of an existing SkeletonData instance.
		 * @return A SkeletonData instance with given name (if exist).
		 */
		public function getSkeletonData(name:String):SkeletonData
		{
			return _skeletonDataDic[name];
		}
		
		/**
		 * Add a SkeletonData instance to this BaseFactory instance.
		 * @example 
		 * <listing>
		 * factory.addSkeletonData(skeletondata, 'dragon');
		 * </listing>
		 * @param	A skeletonData instance.
		 * @param	(optional) A name for this SkeletonData instance.
		 */
		public function addSkeletonData(skeletonData:SkeletonData, name:String = null):void
		{
			if(!skeletonData)
			{
				throw new ArgumentError();
			}
			name = name || skeletonData.name;
			if(!name)
			{
				throw new ArgumentError("Unnamed data!");
			}
			if(_skeletonDataDic[name])
			{
				throw new ArgumentError();
			}
			_skeletonDataDic[name] = skeletonData;
		}
		
		/**
		 * Remove a SkeletonData instance from this BaseFactory instance.
		 * @example 
		 * <listing>
		 * factory.removeSkeletonData('dragon');
		 * </listing>
		 * @param	The name for the SkeletonData instance to remove.
		 */
		public function removeSkeletonData(name:String):void
		{
			delete _skeletonDataDic[name];
		}
		
		/**
		 * Return the TextureAtlas by that name.
		 * @example 
		 * <listing>
		 * var atlas:Object = factory.getTextureAtlas('dragon');
		 * </listing>
		 * @param	The name of the TextureAtlas to return.
		 * @return A textureAtlas.
		 */
		public function getTextureAtlas(name:String):Object
		{
			return _textureAtlasDic[name];
		}
		
		/**
		 * Add a textureAtlas to this BaseFactory instance.
		 * @example 
		 * <listing>
		 * factory.addTextureAtlas(textureatlas, 'dragon');
		 * </listing>
		 * @param	A textureAtlas to add to this BaseFactory instance.
		 * @param	(optional) A name for this TextureAtlas.
		 */
		public function addTextureAtlas(textureAtlas:Object, name:String = null):void
		{
			if(!textureAtlas)
			{
				throw new ArgumentError();
			}
			if(!name && textureAtlas is ITextureAtlas)
			{
				name = textureAtlas.name;
			}
			if(!name)
			{
				throw new ArgumentError("Unnamed data!");
			}
			if(_textureAtlasDic[name])
			{
				throw new ArgumentError();
			}
			_textureAtlasDic[name] = textureAtlas;
		}
		
		/**
		 * Remove a textureAtlas from this baseFactory instance.
		 * @example 
		 * <listing>
		 * factory.removeTextureAtlas('dragon');
		 * </listing>
		 * @param	The name of the TextureAtlas to remove.
		 */
		public function removeTextureAtlas(name:String):void
		{
			delete _textureAtlasDic[name];
		}
		
		 /**
		  * Cleans up resources used by this BaseFactory instance.
		 * @example 
		 * <listing>
		 * factory.dispose();
		 * </listing>
		  * @param	(optional) Destroy all internal references.
		  */
		public function dispose(disposeData:Boolean = true):void
		{
			if(disposeData)
			{
				for each(var skeletonData:SkeletonData in _skeletonDataDic)
				{
					skeletonData.dispose();
				}
				for each(var textureAtlas:Object in _textureAtlasDic)
				{
					textureAtlas.dispose();
				}
			}
			_skeletonDataDic = null
			_textureAtlasDic = null;
			_textureAtlasLoadingDic = null;		
			_currentSkeletonName = null;
			_currentTextureAtlasName = null;
		}
		
		 /**
		  * Build and returns a new Armature instance.
		 * @example 
		 * <listing>
		 * var armature:Armature = factory.buildArmature('dragon');
		 * </listing>
		  * @param	The name of this Armature instance.
		  * @param	The name of this animation.
		  * @param	The name of this skin.
		  * @param	The name of this skeleton.
		  * @param	The name of this textureAtlas.
		  * @return A Armature instance.
		  */
		public function buildArmature(armatureName:String, animationName:String = null, skinName:String = null, skeletonName:String = null, textureAtlasName:String = null):Armature
		{
			if(skeletonName)
			{
				var skeletonData:SkeletonData = _skeletonDataDic[skeletonName];
				if(skeletonData)
				{
					var armatureData:ArmatureData = skeletonData.getArmatureData(armatureName);
				}
			}
			else
			{
				for (skeletonName in _skeletonDataDic)
				{
					skeletonData = _skeletonDataDic[skeletonName];
					armatureData = skeletonData.getArmatureData(armatureName);
					if(armatureData)
					{
						break;
					}
				}
			}
			
			if(!armatureData)
			{
				return null;
			}
			
			_currentSkeletonName = skeletonName;
			_currentTextureAtlasName = textureAtlasName || skeletonName;
			
			var armature:Armature = generateArmature();
			armature.name = armatureName;
			for each(var boneData:BoneData in armatureData.boneDataList)
			{
				var bone:Bone = new Bone();
				bone.name = boneData.name;
				bone.origin.copy(boneData.transform);
				armature.addBone(bone, boneData.parent);
			}
			
			if(animationName && animationName != armatureName)
			{
				var animationArmatureData:ArmatureData = skeletonData.getArmatureData(animationName);
				if(!animationArmatureData)
				{
					for (skeletonName in _skeletonDataDic)
					{
						skeletonData = _skeletonDataDic[skeletonName];
						animationArmatureData = skeletonData.getArmatureData(animationName);
						if(animationArmatureData)
						{
							break;
						}
					}
				}
			}
			
			if(animationArmatureData)
			{
				armature.animation.animationDataList = animationArmatureData.animationDataList;
			}
			else
			{
				armature.animation.animationDataList = armatureData.animationDataList;
			}
			
			var skinData:SkinData = armatureData.getSkinData(skinName);
			for each(var slotData:SlotData in skinData.slotDataList)
			{
				bone = armature.getBone(slotData.parent);
				if(!boneData)
				{
					continue;
				}
				var slot:Slot = generateSlot();
				slot.name = slotData.name;
				slot._originZOrder = slotData.zOrder;
				slot._dislayDataList = slotData.displayDataList;
				
				var i:int = slotData.displayDataList.length;
				while(i --)
				{
					var displayData:DisplayData = slotData.displayDataList[i];
					slot.changeDisplay(i);
					switch(displayData.type)
					{
						case DisplayData.ARMATURE:
							var childArmature:Armature = buildArmature(displayData.name, null, null, _currentSkeletonName, _currentTextureAtlasName);
							if(childArmature)
							{
								childArmature.animation.play();
								slot.childArmature = childArmature;
							}
							break;
						case DisplayData.IMAGE:
						default:
							slot.display = generateTextureDisplay(_textureAtlasDic[_currentTextureAtlasName], displayData.name, displayData.pivot.x, displayData.pivot.y);
							break;
						
					}
				}
				bone.addChild(slot);
			}
			armature._slotsZOrderChanged = true;
			armature.advanceTime(0);
			return armature;
		}
		
		/**
		 * Return the TextureDisplay.
		 * @example 
		 * <listing>
		 * var texturedisplay:Object = factory.getTextureDisplay('dragon');
		 * </listing>
		 * @param	The name of this Texture.
		 * @param	The name of the TextureAtlas.
		 * @param	The registration pivotX position.
		 * @param	The registration pivotY position.
		 * @return An Object.
		 */
		public function getTextureDisplay(textureName:String, textureAtlasName:String = null, pivotX:Number = NaN, pivotY:Number = NaN):Object
		{
			if(textureAtlasName)
			{
				var textureAtlas:Object = _textureAtlasDic[textureAtlasName];
			}
			if(!textureAtlas && !textureAtlasName)
			{
				for (textureAtlasName in _textureAtlasDic)
				{
					textureAtlas = _textureAtlasDic[textureAtlasName];
					if(textureAtlas.getRegion(textureName))
					{
						break;
					}
					textureAtlas = null;
				}
			}
			if(textureAtlas)
			{
				if(isNaN(pivotX) || isNaN(pivotY))
				{
					var skeletonData:SkeletonData = _skeletonDataDic[textureAtlasName];
					if(skeletonData)
					{
						var pivot:Point = skeletonData.getSubTexturePivot(textureName);
						if(pivot)
						{
							pivotX = pivotX || pivot.x;
							pivotY = pivotY || pivot.y;
						}
					}
				}
				
				return generateTextureDisplay(textureAtlas, textureName, pivotX, pivotY);
			}
			return null;
		}
		
		/** @private */
		protected function loaderCompleteHandler(e:Event):void
		{
			e.target.removeEventListener(Event.COMPLETE, loaderCompleteHandler);
			var loader:Loader = e.target.loader;
			var content:Object = e.target.content;
			loader.unloadAndStop();
			
			var skeletonName:String = loader.name;
			var textureAtlasXML:XML = _textureAtlasLoadingDic[skeletonName];
			delete _textureAtlasLoadingDic[skeletonName];
			if(skeletonName && textureAtlasXML)
			{
				if (content is Bitmap)
				{
					content =  (content as Bitmap).bitmapData;
				}
				else if (content is Sprite)
				{
					content = (content as Sprite).getChildAt(0) as MovieClip;
				}
				else
				{
					//
				}
				
				var textureAtlas:Object = generateTextureAtlas(content, textureAtlasXML);
				addTextureAtlas(textureAtlas, skeletonName);
				
				skeletonName = null;
				for(skeletonName in _textureAtlasLoadingDic)
				{
					break;
				}
				//
				if(!skeletonName && hasEventListener(Event.COMPLETE))
				{
					dispatchEvent(new Event(Event.COMPLETE));
				}
			}
		}
		
		/** @private */
		protected function generateTextureAtlas(content:Object, textureAtlasXML:XML):Object
		{
			var textureAtlas:NativeTextureAtlas = new NativeTextureAtlas(content, textureAtlasXML);
			return textureAtlas;
		}
		
		/** @private */
		protected function generateArmature():Armature
		{
			var display:Sprite = new Sprite();
			var armature:Armature = new Armature(display);
			return armature;
		}
		
		/** @private */
		protected function generateSlot():Slot
		{
			var slot:Slot = new Slot(new NativeDisplayBridge());
			return slot;
		}
		
		/** @private */
		protected function generateTextureDisplay(textureAtlas:Object, fullName:String, pivotX:Number, pivotY:Number):Object
		{
			var nativeTextureAtlas:NativeTextureAtlas = textureAtlas as NativeTextureAtlas;
			if(nativeTextureAtlas){
				var movieClip:MovieClip = nativeTextureAtlas.movieClip;
				if (movieClip && movieClip.totalFrames >= 3)
				{
					movieClip.gotoAndStop(movieClip.totalFrames);
					movieClip.gotoAndStop(fullName);
					if (movieClip.numChildren > 0)
					{
						try
						{
							var displaySWF:Object = movieClip.getChildAt(0);
							displaySWF.x = 0;
							displaySWF.y = 0;
							return displaySWF;
						}
						catch(e:Error)
						{
							throw new Error("Can not get the movie clip, please make sure the version of the resource compatible with app version!");
						}
					}
				}
				else if(nativeTextureAtlas.bitmapData)
				{
					var subTextureData:Rectangle = nativeTextureAtlas.getRegion(fullName);
					if (subTextureData)
					{
						var displayShape:Shape = new Shape();
						
						_helpMatirx.a = 1;
						_helpMatirx.b = 0;
						_helpMatirx.c = 0;
						_helpMatirx.d = 1;
						_helpMatirx.scale(nativeTextureAtlas.scale, nativeTextureAtlas.scale);
						_helpMatirx.tx += subTextureData.x + pivotX;
						_helpMatirx.ty += subTextureData.y + pivotY;
						
						displayShape.graphics.beginBitmapFill(nativeTextureAtlas.bitmapData, _helpMatirx, false, true);
						displayShape.graphics.drawRect(pivotX, pivotY, subTextureData.width, subTextureData.height);
						return displayShape;
					}
				}
				else
				{
					throw new Error();
				}
			}
			return null;
		}
	}
}