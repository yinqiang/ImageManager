package core.managers
{
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
}