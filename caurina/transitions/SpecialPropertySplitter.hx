package caurina.transitions;

/**
 * SpecialPropertySplitter
 * A proxy setter for special properties
 *
 * @author		Zeh Fernando
 * @version		1.0.0
 */
class SpecialPropertySplitter {

	public var parameters:Array<Dynamic>;
	public var splitValues:Dynamic->Array<Dynamic>->Array<Dynamic>;

	/**
	 * Builds a new group special propery object.
	 * 
	 * @param		p_splitFunction		Function	Reference to the function used to split a value 
	 */
	public function new (p_splitFunction:Dynamic->Array<Dynamic>->Array<Dynamic>, p_parameters:Array<Dynamic>) {
		splitValues = p_splitFunction;
		parameters = p_parameters;
	}

	/**
	 * Converts the instance to a string that can be used when trace()ing the object
	 */
	public function toString():String {
		var value:String = "";
		value += "[SpecialPropertySplitter ";
		value += "splitValues:"+Std.string(splitValues); // .toString();
		value += ", ";
		value += "parameters:"+Std.string(parameters);
		value += "]";
		return value;
	}

}
