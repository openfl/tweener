package caurina.transitions;

/**
 * SpecialProperty
 * A kind of a getter/setter for special properties
 *
 * @author		Zeh Fernando
 * @version		1.0.0
 */
class SpecialProperty {

	public var getValue:Dynamic->Array<Dynamic>->Dynamic->Float; // (p_obj:Dynamic, p_parameters:Array, p_extra:Dynamic): Number
	public var setValue:Dynamic->Float->Array<Dynamic>->Dynamic->Void; // (p_obj:Dynamic, p_value:Float, p_parameters:Array, p_extra:Dynamic): Void
	public var parameters:Array<Dynamic>;
	public var preProcess:Dynamic->Array<Dynamic>->Dynamic->Dynamic->Float; // (p_obj:Dynamic, p_parameters:Array, p_originalValueComplete:Dynamic, p_extra:Dynamic): Number

	/**
	* Builds a new special property object.
	 *
	 * @param		p_getFunction		Function	Reference to the function used to get the special property value
	 * @param		p_setFunction		Function	Reference to the function used to set the special property value
	 */
	public function new (p_getFunction:Dynamic->Array<Dynamic>->Dynamic->Float, p_setFunction:Dynamic->Float->Array<Dynamic>->Dynamic->Void, p_parameters:Array<Dynamic> = null, p_preProcessFunction:Dynamic->Array<Dynamic>->Dynamic->Dynamic->Float = null) {
		getValue = p_getFunction;
		setValue = p_setFunction;
		parameters = p_parameters;
		preProcess = p_preProcessFunction;
	}

	/**
	 * Converts the instance to a string that can be used when trace()ing the object
	 */
	public function toString():String {
		var value:String = "";
		value += "[SpecialProperty ";
		value += "getValue:"+Std.string(getValue);
		value += ", ";
		value += "setValue:"+Std.string(setValue);
		value += ", ";
		value += "parameters:"+Std.string(parameters);
		value += ", ";
		value += "preProcess:"+Std.string(preProcess);
		value += "]";
		return value;
	}
}
