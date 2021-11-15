/*
Licensed under the MIT License

Copyright (c) 2006-2008 Zeh Fernando, Nate Chatellier, Arthur Debert and Francis
Turmel

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

http://code.google.com/p/tweener/
http://code.google.com/p/tweener/wiki/License
*/

package caurina.transitions;

import flash.display.*;
import flash.events.Event;
import openfl.Lib.getTimer;

/**
 * Tweener
 * Transition controller for movieclips, sounds, textfields and other objects
 *
 * @author		Zeh Fernando, Nate Chatellier, Arthur Debert, Francis Turmel
 * @version		1.33.74, compatible with haXe 2.0 (AS2, AS3, JS)
 * Ported to haXe by Băluță Cristian (www.ralcr.com/ports/tweenerhx)
 */
class Tweener {

	private static var __tweener_controller__:MovieClip;	// Used to ensure the stage copy is always accessible (garbage collection)
	
	private static var _engineExists:Bool = false;		// Whether or not the engine is currently running
	private static var _inited:Bool = false;				// Whether or not the class has been initiated
	private static var _currentTime:Float;					// The current time. This is generic for all tweenings for a "time grid" based update
	private static var _currentTimeFrame:Int;			// The current frame. Used on frame-based tweenings

	private static var _tweenList:List<TweenListObj>;					// List of active tweens

	private static var _timeScale:Float = 1;				// Time scale (default = 1)

	private static var _transitionList:Dynamic;				// List of "pre-fetched" transition functions
	private static var _specialPropertyList:Dynamic;			// List of special properties
	private static var _specialPropertyModifierList:Dynamic;	// List of special property modifiers
	private static var _specialPropertySplitterList:Dynamic;	// List of special property splitters

	public static var autoOverwrite:Bool = true;			// If true, auto overwrite on new tweens is on unless declared as false

	/**
	 * There's no constructor.
	 */
	private function new () {
		trace ("Tweener is a static class and should not be instantiated.");
	}

	// ==================================================================================================================================
	// TWEENING CONTROL functions -------------------------------------------------------------------------------------------------------

	/**
	 * Adds a new tweening
	 *
	 * @param		(first-n param)		Object				Object that should be tweened: a movieclip, textfield, etc.. OR an array of objects
	 * @param		(last param)		Object				Object containing the specified parameters in any order, as well as the properties
															that should be tweened and their values
	 * @param		.time				Number				Time in seconds or frames for the tweening to take (defaults 2)
	 * @param		.delay				Number				Delay time (defaults 0)
	 * @param		.useFrames			Boolean				Whether to use frames instead of seconds for time control (defaults false)
	 * @param		.transition			String/Function		Type of transition equation... (defaults to "easeoutexpo")
	 * @param		.transitionParams	Object				* Direct property, See the TweenListObj class
	 * @param		.onStart			Function			* Direct property, See the TweenListObj class
	 * @param		.onUpdate			Function			* Direct property, See the TweenListObj class
	 * @param		.onComplete			Function			* Direct property, See the TweenListObj class
	 * @param		.onOverwrite		Function			* Direct property, See the TweenListObj class
	 * @param		.onStartParams		Array				* Direct property, See the TweenListObj class
	 * @param		.onUpdateParams		Array				* Direct property, See the TweenListObj class
	 * @param		.onCompleteParams	Array				* Direct property, See the TweenListObj class
	 * @param		.onOverwriteParams	Array				* Direct property, See the TweenListObj class
	 * @param		.rounded			Boolean				* Direct property, See the TweenListObj class
	 * @param		.skipUpdates		Number				* Direct property, See the TweenListObj class
	 * @return							Boolean				TRUE if the tween was successfully added, FALSE if otherwise
	 */
	public static function addTween (p_scopes:Dynamic = null, p_parameters:Dynamic = null):Bool {
		if (p_scopes == null) return false;

		// var i:Float, j:Float, istr:String;

		var rScopes = new Array<Dynamic>(); // List of objects to tween
		if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (p_scopes, Array)) {
			// The first argument is an array
			rScopes = p_scopes.concat();
		} else {
			// The first argument(s) is(are) object(s)
			rScopes = [p_scopes];
		}
	
		// make properties chain ("inheritance")
		var p_obj:Dynamic = TweenListObj.makePropertiesChain(p_parameters);

		// Creates the main engine if it isn't active
		if (!_inited) init();
		if (!_engineExists || __tweener_controller__ == null) startEngine(); // Quick fix for Flash not resetting the vars on double ctrl+enter...

		// Creates a "safer", more strict tweening object
		var rTime:Float = !Reflect.hasField(p_obj, "time") ? 0 : p_obj.time; // Real time
		var rDelay:Float = !Reflect.hasField(p_obj, "delay") ? 0 : p_obj.delay; // Real delay

