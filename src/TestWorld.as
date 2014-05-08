package  
{
	import flash.display.BlendMode;
	import flash.geom.Point;
	import flash.system.System;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import net.flashpunk.Entity;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.utils.Draw;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	import net.flashpunk.World;

	
	/**
	 * ...
	 * @author azrafe7
	 */
	public class TestWorld extends World
	{
		
		private var text:Text;
		
		
		private var lastPoint:Point;
		private var newPoly:Vector.<Point> = new Vector.<Point>();
		private var poly:Vector.<Point> = new Vector.<Point>();

		private var close:Boolean = false;
		private var INFO:String = "\n\n\nClick to set points - SPACE to close poly";
		
		public function TestWorld() 
		{
			
		}
		
		override public function begin():void {
			
			text = new Text(INFO, 0, 5);
			var textEntity:Entity = new Entity(100, 300, text);
			text.blend = BlendMode.OVERLAY;
			text.scrollX = 0;
			text.scrollY = 0;
			text.scale = 1;
			text.setTextProperty("multiline", true);
			add(textEntity);
			
			FP.log("Test polygon props...");
			
			Input.mouseCursor = "hide";
		}
		
		override public function update():void 
		{
			super.update();
			
			// ESC to exit
			if (Input.pressed(Key.ESCAPE)) {
				System.exit(1);
			}
			
			if (Input.mouseReleased) {
				if (close) {
					poly.length = 0;
					lastPoint = null;
					text.text = INFO;
					close = false;
				}
				lastPoint = new Point(Input.mouseX, Input.mouseY);
				poly.push(lastPoint);
			}
			
			if (Input.pressed(Key.SPACE)) {
				lastPoint = null;
				close = true;
				var flatRepr:String = poly.length + " pts: ";
				for each (var p:Point in poly) flatRepr += p.x + "," + p.y + ",";
				trace("dump " + flatRepr);
				var dupPoints:Vector.<int> = findDuplicatePoints(poly);
				var simple:Boolean = isSimple(poly); 
				var convex:Boolean = isConvex(poly); 
				var ccw:Boolean = isCCW(poly);
				text.text = 
					//"dupPoints\t: " + (dupPoints == null ? "none" : dupPoints) + "\n" +
					"simple\t\t: " + simple + "\n" +
					"convex\t\t: " + convex + (!simple ? " (not reliable since poly is not simple)" : "") + "\n" +
					"ccw\t\t\t: " + ccw;
				trace(text.text.replace(/\t/g, ""));
			}
		}
		
		
		override public function render():void 
		{
			super.render();
			
			if (poly.length > 1) {
				for (var i:int = 0; i < poly.length - 1; i++) {
					var p1:Point = poly[i];
					var p2:Point = poly[i + 1];
					Draw.linePlus(p1.x, p1.y, p2.x, p2.y, 0xFFFFFFFF, 1);
					Draw.circlePlus(p1.x, p1.y, 3, i == 0 ? 0xffff00 : 0x00ff00, 1, false);
					Draw.circlePlus(p2.x, p2.y, 3, 0x00ff00, 1, false);
				}
				if (close) Draw.linePlus(poly[0].x, poly[0].y, poly[poly.length - 1].x, poly[poly.length - 1].y, 0xFFFFFFFF, 1);
			} else if (poly.length == 1) {
				Draw.circlePlus(poly[0].x, poly[0].y, 3, 0xffff00, 1, false);
			}

			if (lastPoint != null) {
				Draw.linePlus(lastPoint.x, lastPoint.y, Input.mouseX, Input.mouseY, 0xFFFFFFFF);
			}
			
			Draw.circlePlus(Input.mouseX, Input.mouseY, 3, 0xff0000, 1, false);
		}

		
		/** 
		 * Assuming the polygon is simple (not self-intersecting), checks if it is counterclockwise.
		 **/
		static public function isCCW(points:Vector.<Point>):Boolean
		{
			var br:int = 0;
			var len:int = points.length;

			// find bottom right point
			for (var i:int = 1; i < len; i++) {
				if (points[i].y < points[br].y || (points[i].y == points[br].y && points[i].x > points[br].x)) {
					br = i;
				}
			}

			// return true if p is on the left of directed line a-b
			var p:int = (br - 1 + len) % len;
			var a:int = br;
			var b:int = (br + 1 + len) % len;
			
			return (((points[b].x - points[a].x) * (points[p].y - points[a].y)) - 
					((points[p].x - points[a].x) * (points[b].y - points[a].y)) <= 0);
		}

		
		/** 
		 * Assuming the polygon is simple (not self-intersecting), checks if it is convex.
		 **/
		static public function isConvex(points:Vector.<Point>):Boolean
		{
			var isPositive:Boolean = false;

			for (var i:int = 0; i < points.length; i++)
			{
				var lower:int = (i == 0 ? points.length - 1 : i - 1);
				var middle:int = i;
				var upper:int = (i == points.length - 1 ? 0 : i + 1);
				var dx0:Number = points[middle].x - points[lower].x;
				var dy0:Number = points[middle].y - points[lower].y;
				var dx1:Number = points[upper].x - points[middle].x;
				var dy1:Number = points[upper].y - points[middle].y;
				var cross:Number = dx0 * dy1 - dx1 * dy0;
				
				// cross product should have same sign
				// for each vertex if poly is convex.
				var newIsPositive:Boolean = (cross >= 0 ? true : false);

				if (i == 0)
					isPositive = newIsPositive;
				else if (isPositive != newIsPositive)
					return false;
			}

			return true;
		}

		/** 
		 * Checks if the polygon is simple (not self-intersecting).
		 **/
		static public function isSimple(points:Vector.<Point>):Boolean
		{
			var len:int = points.length;

			for (var i:int = 0; i < len; i++)
			{
				// first segment
				var p0:int = i;
				var p1:int = i == len - 1 ? 0 : i + 1;
				
				for (var j:int = i + 1; j < len; j++)
				{
					// second segment
					var q0:int = j;
					var q1:int = j == len - 1 ? 0 : j + 1;
					
					// check for intersection between segment p and segment q.
					// if the intersection point exists and is different from the endpoints,
					// then the poly is not simple
					var intersection:Point = segmentIntersect(points[p0], points[p1], points[q0], points[q1]);
					if (intersection != null
						&& !(intersection.equals(points[p0]) || intersection.equals(points[p1]))
						&& !(intersection.equals(points[q0]) || intersection.equals(points[q1])))
					{
						return false;
					}
				}	
			}

			return true;
		}

		/**
		 * Returns intersection point between segments p0-p1 and q0-q1. Null if no intersection is found.
		 */
		static public function segmentIntersect(p0:Point, p1:Point, q0:Point, q1:Point):Point 
		{
			var intersectionPoint:Point;
			var a1:Number, a2:Number;
			var b1:Number, b2:Number;
			var c1:Number, c2:Number;
		 
			a1 = p1.y - p0.y;
			b1 = p0.x - p1.x;
			c1 = p1.x * p0.y - p0.x * p1.y;
			a2 = q1.y - q0.y;
			b2 = q0.x - q1.x;
			c2 = q1.x * q0.y - q0.x * q1.y;
		 
			var denom:Number = a1 * b2 - a2 * b1;
			if (denom == 0){
				return null;
			}
			
			intersectionPoint = new Point();
			intersectionPoint.x = (b1 * c2 - b2 * c1) / denom;
			intersectionPoint.y = (a2 * c1 - a1 * c2) / denom;
		 
			// check to see if distance between intersection and endpoints
			// is longer than actual segments.
			// return null otherwise.
			if (Point.distance(intersectionPoint, p1) > Point.distance(p0, p1)) return null;
			if (Point.distance(intersectionPoint, p0) > Point.distance(p0, p1)) return null;
			if (Point.distance(intersectionPoint, q1) > Point.distance(q0, q1)) return null;
			if (Point.distance(intersectionPoint, q0) > Point.distance(q0, q1)) return null;
			
			return intersectionPoint;
		}
		
		/**
		 * Returns indices of duplicate points (or null if none are found).
		 */
		static public function findDuplicatePoints(points:Vector.<Point>):Vector.<int> 
		{
			var len:int = points.length;
			if (len <= 1) return null;
			var res:Vector.<int> = new Vector.<int>();
			
			for (var i:int = 0; i < len; i++) {
				for (var j:int = i + 1; j < len; j++) {
					if (points[i].equals(points[j])) res.push(j);
				}
			}
			
			return res.length != 0 ? res : null;
		}
	}

}