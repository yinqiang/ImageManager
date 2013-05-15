package core.managers 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	/**
	 * 图片管理器
	 * @author YQ
	 */
	public class ImageManager 
	{
		static protected var instance:ImageManager;
		
		/**
		 * url和尺寸之间的分隔符
		 */
		static protected const TOKEN_URL:String = "^";
		/**
		 * width和height之间的分隔符
		 */
		static protected const TOKEN_SIZE:String = ",";
		
		/**
		 * 已知尺寸类型
		 */
		static protected const TYPE_GET:String = "getImage";
		/**
		 * 请求类型
		 */
		static protected const TYPE_REQ:String = "reqImage";
		
		/**
		 * 原尺寸BitmapData
		 */
		protected var cacheOriginal:Dictionary;
		/**
		 * 不同尺寸BitmapData克隆
		 */
		protected var cacheDiffSize:Dictionary;
		/**
		 * 正在下载的图片，key:Loader
		 */
		protected var urls:Dictionary;
		/**
		 * 图片请求队列
		 */
		protected var queueReqs:Dictionary;
		
		/**
		 * 各个url占用的内存数量
		 */
		protected var imageMemoryList:Array;
		/**
		 * 内存总占用量
		 */
		protected var imageMemory:Number;
		
		public function ImageManager() 
		{
			if (instance == null) {
				cacheOriginal = new Dictionary();
				cacheDiffSize = new Dictionary();
				urls = new Dictionary();
				queueReqs = new Dictionary();
				imageMemoryList = [];
				imageMemory = 0;
			}
		}
		
		/**
		 * 获取图片管理器单例
		 * @return 
		 * 
		 */
		static public function getInstance():ImageManager {
			if (instance == null) {
				instance = new ImageManager();
			}
			return instance;
		}
		
		/**
		 * 获取已知大小的图片
		 * @param url       地址
		 * @param width     宽度
		 * @param height    高度
		 * @param smoothing 否对位图进行平滑处理
		 * @return 
		 * 
		 */
		public function getImage(url:String, width:Number, height:Number, smoothing:Boolean=true):Bitmap {
			const keySize:String = url + TOKEN_URL + width + TOKEN_SIZE + height;
			var bmpData:BitmapData;
			var bmp:Bitmap;
			if (cacheDiffSize.hasOwnProperty(keySize)) { // 如果有这个尺寸的缓存
				bmpData = cacheDiffSize[keySize] as BitmapData;
				bmp = new Bitmap(bmpData);
				bmp.smoothing = smoothing;
				return bmp;
			} else if (cacheOriginal.hasOwnProperty(url)) { // 如果有原尺寸的缓存，则从原尺寸图片拷贝一份
				bmpData = cacheOriginal[url] as BitmapData;
				bmpData.lock();
				var cloneData:BitmapData;
				if (bmpData.width == width && bmpData.height == height) { // 若尺寸和原图一致则使用原图数据
					cloneData = bmpData;
				} else {
					cloneData = new BitmapData(width, height, true, 0);
					var matx:Matrix = new Matrix();
					matx.scale(width / bmpData.width, height / bmpData.height);
					cloneData.draw(bmpData, matx);
				}
				bmpData.unlock();
				cacheDiffSize[keySize] = cloneData;
				bmp = new Bitmap(bmpData);
				bmp.smoothing = smoothing;
				return bmp;
			}
			// 请求的图片没有缓存过，则下载此图片
			bmpData = new BitmapData(width, height, true, 0); // 构造出空图片以便下载后填充
			cacheDiffSize[keySize] = bmpData; // 放入缓存
			bmp = new Bitmap(bmpData);
			bmp.smoothing = smoothing;
			var loader:Loader;
			var size:Object = {
				width: width,
				height: height
			}
			if (! queueReqs.hasOwnProperty(url)) {
				queueReqs[url] = new Dictionary();
				loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				urls[loader] = url;
			}
			if (queueReqs[url].hasOwnProperty(TYPE_GET)) {
				queueReqs[url][TYPE_GET].push(size);
			} else {
				queueReqs[url][TYPE_GET] = new Vector.<Object>();
				queueReqs[url][TYPE_GET].push(size);
				if (loader) {
					loader.load(new URLRequest(url));
				}
			}
			return bmp;
		}
		
		/**
		 * 未知图片大小时请求图片
		 * @param url      地址
		 * @param callback 回调函数，function(bmpData:BitmapData, parms:Object)
		 * @param parms    回调定义参数
		 * 
		 */
		public function requstImage(url:String, callback:Function, parms:Object=null):void {
			if (cacheOriginal.hasOwnProperty(url)) {
				callback(cacheOriginal[url], parms);
			} else {
				var loader:Loader;
				var req:Object = {
					callback: callback,
					parms: parms
				};
				if (! queueReqs.hasOwnProperty(url)) { // 若没有相同地址的请求
					queueReqs[url] = new Dictionary();
					loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
					urls[loader] = url;
				}
				if (queueReqs[url].hasOwnProperty(TYPE_REQ)) { // 若已经有同类型的求
					queueReqs[url][TYPE_REQ].push(req); // 加入队列
				} else {
					queueReqs[url][TYPE_REQ] = new Vector.<Object>(); // 建立队列
					queueReqs[url][TYPE_REQ].push(req);
					if (loader) {
						loader.load(new URLRequest(url));
					}
				}
			}
		}
		
		protected function onLoadComplete(e:Event):void {
			var loader:Loader = (e.currentTarget as LoaderInfo).loader;
			
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadComplete);
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			
			var bmpOriginalData:BitmapData = (loader.content as Bitmap).bitmapData;
			var url:String = urls[loader];
			
			if (queueReqs[url].hasOwnProperty(TYPE_GET)) {
				for each (var size:Object in queueReqs[url][TYPE_GET]) {
					var keySize:String = url + TOKEN_URL + size.width + TOKEN_SIZE + size.height;
					var bmpDiffSizeData:BitmapData = cacheDiffSize[keySize]; // 当前这个BitmapData必然是没有图像的
					var matx:Matrix = new Matrix();
					matx.scale(size.width / bmpOriginalData.width, size.height / bmpOriginalData.height);
					bmpDiffSizeData.lock();
					bmpDiffSizeData.draw(bmpOriginalData, matx, null, null, null, true);
					bmpDiffSizeData.unlock();
					if (! cacheOriginal.hasOwnProperty(url)) { // 若没有缓存原图
						if (size.width == bmpOriginalData.width
							&& size.height == bmpOriginalData.height)
						{ // 若请求的尺寸和原图一样
							cacheOriginal[url] = cacheDiffSize[keySize]; // 指向cacheDiffSize的数据
							bmpOriginalData.dispose();
						} else {
							cacheOriginal[url] = bmpOriginalData; // 缓存原尺寸图片
						}
					}
				}
				delete queueReqs[url][TYPE_GET];
			}
			if (queueReqs[url].hasOwnProperty(TYPE_REQ)) {
				if (cacheOriginal.hasOwnProperty(url) && cacheOriginal[url] != bmpOriginalData) { // 原图只需要一个
					bmpOriginalData.dispose();
				} else {
					cacheOriginal[url] = bmpOriginalData;
				}
				for each (var req:Object in queueReqs[url][TYPE_REQ]) {
					req.callback(cacheOriginal[url], req.parms); // 回调
				}
				delete queueReqs[url][TYPE_REQ];
			}
			
			imageMemoryList.push({ url: url, bytes: loader.loaderInfo.bytesLoaded });
			imageMemory += loader.loaderInfo.bytesLoaded;
			
			delete queueReqs[url];
			delete urls[loader];
			loader.unload();
		}
		
		protected function onIOError(e:IOErrorEvent):void {
			var loader:Loader = (e.currentTarget as LoaderInfo).loader;
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadComplete);
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			trace("[ERROR] image not found: " + urls[loader]);
			delete urls[loader];
		}
		
		protected function onSecurityError(e:SecurityErrorEvent):void {
			var loader:Loader = (e.currentTarget as LoaderInfo).loader;
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadComplete);
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			trace("[SECURITY ERROR] image can not open: " + urls[loader]);
			delete urls[loader];
		}
		
		/**
		 * 获得图片的内存总占用量
		 * @return 
		 * 
		 */
		public function getImageMemTotal():Number {
			return imageMemory;
		}
		
		/**
		 * 获得各个url占用的内存量
		 * @return 
		 * 
		 */
		public function getImageMemList():Array {
			imageMemoryList.sortOn('bytes', Array.NUMERIC | Array.DESCENDING);
			return imageMemoryList;
		}
	}
}
