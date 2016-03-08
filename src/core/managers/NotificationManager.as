package core.managers
{
	import core.Consts;
	
	import flash.utils.Dictionary;

	/**
	 * 消息管理器
	 * @author YQ
	 * 
	 */
	public class NotificationManager
	{
		static protected var instance:NotificationManager;
		
		static public const FILTER_TOKEN:String = ";"
		
		private var types:Dictionary;
		
		public function NotificationManager()
		{
			if (instance == null) {
				types = new Dictionary();
			}
		}
		
		static public function getInstance():NotificationManager {
			if (instance == null) {
				instance = new NotificationManager();
			}
			return instance;
		}
		
		public function hasListener(type:String):Boolean {
			if (type == null || type == Consts.NULL_STR) return false;
			return (types.hasOwnProperty(type));
		}
		
		/**
		 * 添加消息接收函数
		 * @param type
		 * @param listener <code>function(type:String, data:Object)</code>
		 * @return 
		 * 
		 */
		public function addListener(type:String, listener:Function):Boolean {
			if (type == null || type == Consts.NULL_STR || listener == null) return false;
			var group:NotificationGroup = types[type];
			if (group == null) {
				group = new NotificationGroup();
				types[type] = group;
			}
			return group.add(listener);
		}
		
		public function removeListener(type:String, listener:Function):Boolean {
			if (type == null || type == Consts.NULL_STR || listener == null) return false;
			var group:NotificationGroup = types[type];
			if (group == null) return false;
			if (! group.remove(listener)) return false;
			if (group.count() == 0) {
				delete types[type];
			}
			return true;
		}
		
		public function removeAllListener(type:String):Boolean {
			if (type == null || type == Consts.NULL_STR) return false;
			var group:NotificationGroup = types[type];
			if (group == null) return false;
			group.destory();
			delete types[type];
			return true;
		}
		
		public function dispatch(type:String, data:Object=null):void {
			if (type == null || type == Consts.NULL_STR) return;
			var group:NotificationGroup = types[type];
			if (group == null) return;
			group.call(type, data);
		}
		
		public function dump(filter:String=null):String {
			const type_filter:Array = (filter ? filter.split(FILTER_TOKEN) : null);
			var ret:String = "## Notification dump:(\n";
			var group:NotificationGroup;
			if (type_filter) {
				for (var i:int=0; i<type_filter.length; i++) {
					group = types[type_filter[i]];
					if (group) {
						ret += "type:" + type_ + ", listeners:" + group.count() + "\n";
					} else {
						ret += "type:" + type_filter[i] + " !Undefined!\n";
					}
				}
			} else {
				for (var type_:String in types) {
					group = types[type_];
					ret += "type:" + type_ + ", listeners:" + group.count() + "\n";
				}
			}
			return ret + ")";
		}
	}
}

internal class NotificationGroup
{
	private var listeners:Vector.<Function>;
	
	public function NotificationGroup()
	{
		listeners = new Vector.<Function>();
	}
	
	public function call(type:String, data:Object=null):void {
		for each (var func:Function in listeners) {
			if (func != null) {
				func(type, data);
			}
		}
	}
	
	public function has(listener:Function):Boolean {
		return (listener != null && listeners.indexOf(listener) >= 0);
	}
	
	public function add(listener:Function):Boolean {
		if (listener == null) return false;
		if (! has(listener)) {
			listeners.push(listener);
		}
		return true;
	}
	
	public function remove(listener:Function):Boolean {
		if (listener == null) return false;
		const i:int = listeners.indexOf(listener);
		if (i == -1) return false;
		listeners.splice(i, 1);
		return true;
	}
	
	public function count():int {
		return listeners.length;
	}
	
	public function clean():void {
		listeners.splice(0, listeners.length);
	}
	
	public function destory():void {
		clean();
		listeners = null;
	}
}