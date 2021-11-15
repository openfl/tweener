package caurina.transitions;

/**
 * PropertyInfoObj
 * An object containing the updating info for a given property (its starting value, its final value, and a few other things)
 *
 * @author		Zeh Fernando
 * @version		1.0.0
 * @private
 */
class PropertyInfoObj {
	
	public var valueStart				:Null<Float>;	// Starting value of the tweening (null if not started yet)
	public var valueComplete			:Null<Float>;	// Final desired value (numerically)
	public var originalValueComplete	:Dynamic;		// Final desired value as declared initially
	public var arrayIndex				:Null<Int>;		// Index (if this is an array item)
	public var extra					:Dynamic;		// Additional parameters, used by some special properties
	public var isSpecialProperty		:Bool;			// Whether or not this is a special property instead of a direct one
	public var hasModifier				:Bool;			// Whether or not it has a modifier function
	public var modifierFunction			:Dynamic;		// Modifier function, if any
	public var modifierParameters		:Array<Float>;	// Additional array of modifier parameters

	// ==================================================================================================================================
	// CONSTRUCTOR function -------------------------------------------------------------------------------------------------------------

	/**
	 * Initializes the basic PropertyInfoObj.
	 * 
	 * @param	p_valueStart		Number		Starting value of the tweening (null if not started yet)
	 * @param	p_valueComplete		Number		Final (desired) property value
	 */
	public function new(p_valueStart:Null<Float>, p_valueComplete:Null<Float>, p_originalValueComplete:Dynamic, p_arrayIndex:Null<Int>, p_extra:Dynamic, p_isSpecialProperty:Bool, p_modifierFunction:Dynamic, p_modifierParameters:Array<Float>) {
		valueStart			=	p_valueStart;
		valueComplete		=	p_valueComplete;
		originalValueComplete	=	p_originalValueComplete;
		arrayIndex				=	p_arrayIndex;
		extra					=	p_extra;
		isSpecialProperty		=	p_isSpecialProperty;
		hasModifier			=	p_modifierFunction != null;
		modifierFunction 	=	p_modifierFunction;
		modifierParameters	=	p_modifierParameters;
	}


	// ==================================================================================================================================
	// OTHER functions ------------------------------------------------------------------------------------------------------------------

	/**
	 * Clones this property info and returns the new PropertyInfoObj
	 *
	 * @param	omitEvents		Boolean			Whether or not events such as onStart (and its parameters) should be omitted
	 * @return 					TweenListObj	A copy of this object
	 */
	public function clone():PropertyInfoObj {
		var nProperty:PropertyInfoObj = new PropertyInfoObj(valueStart, valueComplete, originalValueComplete, arrayIndex, extra, isSpecialProperty, modifierFunction, modifierParameters);
		return nProperty;
	}

	/**
	 * Returns this object described as a String.
	 *
	 * @return 					String		The description of this object.
	 */
	public function toString():String {
		var returnStr:String = "\n[PropertyInfoObj ";
		returnStr += "valueStart:" + Std.string(valueStart);
		returnStr += ", ";
		returnStr += "valueComplete:" + Std.string(valueComplete);
		returnStr += ", ";
		returnStr += "originalValueComplete:" + Std.string(originalValueComplete);
		returnStr += ", ";
		returnStr += "arrayIndex:" + Std.string(arrayIndex);
		returnStr += ", ";
		returnStr += "extra:" + Std.string(extra);
		returnStr += ", ";
		returnStr += "isSpecialProperty:" + Std.string(isSpecialProperty);
		returnStr += ", ";
		returnStr += "hasModifier:" + Std.string(hasModifier);
		returnStr += ", ";
		returnStr += "modifierFunction:" + Std.string(modifierFunction);
		returnStr += ", ";
		returnStr += "modifierParameters:" + Std.string(modifierParameters);
		returnStr += "]\n";
		return returnStr;
	}
	
}
