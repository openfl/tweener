package caurina.transitions;

/**
 * Generic, auxiliary functions
 *
 * @author		Zeh Fernando
 * @version		1.0.0
 */
class AuxFunctions {

	/**
	 * Gets the R (xx0000) bits from a number
	 *
	 * @param		p_num				Number		Color number (ie, 0xffff00)
	 * @return							Number		The R value
	 */
	public static function numberToR(p_num:Int):Int {
		// The initial & is meant to crop numbers bigger than 0xffffff
		#if neko
		if (p_num == null) p_num = 0;
		#end
		return (p_num & 0xff0000) >> 16;
	}

	/**
	 * Gets the G (00xx00) bits from a number
	 *
	 * @param		p_num				Number		Color number (ie, 0xffff00)
	 * @return							Number		The G value
	 */
	public static function numberToG(p_num:Int):Int {
		#if neko
		if (p_num == null) p_num = 0;
		#end
		return (p_num & 0xff00) >> 8;
	}

	/**
	 * Gets the B (0000xx) bits from a number
	 *
	 * @param		p_num				Number		Color number (ie, 0xffff00)
	 * @return							Number		The B value
	 */
	public static function numberToB(p_num:Int):Int {
		#if neko
		if (p_num == null) p_num = 0;
		#end
		return (p_num & 0xff);
	}

	/**
	 * Returns the number of properties an object has
	 *
	 * @param		p_object			Object		Target object with a number of properties
	 * @return							Number		Number of total properties the object has
	 */
	public static function getObjectLength(p_object:Dynamic):Int {
		var totalProperties:Int = 0;
		for (pName in Reflect.fields(p_object)) totalProperties ++;
		return totalProperties;
	}
	
	/* Takes a variable number of objects as parameters and "adds" their properties, from left to right. 
	   If a latter object defines a property as null, it will be removed from the final object
	* @param		args				Object(s)	A variable number of objects
	* @return							Object		An object with the sum of all paremeters added as properties.
	*/
	public static function concatObjects(args:Array<Dynamic>) : Dynamic {
		var finalObject : Dynamic = {};
		for (currentObject in args) {
			for (prop in Reflect.fields(currentObject)) {
				if (Reflect.field(currentObject, prop) == null) {
					Reflect.deleteField(finalObject, prop);
				}else{
					Reflect.setField(finalObject, prop, Reflect.field(currentObject, prop));
				}
			}
		}
		return finalObject;
	}
}