		// Creates the property list; everything that isn't a hardcoded variable
		var rProperties:Dynamic = {}; // Object containing a list of PropertyInfoObj instances
		var restrictedWords:Dynamic = { overwrite:true, time:true, delay:true, useFrames:true, skipUpdates:true, transition:true, transitionParams:true, onStart:true, onUpdate:true, onComplete:true, onOverwrite:true, onError:true, rounded:true, onStartParams:true, onUpdateParams:true, onCompleteParams:true, onOverwriteParams:true, onStartScope:true, onUpdateScope:true, onCompleteScope:true, onOverwriteScope:true, onErrorScope:true};
		var modifiedProperties:Dynamic = {};
		for (istr in Reflect.fields(p_obj)) {
			if (!Reflect.hasField(restrictedWords, istr)) {
				// It's an additional pair, so adds
				if (Reflect.hasField(_specialPropertySplitterList, istr)) {
					// Special property splitter
					var splitProperties:Array<Dynamic> = Reflect.field(_specialPropertySplitterList, istr).splitValues(Reflect.field(p_obj, istr), Reflect.field(_specialPropertySplitterList, istr).parameters);
					for (prop in splitProperties) {
						if (Reflect.hasField(_specialPropertySplitterList, prop.name)) {
							var splitProperties2:Array<Dynamic> = Reflect.field(_specialPropertySplitterList, prop.name).splitValues(prop.value, Reflect.field(_specialPropertySplitterList, prop.name).parameters);
							for (prop2 in splitProperties2) {
								Reflect.setField(rProperties, prop2.name, {valueStart:null, valueComplete:prop2.value, arrayIndex:prop2.arrayIndex, isSpecialProperty:false});
							}
						} else {
							Reflect.setField(rProperties, prop.name, {valueStart :null, valueComplete:prop.value, arrayIndex:prop.arrayIndex, isSpecialProperty:false});
						}
					}
				} else if (Reflect.hasField(_specialPropertyModifierList, istr)) {
					// Special property modifier
					var tempModifiedProperties:Array<Dynamic> = Reflect.field(_specialPropertyModifierList, istr).modifyValues (Reflect.field(p_obj, istr));
					for (prop in tempModifiedProperties) {
						Reflect.setField(modifiedProperties, prop.name, {modifierParameters:prop.parameters, modifierFunction:Reflect.field(_specialPropertyModifierList, istr).getValue});
					}
				} else {
					// Regular property or special property, just add the property normally
					Reflect.setField(rProperties, istr, {valueStart:null, valueComplete:Reflect.field(p_obj, istr)});
				}
			}
		}

		// Verifies whether the properties exist or not, for warning messages
		#if debug
		// for (istr in Reflect.fields(rProperties)) {
		// 	if (Reflect.hasField(_specialPropertyList, istr)) {
		// 		Reflect.field(rProperties, istr).isSpecialProperty = true;
		// 	} else {
		// 		if (!Reflect.hasField(rScopes[0], istr)) {
		// 			var classType = Type.getClass(rScopes[0]);
		// 			var fields = Type.getInstanceFields(classType);
		// 			if (fields.indexOf(istr) == -1 && fields.indexOf("get_" + istr) == -1)
		// 			{
		// 				printError("The property '" + istr + "' doesn't seem to be a normal object property of " + Std.string(rScopes[0]) + " or a registered special property.");
		// 			}
		// 		}
		// 	}
		// }
		#end

		// Adds the modifiers to the list of properties
		for (istr in Reflect.fields(modifiedProperties)) {
			if (Reflect.hasField(rProperties, istr)) {
				Reflect.field(rProperties, istr).modifierParameters = Reflect.field(modifiedProperties, istr).modifierParameters;
				Reflect.field(rProperties, istr).modifierFunction = Reflect.field(modifiedProperties, istr).modifierFunction;
			}
			
		}

		var rTransition :Dynamic = null; // Real transition

