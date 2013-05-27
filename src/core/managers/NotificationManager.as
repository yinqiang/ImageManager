package core.managers
{
	import core.Consts;

	/**
	 * 消息管理器
	 * @author YQ
	 * 
	 */
	public class NotificationManager
	{
		static protected var instance:NotificationManager;
		
		static public const FILTER_TOKEN:String = ";"
		
		private var types:Array;
		
		public function NotificationManager()
		{
			if (instance == null) {
				types = [];
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
			return group.remove(listener);
		}
		
		public function removeAllListener(type:String):Boolean {
			if (type == null || type == Consts.NULL_STR) return false;
			var group:NotificationGroup = types[type];
			if (group == null) return false;
			group.destory();
			types[type] = null;
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
			var ret:String = "";
			var group:NotificationGroup;
			if (type_filter) {
				for (var i:int=0; i<type_filter.length; i++) {
					group = types[type_filter[i]];
					if (group) {
						ret += "type:" + type_ + ", count:" + group.count() + "\n";
					} else {
						ret += "type:" + type_ + " NULL\n";
					}
				}
			} else {
				for (var type_:String in types) {
					group = types[type_];
					ret += "type:" + type_ + ", count:" + group.count() + "\n";
				}
			}
			return ret;
		}
	}
}