		if (Reflect.field(p_obj, "transition") != null)
		{
			if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (p_obj.transition, String)) {
				// String parameter, transition names
				var trans:String = p_obj.transition.toLowerCase();
				rTransition = Reflect.field(_transitionList, trans);
			} else if (Reflect.isFunction (p_obj.transition)) {
				// Proper transition function
				rTransition = p_obj.transition;
			}
		}
		if (rTransition == null) rTransition = Reflect.field(_transitionList, "easeoutexpo");

		var nProperties:Dynamic;
		var nTween:TweenListObj;

		for (i in 0...rScopes.length) {
			// Makes a copy of the properties
			nProperties = {};
			for (istr in Reflect.fields(rProperties)) {
				Reflect.setField(nProperties, istr, new PropertyInfoObj (Reflect.field(rProperties, istr).valueStart, Reflect.field(rProperties, istr).valueComplete, Reflect.field(rProperties, istr).valueComplete, Reflect.field(rProperties, istr).arrayIndex, {}, Reflect.field(rProperties, istr).isSpecialProperty, Reflect.field(rProperties, istr).modifierFunction, Reflect.field(rProperties, istr).modifierParameters));
			}

			if (Reflect.hasField(p_obj, "useFrames") && p_obj.useFrames == true) {
				nTween = new TweenListObj(
					/* scope			*/	rScopes[i],
					/* timeStart		*/	_currentTimeFrame + (rDelay / _timeScale),
					/* timeComplete		*/	_currentTimeFrame + ((rDelay + rTime) / _timeScale),
					/* useFrames		*/	true,
					/* transition		*/	rTransition,
											p_obj.transitionParams
				);
			} else {
				nTween = new TweenListObj(
					/* scope			*/	rScopes[i],
					/* timeStart		*/	_currentTime + ((rDelay * 1000) / _timeScale),
					/* timeComplete		*/	_currentTime + (((rDelay * 1000) + (rTime * 1000)) / _timeScale),
					/* useFrames		*/	false,
					/* transition		*/	rTransition,
											p_obj.transitionParams
				);
			}

			nTween.properties			=	nProperties;
			nTween.onStart				=	p_obj.onStart;
			nTween.onUpdate				=	p_obj.onUpdate;
			nTween.onComplete			=	p_obj.onComplete;
			nTween.onOverwrite			=	p_obj.onOverwrite;
			nTween.onError			    =	p_obj.onError;
			nTween.onStartParams		=	p_obj.onStartParams;
			nTween.onUpdateParams		=	p_obj.onUpdateParams;
			nTween.onCompleteParams		=	p_obj.onCompleteParams;
			nTween.onOverwriteParams	=	p_obj.onOverwriteParams;
			nTween.onStartScope			=	p_obj.onStartScope;
			nTween.onUpdateScope		=	p_obj.onUpdateScope;
			nTween.onCompleteScope		=	p_obj.onCompleteScope;
			nTween.onOverwriteScope		=	p_obj.onOverwriteScope;
			nTween.onErrorScope			=	p_obj.onErrorScope;
			nTween.rounded				=	p_obj.rounded;
			nTween.skipUpdates			=	p_obj.skipUpdates;

			// Remove other tweenings that occur at the same time
			if (!Reflect.hasField(p_obj, "overwrite") ? autoOverwrite : p_obj.overwrite == true) removeTweensByTime(nTween.scope, nTween.properties, nTween.timeStart, nTween.timeComplete); // Changed on 1.32.74

			// And finally adds it to the list
			_tweenList.add(nTween);

			// Immediate update and removal if it's an immediate tween -- if not deleted, it executes at the end of this frame execution
			if (rTime == 0 && rDelay == 0) {
				updateTweenByObj(nTween);
				removeTweenByObj(nTween);
			}
		}

		return true;
	}

	// A "caller" is like this: [          |     |  | ||] got it? :)
	// this function is crap - should be fixed later/extend on addTween()

	/**
	 * Adds a new caller tweening
	 *
	 * @param		(first-n param)		Object				Object that should be tweened: a movieclip, textfield, etc.. OR an array of objects
	 * @param		(last param)		Object				Object containing the specified parameters in any order, as well as the properties
															that should be tweened and their values
	 * @param		.time				Number				Time in seconds or frames for the tweening to take (defaults 2)
	 * @param		.delay				Number				Delay time (defaults 0)
	 * @param		.count				Number				Number of times this caller should be called
	 * @param		.transition			String/Function		Type of transition equation... (defaults to "easeoutexpo")
	 * @param		.onStart			Function			Event called when tween starts
	 * @param		.onUpdate			Function			Event called when tween updates
	 * @param		.onComplete			Function			Event called when tween ends
	 * @param		.waitFrames			Boolean				Whether to wait (or not) one frame for each call
	 * @return							Boolean				TRUE if the tween was successfully added, FALSE if otherwise
	 */
	
	
	public static function addCaller (p_scopes:Dynamic = null, p_parameters:Dynamic = null):Bool {
		if (p_scopes == null) return false;

		var rScopes:Array<Dynamic>; // List of objects to tween
		if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (p_scopes, Array)) {
			// The first argument is an array
			rScopes = p_scopes.concat();
		} else {
			// The first argument(s) is(are) object(s)
			rScopes = [p_scopes];
		}

		var p_obj:Dynamic = p_parameters;

		// Creates the main engine if it isn't active
		if (!_inited) init();
		if (!_engineExists || __tweener_controller__ == null) startEngine(); // Quick fix for Flash not resetting the vars on double ctrl+enter...

		// Creates a "safer", more strict tweening object
		var rTime:Float = !Reflect.hasField(p_obj, "time") ? 0 : p_obj.time; // Real time
		var rDelay:Float = !Reflect.hasField(p_obj, "delay") ? 0 : p_obj.delay; // Real delay

		var rTransition :Dynamic = null; // Real transition

		if (Reflect.field(p_obj, "transition") != null)
		{
			if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (p_obj.transition, String)) {
				// String parameter, transition names
				var trans:String = p_obj.transition.toLowerCase();
				rTransition = Reflect.field(_transitionList, trans);
			} else if (Reflect.isFunction (p_obj.transition)) {
				// Proper transition function
				rTransition = p_obj.transition;
			}
		}
		if (rTransition == null) rTransition = Reflect.field(_transitionList, "easeoutexpo");

		var nTween:TweenListObj;
		for (i in 0...rScopes.length) {
			
			if (Reflect.hasField(p_obj, "useFrames") && p_obj.useFrames == true) {
				nTween = new TweenListObj(
					/* scope			*/	rScopes[i],
					/* timeStart		*/	_currentTimeFrame + (rDelay / _timeScale),
					/* timeComplete		*/	_currentTimeFrame + ((rDelay + rTime) / _timeScale),
					/* useFrames		*/	true,
					/* transition		*/	rTransition,
											p_obj.transitionParams
				);
			} else {
				nTween = new TweenListObj(
					/* scope			*/	rScopes[i],
					/* timeStart		*/	_currentTime + ((rDelay * 1000) / _timeScale),
					/* timeComplete		*/	_currentTime + (((rDelay * 1000) + (rTime * 1000)) / _timeScale),
					/* useFrames		*/	false,
					/* transition		*/	rTransition,
											p_obj.transitionParams
				);
			}

			nTween.properties			=	null;
			nTween.onStart				=	p_obj.onStart;
			nTween.onUpdate				=	p_obj.onUpdate;
			nTween.onComplete			=	p_obj.onComplete;
			nTween.onOverwrite			=	p_obj.onOverwrite;
			nTween.onStartParams		=	p_obj.onStartParams;
			nTween.onUpdateParams		=	p_obj.onUpdateParams;
			nTween.onCompleteParams		=	p_obj.onCompleteParams;
			nTween.onOverwriteParams	=	p_obj.onOverwriteParams;
			nTween.onStartScope			=	p_obj.onStartScope;
			nTween.onUpdateScope		=	p_obj.onUpdateScope;
			nTween.onCompleteScope		=	p_obj.onCompleteScope;
			nTween.onOverwriteScope		=	p_obj.onOverwriteScope;
			nTween.onErrorScope			=	p_obj.onErrorScope;
			nTween.isCaller				=	true;
			nTween.count				=	p_obj.count;
			nTween.waitFrames			=	p_obj.waitFrames;

			// And finally adds it to the list
			_tweenList.push(nTween);

			// Immediate update and removal if it's an immediate tween -- if not deleted, it executes at the end of this frame execution
			if (rTime == 0 && rDelay == 0) {
				updateTweenByObj(nTween);
				removeTweenByObj(nTween);
			}
		}

		return true;
	}

	/**
	 * Remove an specified tweening of a specified object the tweening list, if it conflicts with the given time
	 *
	 * @param		p_scope				Object						List of objects affected
	 * @param		p_properties		Object						List of properties affected (PropertyInfoObj instances)
	 * @param		p_timeStart			Number						Time when the new tween starts
	 * @param		p_timeComplete		Number						Time when the new tween ends
	 * @return							Boolean						Whether or not it actually deleted something
	 */
	public static function removeTweensByTime (p_scope:Dynamic, p_properties:Dynamic, p_timeStart:Float, p_timeComplete:Float):Bool {
		var removed:Bool = false;
		var removedLocally:Bool;

		for (obj in _tweenList) {
			if (p_scope == obj.scope) {
				// Same object...
				if (p_timeComplete > obj.timeStart && p_timeStart < obj.timeComplete) {
					// New time should override the old one...
					removedLocally = false;
					for (pName in Reflect.fields(obj.properties)) {
						if (Reflect.field(p_properties, pName) != null) {
							// Same object, same property
							// Finally, remove this old tweening and use the new one
							if (Reflect.isFunction (obj.onOverwrite)) {
								var eventScope = obj.onOverwriteScope != null ? obj.onOverwriteScope : obj.scope;
								// try {
									_callMethod(eventScope, obj.onOverwrite, obj.onOverwriteParams);
									// obj.onOverwrite.apply (eventScope, obj.onOverwriteParams);
								// }
								// catch (e:Dynamic) {
								// 	handleError (obj, e, "onOverwrite");
								// }
							}
							Reflect.deleteField(obj.properties, pName);
							removedLocally = true;
							removed = true;
						}
					}
					if (removedLocally) {
						// Verify if this can be deleted
						if (AuxFunctions.getObjectLength(obj.properties) == 0) removeTweenByObj(obj);
					}
				}
			}
		}

		return removed;
	}

	/*
	public static function removeTweens (p_scope:Object, ...args):Boolean {
		// Create the property list
		var properties:Array = new Array();
		var i:uint;
		for (i = 0; i < args.length; i++) {
			if (typeof(args[i]) == "string" && properties.indexOf(args[i]) == -1) properties.push(args[i]);
		}
		// Call the affect function on the specified properties
		return affectTweens(removeTweenByIndex, p_scope, properties);
	}
	*/

	/**
	 * Remove tweenings from a given object from the tweening list
	 *
	 * @param		p_tween				Object		Object that must have its tweens removed
	 * @param		(2nd-last params)	Object		Property(ies) that must be removed
	 * @return							Boolean		Whether or not it successfully removed this tweening
	 */
	public static function removeTweens (p_scope:Dynamic, args:Array<String> = null) : Bool {
		// Create the property list
		var properties:Array<String> = new Array();
		if (args == null) args = [];
		for (arg in args) {
			if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (arg, String) && properties.indexOf(arg) == -1) {
				if (Reflect.hasField(_specialPropertySplitterList, arg)) {
					//special property, get splitter array first
					var sps:SpecialPropertySplitter = Reflect.field(_specialPropertySplitterList, arg);
					var specialProps:Array<Dynamic> = sps.splitValues(p_scope, null);
					for (prop in specialProps) {
					//trace(prop.name);
						properties.push(prop.name);
					}
				} else {
					properties.push(arg);
				}
			}
		}

		// Call the affect function on the specified properties
		return affectTweens(removeTweenByObj, p_scope, properties);
	}

	/**
	 * Remove all tweenings from the engine
	 *
	 * @return					<code>true</code> if it successfully removed any tweening, <code>false</code> if otherwise.
	 */
	public static function removeAllTweens ():Bool {
		if (_tweenList == null || _tweenList.isEmpty()) return false;
		for (obj in _tweenList) {
			removeTweenByObj(obj);
		}
		return true;
	}

	/**
	 * Pause tweenings from a given object
	 *
	 * @param		p_scope				Object that must have its tweens paused
	 * @param		(2nd-last params)	Property(ies) that must be paused
	 * @return					<code>true</code> if it successfully paused any tweening, <code>false</code> if otherwise.
	 */
	public static function pauseTweens (p_scope:Dynamic, args:Array<String> = null):Bool {
		// Create the property list
		var properties:Array<String> = new Array();
		if (args == null) args = [];
		for (arg in args) {
			if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (arg, String) && properties.indexOf(arg) == -1) properties.push(arg);
		}
		// Call the affect function on the specified properties
		return affectTweens(pauseTweenByObj, p_scope, properties);
	}

	/**
	 * Pause all tweenings on the engine
	 *
	 * @return					<code>true</code> if it successfully paused any tweening, <code>false</code> if otherwise.
	 */
	public static function pauseAllTweens ():Bool {
		if (_tweenList == null || _tweenList.isEmpty()) return false;
		for (obj in _tweenList) {
			pauseTweenByObj(obj);
		}
		return true;
	}

	/**
	 * Resume tweenings from a given object.
	 *
	 * @param		p_scope				Object		Object that must have its tweens resumed
	 * @param		(2nd-last params)	Object		Property(ies) that must be resumed
	 * @return							Boolean		Whether or not it successfully resumed something
	 */
	public static function resumeTweens (p_scope:Dynamic, args:Array<String> = null):Bool {
		// Create the property list
		var properties:Array<String> = new Array();
		if (args == null) args = [];
		for (arg in args) {
			if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (arg, String) && properties.indexOf(arg) == -1) properties.push(arg);
		}
		// Call the affect function on the specified properties
		return affectTweens(resumeTweenByObj, p_scope, properties);
	}

	/**
	 * Resume all tweenings on the engine.
	 *
	 * @return <code>true</code> if it successfully resumed any tweening, <code>false</code> if otherwise.
	 * @see #pauseAllTweens()
	 */
	public static function resumeAllTweens ():Bool {
		if (_tweenList == null || _tweenList.isEmpty()) return false;
		for (obj in _tweenList) {
			resumeTweenByObj(obj);
		}
		return true;
	}

	/**
	 * Do some generic action on specific tweenings (pause, resume, remove, more?)
	 *
	 * @param		p_function			Function	Function to run on the tweenings that match
	 * @param		p_scope				Object		Object that must have its tweens affected by the function
	 * @param		p_properties		Array		Array of strings that must be affected
	 * @return							Boolean		Whether or not it successfully affected something
	 */
	private static function affectTweens (p_affectFunction:Dynamic, p_scope:Dynamic, p_properties:Array<String>) : Bool {
		if (_tweenList == null || _tweenList.isEmpty()) return false;
		var affected = false;
		
		for (obj in _tweenList) {
			if (obj.scope == p_scope) {
				if (p_properties.length == 0) {
					// Can affect everything
					p_affectFunction(obj);
					affected = true;
				} else {
					// Must check whether this tween must have specific properties affected
					var affectedProperties:Array<String> = new Array();
					for (prop in p_properties)
						if (Reflect.field(obj.properties, prop) != null)
							affectedProperties.push(prop);
					
					if (affectedProperties.length > 0) {
						// This tween has some properties that need to be affected
						var objectProperties:UInt = AuxFunctions.getObjectLength(obj.properties);
						if (objectProperties == affectedProperties.length) {
							// The list of properties is the same as all properties, so affect it all
							p_affectFunction(obj);
						} else {
							// The properties are mixed, so split the tween and affect only certain specific properties
							var slicedTweenObj:TweenListObj = splitTweens(obj, affectedProperties);
							p_affectFunction (slicedTweenObj);
						}
						affected = true;
					}
				}
			}
		}
		return affected;
	}

	/**
	 * Splits a tweening in two
	 *
	 * @param		p_tween				Number		Object that must have its tweens split
	 * @param		p_properties		Array		Array of strings containing the list of properties that must be separated
	 * @return							Number		The index number of the new tween
	 */
	public static function splitTweens (originalTween:TweenListObj, p_properties:Array<String>):TweenListObj {
		// First, duplicates
		var newTween:TweenListObj = originalTween.clone(false);

		// Now, removes tweenings where needed
		// Removes the specified properties from the old one
		for (pName in p_properties) {
			Reflect.deleteField(originalTween.properties, pName);
		}

		// Removes the unspecified properties from the new one
		var found:Bool;
		for (pName in Reflect.fields(newTween.properties)) {
			found = false;
			for (prop in p_properties) {
				if (prop == pName) {
					found = true;
					break;
				}
			}
			if (!found) {
				Reflect.deleteField(newTween.properties, pName);
			}
		}

		// If there are empty property lists, a cleanup is done on the next updateTweens() cycle
		_tweenList.add(newTween);
		return newTween;
		
	}

	// ==================================================================================================================================
	// ENGINE functions -----------------------------------------------------------------------------------------------------------------

	/**
	 * Updates all existing tweenings.
	 *
	 * @return							Boolean		FALSE if no update was made because there's no tweening (even delayed ones)
	 */
	private static function updateTweens ():Bool {
		if (_tweenList == null || _tweenList.isEmpty()) return false;
		for (obj in _tweenList)
			if (!obj.isPaused)
				if (!updateTweenByObj(obj))
					removeTweenByObj(obj);
		
		return true;
	}

	/**
	 * Remove an specific tweening from the tweening list
	 *
	 * @param		p_tween				Number		Index of the tween to be removed on the tweenings list
	 * @return							Boolean		Whether or not it successfully removed this tweening
	 */
	public static function removeTweenByObj (tTweening:TweenListObj/*, p_finalRemoval:Bool = false*/):Bool {
		return _tweenList.remove(tTweening);
	}

	/**
	 * Pauses a specific tween
	 *
	 * @param		p_tween				Number		Index of the tween to be paused
	 * @return							Boolean		Whether or not it successfully paused this tweening
	 */
	public static function pauseTweenByObj (tTweening:TweenListObj):Bool {
		if (tTweening == null || tTweening.isPaused) return false;
		tTweening.timePaused = getCurrentTweeningTime(tTweening);
		tTweening.isPaused = true;

		return true;
	}

	/**
	 * Resumes a specific tween
	 *
	 * @param		p_tween				Number		Index of the tween to be resumed
	 * @return							Boolean		Whether or not it successfully resumed this tweening
	 */
	public static function resumeTweenByObj (tTweening:TweenListObj):Bool {
		if (tTweening == null || !tTweening.isPaused) return false;
		var cTime :Float = getCurrentTweeningTime(tTweening);
		tTweening.timeStart += cTime - tTweening.timePaused;
		tTweening.timeComplete += cTime - tTweening.timePaused;
		tTweening.timePaused = null;
		tTweening.isPaused = false;

		return true;
	}

	/**
	 * Updates a specific tween
	 *
	 * @param		i					Number		Index (from the tween list) of the tween that should be updated
	 * @return							Boolean		FALSE if it's already finished and should be deleted, TRUE if otherwise
	 */
	static function updateTweenByObj (tTweening:TweenListObj):Bool {

		if (tTweening == null || tTweening.scope == null) return false;

		var isOver:Bool = false;		// Whether or not it's over the update time
		var mustUpdate:Bool;			// Whether or not it should be updated (skipped if false)

		var nv : Float;					// New value for each property

		var t:Float;					// current time (frames, seconds)
		var b:Float;					// beginning value
		var c:Float;					// change in value
		var d:Float;					// duration (frames, seconds)

		var pName:String;				// Property name, used in loops
		var eventScope:Dynamic;			// Event scope, used to call functions

		// Shortcut stuff for speed
		var tScope:Dynamic;				// Current scope
		var cTime:Float = getCurrentTweeningTime(tTweening);
		var tProperty:Dynamic;			// Property being checked

		if (cTime >= tTweening.timeStart) {
			// Can already start

			tScope = tTweening.scope;

			if (tTweening.isCaller) {
				// It's a 'caller' tween
				if (!tTweening.hasStarted) {
					if (Reflect.isFunction(tTweening.onStart)) {
						eventScope = tTweening.onStartScope != null ? tTweening.onStartScope : tScope;
						// try {
							_callMethod(eventScope, tTweening.onStart, tTweening.onStartParams);
							// tTweening.onStart.apply(eventScope, tTweening.onStartParams);
						// } catch(e2:Error) {
						// 	handleError(tTweening, e2, "onStart");
						// }
					}
					tTweening.hasStarted = true;
				}
				do {
					t = ((tTweening.timeComplete - tTweening.timeStart)/tTweening.count) * (tTweening.timesCalled+1);
					b = tTweening.timeStart;
					c = tTweening.timeComplete - tTweening.timeStart;
					d = tTweening.timeComplete - tTweening.timeStart;
					nv = tTweening.transition(t, b, c, d);

					if (cTime >= nv) {
						if (Reflect.isFunction(tTweening.onUpdate)) {
							eventScope = tTweening.onUpdateScope != null ? tTweening.onUpdateScope : tScope;
							// try {
								_callMethod(eventScope, tTweening.onUpdate, tTweening.onUpdateParams);
								// tTweening.onUpdate.apply (eventScope, tTweening.onUpdateParams);
							// }
							// catch (e:Dynamic) {
							// 	handleError (tTweening, e, "onUpdate");
							// }
						}

						tTweening.timesCalled++;
						if (tTweening.timesCalled >= tTweening.count) {
							isOver = true;
							break;
						}
						if (tTweening.waitFrames) break;
					}

				} while (cTime >= nv);
			} else {
				// It's a normal transition tween

				mustUpdate = tTweening.skipUpdates < 1 || tTweening.skipUpdates == null || tTweening.updatesSkipped >= tTweening.skipUpdates;

				if (cTime >= tTweening.timeComplete) {
					isOver = true;
					mustUpdate = true;
				}

				if (!tTweening.hasStarted) {
					// First update, read all default values (for proper filter tweening)
					if (Reflect.isFunction (tTweening.onStart)) {
						eventScope = tTweening.onStartScope != null ? tTweening.onStartScope : tScope;
						// try {
							_callMethod(eventScope, tTweening.onStart, tTweening.onStartParams);
							// tTweening.onStart.apply (eventScope, tTweening.onStartParams);
						// }
						// catch (e:Dynamic) {
						// 	handleError (tTweening, e, "onStart");
						// }
					}
					var pv:Null<Float> = null;
					for (pName in Reflect.fields(tTweening.properties)) {
						var prop = Reflect.field(tTweening.properties, pName);
						if (Reflect.hasField(prop, "isSpecialProperty") && prop.isSpecialProperty == true) {
							// It's a special property, tunnel via the special property function
							if (Reflect.field(_specialPropertyList, pName) != null) {
								if (Reflect.field(_specialPropertyList, pName).preProcess != null) {
									Reflect.field(tTweening.properties, pName).valueComplete = Reflect.field(_specialPropertyList, pName).preProcess (tScope, Reflect.field(_specialPropertyList, pName).parameters, Reflect.field(tTweening.properties, pName).originalValueComplete, Reflect.field(tTweening.properties, pName).extra);
								}
								pv = Reflect.field(_specialPropertyList, pName).getValue (tScope, Reflect.field(_specialPropertyList, pName).parameters, Reflect.field(tTweening.properties, pName).extra);
							}
						} else {
							// Directly read property
							pv = _getProperty(tScope, pName);
						}
						Reflect.setField(prop, "valueStart", pv == null ? prop.valueComplete : pv);
					}
					mustUpdate = true;
					tTweening.hasStarted = true;
				}

				if (mustUpdate) {
					for (pName in Reflect.fields(tTweening.properties)) {
						tProperty = Reflect.field(tTweening.properties, pName);
						if (tProperty == null) return false;

						if (isOver) {
							// Tweening time has finished, just set it to the final value
							nv = tProperty.valueComplete;
						} else {
							if (tProperty.hasModifier) {
								// Modified
								t = cTime - tTweening.timeStart;
								d = tTweening.timeComplete - tTweening.timeStart;
								nv = tTweening.transition(t, 0, 1, d, tTweening.transitionParams);
								nv = tProperty.modifierFunction(tProperty.valueStart, tProperty.valueComplete, nv, tProperty.modifierParameters);
							} else {
								// Normal update
								t = cTime - tTweening.timeStart;
								b = tProperty.valueStart;
								c = tProperty.valueComplete - tProperty.valueStart;
								d = tTweening.timeComplete - tTweening.timeStart;
								nv = tTweening.transition(t, b, c, d, tTweening.transitionParams);
							}
						}

						if (tTweening.rounded) nv = Math.round(nv);
						if (tProperty.isSpecialProperty) {
							// It's a special property, tunnel via the special property method
							Reflect.field(_specialPropertyList, pName).setValue(tScope, nv, Reflect.field(_specialPropertyList, pName).parameters, Reflect.field(tTweening.properties, pName).extra);
						} else {
							// Directly set property
							_setProperty(tScope, pName, nv);
						}
					}

					tTweening.updatesSkipped = 0;

					if (Reflect.isFunction (tTweening.onUpdate)) {
						eventScope = tTweening.onUpdateScope != null ? tTweening.onUpdateScope : tScope;
						// try {
							_callMethod(eventScope, tTweening.onUpdate, tTweening.onUpdateParams);
							// tTweening.onUpdate.apply (eventScope, tTweening.onUpdateParams);
						// }
						// catch (e:Dynamic) {
						// 	handleError (tTweening, e, "onUpdate");
						// }
					}
				} else {
					tTweening.updatesSkipped++;
				}
			}
			
			if (isOver && Reflect.isFunction(tTweening.onComplete)) {
				eventScope = tTweening.onCompleteScope != null ? tTweening.onCompleteScope : tScope;
				// try {
					_callMethod(eventScope, tTweening.onComplete, tTweening.onCompleteParams);
					// tTweening.onComplete.apply (eventScope, tTweening.onCompleteParams);
				// }
				// catch (e:Dynamic) {
				// 	handleError (tTweening, e, "onComplete");
				// }
			}

			return (!isOver);
		}

		// On delay, hasn't started, so returns true
		return (true);
	}

	/**
	 * Initiates the Tweener--should only be ran once.
	 */
	private static function init():Void {
		_inited = true;

		// Registers all default equations
		_transitionList = {};
		Equations.init();

		// Registers all default special properties
		_specialPropertyList = {};
		_specialPropertyModifierList = {};
		_specialPropertySplitterList = {};
	}

	/**
	 * Adds a new function to the available transition list "shortcuts".
	 *
	 * @param		p_name				String		Shorthand transition name
	 * @param		p_function			Function	The proper equation function
	 */
	public static function registerTransition(p_name:String, p_function:Dynamic): Void {
		if (!_inited) init();
		Reflect.setField(_transitionList, p_name, p_function);
	}

	/**
	 * Adds a new special property to the available special property list.
	 *
	 * @param		p_name				Name of the "special" property.
	 * @param		p_getFunction		Function that gets the value.
	 * @param		p_setFunction		Function that sets the value.
	 */
	public static function registerSpecialProperty (p_name:String, p_getFunction:Dynamic, p_setFunction:Dynamic, p_parameters:Array<Dynamic> = null, p_preProcessFunction:Dynamic = null): Void {
		if (!_inited) init();
		var sp:SpecialProperty = new SpecialProperty(p_getFunction, p_setFunction, p_parameters, p_preProcessFunction);
		Reflect.setField(_specialPropertyList, p_name, sp);
	}

	/**
	 * Adds a new special property modifier to the available modifier list.
	 *
	 * @param		p_name				Name of the "special" property modifier.
	 * @param		p_modifyFunction	Function that modifies the value.
	 * @param		p_getFunction		Function that gets the value.
	 */
	public static function registerSpecialPropertyModifier(p_name:String, p_modifyFunction:Dynamic, p_getFunction:Dynamic): Void {
		if (!_inited) init();
		var spm:SpecialPropertyModifier = new SpecialPropertyModifier(p_modifyFunction, p_getFunction);
		Reflect.setField(_specialPropertyModifierList, p_name, spm);
	}

	/**
	 * Adds a new special property splitter to the available splitter list.
	 *
	 * @param		p_name				Name of the "special" property splitter.
	 * @param		p_splitFunction		Function that splits the value.
	 */
	public static function registerSpecialPropertySplitter(p_name:String, p_splitFunction:Dynamic, p_parameters:Array<Dynamic> = null): Void {
		if (!_inited) init();
		var sps:SpecialPropertySplitter = new SpecialPropertySplitter (p_splitFunction, p_parameters);
		Reflect.setField(_specialPropertySplitterList, p_name, sps);
	}

	/**
	 * Starts the Tweener class engine. It is supposed to be running every time a tween exists
	 */
	private static function startEngine(): Void {
		_engineExists = true;
		_tweenList = new List<TweenListObj>();
		__tweener_controller__ = new MovieClip();
		__tweener_controller__.addEventListener(Event.ENTER_FRAME, Tweener.onEnterFrame);
		
		_currentTimeFrame = 0;
		updateTime();
	}

	/**
	 * Stops the Tweener class engine
	 */
	private static function stopEngine():Void {
		_engineExists = false;
		_tweenList.clear();
		_currentTime = 0;
		_currentTimeFrame = 0;
		__tweener_controller__.removeEventListener(Event.ENTER_FRAME, Tweener.onEnterFrame);
		__tweener_controller__ = null;
	}

	/**
	 * Updates the time to enforce time grid-based updates.
	 */
	public static function updateTime():Void {
		_currentTime = getTimer();
	}

	/**
	 * Updates the current frame count
	 */
	public static function updateFrame():Void {
		_currentTimeFrame++;
	}

	/**
	 * Ran once every frame. It's the main engine; updates all existing tweenings.
	 */
	public static function onEnterFrame(e:Event):Void {
		updateTime();
		updateFrame();
		var hasUpdated:Bool = false;
		hasUpdated = updateTweens();
		if (!hasUpdated) stopEngine();	// There's no tweening to update or wait, so it's better to stop the engine
	}

	/**
	 * Sets the new time scale.
	 *
	 * @param		p_time				Number		New time scale (0.5 = slow, 1 = normal, 2 = 2x fast forward, etc)
	 */
	public static function setTimeScale(p_time:Float):Void {
		// var i:Float;
		var cTime:Float;

		if (Math.isNaN(p_time)) p_time = 1;
		if (p_time < 0.00001) p_time = 0.00001;
		if (p_time != _timeScale) {
			if (_tweenList != null) {
				// Multiplies all existing tween times accordingly
				for (tweenListObj in _tweenList) {
					cTime = getCurrentTweeningTime(tweenListObj);
					tweenListObj.timeStart = cTime - ((cTime - tweenListObj.timeStart) * _timeScale / p_time);
					tweenListObj.timeComplete = cTime - ((cTime - tweenListObj.timeComplete) * _timeScale / p_time);
					if (tweenListObj.timePaused != null) tweenListObj.timePaused = cTime - ((cTime - tweenListObj.timePaused) * _timeScale / p_time);
				}
			}
			// Sets the new timescale value (for new tweenings)
			_timeScale = p_time;
		}
	}


	// ==================================================================================================================================
	// AUXILIARY functions --------------------------------------------------------------------------------------------------------------

	/**
	 * Finds whether or not an object has any tweening.
	 *
	 * @param		p_scope		Target object.
	 * @return					<code>true</code> if there's a tweening occuring on this object (paused, delayed, or active), <code>false</code> if otherwise.
	 */
	public static function isTweening (p_scope:Dynamic):Bool {
		if (_tweenList == null || _tweenList.length == 0) return false;

		for (tweenListObj in _tweenList) {
			if (tweenListObj != null && tweenListObj.scope == p_scope) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Return an array containing a list of the properties being tweened for this object
	 *
	 * @param		p_scope		Target object.
	 * @return							Array		List of strings with properties being tweened (including delayed or paused)
	 */
	public static function getTweens (p_scope:Dynamic) : Array<String> {
		if (_tweenList == null) return [];
		if (_tweenList.length == 0) return [];
		var tList = new Array<String>();
		
		for (tweenListObj in _tweenList)
			if (tweenListObj != null)
			if (tweenListObj.scope == p_scope)
				for (pName in Reflect.fields(tweenListObj.properties))
					tList.push ( pName );
					
		return tList;
	}

	/**
	 * Return the number of properties being tweened for a given object.
	 *
	 * @param		p_scope		Target object.
	 * @return					Total number of properties being tweened (including delayed or paused tweens).
	 */
	public static function getTweenCount (p_scope:Dynamic):Int {
		if (_tweenList == null || _tweenList.length == 0) return 0;
		var c:Int = 0;

		for (tweenListObj in _tweenList) {
			if (tweenListObj.scope == p_scope) {
				c += AuxFunctions.getObjectLength (tweenListObj.properties);
			}
		}
		return c;
	}


	/* Handles errors when Tweener executes any callbacks (onStart, onUpdate, etc)
	*  If the TweenListObj specifies an <code>onError</code> callback it well get called,
	*  passing the <code>Error</code> object and the current scope as parameters.
	*  If no <code>onError</code> callback is specified, it will trace a stackTrace.
	*/
	private static function handleError(pTweening : TweenListObj, pError : Dynamic, pCallBackName : String) : Void{
		// do we have an error handler?
		if (pTweening.onError != null && Reflect.isFunction(pTweening.onError)){
			// yup, there's a handler. Wrap this in a try catch in case the onError throws an error itself.
			var eventScope:Dynamic = pTweening.onErrorScope != null ? pTweening.onErrorScope : pTweening.scope;
			// try {
				_callMethod(eventScope, pTweening.onError, [pTweening.scope, pError]);
				// pTweening.onError.apply (eventScope, [pTweening.scope, pError]);
			// }
			// catch (metaError : Dynamic) {
			// 	printError (Std.string (pTweening.scope) +
			// 				" raised an error while executing the 'onError' handler. Original error:\n " +
			// 				pError +  "\nonError error: " + metaError);
			// }
		} else {
			// if handler is undefied or null trace the error message (allows empty onErro's to ignore errors)
			if (pTweening.onError == null) {
				printError (pTweening.scope.toString() + " raised an error while executing the '" + pCallBackName + "'handler. \n" + pError );
			}
		}
	}

	/**
	 * Get the current tweening time (no matter if it uses frames or time as basis), given a specific tweening
	 *
	 * @param		p_tweening				TweenListObj		Tween information
	 */
	public static function getCurrentTweeningTime(p_tweening:Dynamic):Float {
		return (Reflect.hasField(p_tweening, "useFrames") && p_tweening.useFrames) ? _currentTimeFrame : _currentTime;
	}

	/**
	 * Return the current tweener version
	 *
	 * @return							String		The number of the current Tweener version
	 */
	public static function getVersion():String {
		return "1.33.74";
	}


	// ======================================================================================================
	// DEBUG functions --------------------------------------------------------------------------------------

	/**
	 * Output an error message
	 *
	 * @param		p_message				String		The error message to output
	 */
	public static function printError(p_message:String): Void {
		//
		trace("## [Tweener] Error: "+p_message);
	}

	private static inline function _callMethod (scope:Dynamic, method:Dynamic, params:Array<Dynamic> = null):Dynamic
	{
		if (method == null) return null;
		#if flash
		return method.apply (scope, params);
		#else
		if (params == null)
		{
			params = [];
		}
		#if neko
		var diff = untyped($nargs)(method) - params.length;
		if (diff > 0)
		{
			params = params.copy();
			for (i in 0...diff)
			{
				params.push (null);
			}
		}
		#end
		// TODO: Set scope?
		return Reflect.callMethod(#if hl null #else method #end, method, params);
		#end
	}

	private static inline function _getProperty (target:Dynamic, propertyName:String):Dynamic
	{
		var value = null;
		if (Reflect.hasField(target, propertyName))
		{
			#if flash
			value = untyped target[propertyName];
			#else
			value = Reflect.field(target, propertyName);
			#end	
		}
		else
		{	
			value = Reflect.getProperty(target, propertyName);
		}
		return value;
	}

	private static inline function _setProperty (target:Dynamic, propertyName:String, value:Dynamic):Void
	{
		// TODO: Cache for performance?
		// if (details.isField) {
			
		// 	#if flash
		// 	untyped details.target[details.propertyName] = value;
		// 	#else
		// 	Reflect.setField (details.target, details.propertyName, value);
		// 	#end
			
		// } else {
			
		// 	#if (haxe_209 || haxe3)
		// 	Reflect.setProperty (details.target, details.propertyName, value);
		// 	#end
			
		// }

		if (Reflect.hasField(target, propertyName) #if flash && !untyped(target).hasOwnProperty("set_" + propertyName) #elseif js && !(untyped(target).__properties__ && untyped(target).__properties__["set_" + propertyName]) #end)
		{
			#if flash
			untyped target[propertyName] = value;
			#else
			Reflect.setField(target, propertyName, value);
			#end
		}
		else
		{
			#if (haxe_209 || haxe3)
			Reflect.setProperty(target, propertyName, value);
			#end
		}
	}
}
