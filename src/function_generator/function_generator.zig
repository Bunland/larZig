const jsc = @import("../jsc/jsc.zig");

///*
//* Creates a custom function in JavaScript.
//*
//* @param context           The JavaScript context in which the function will be created.
//* @param globalObject      The global object to which the custom function will be attached.
//* @param functionName      The name of the function to be created in JavaScript.
//* @param functionCallback  A pointer to the C/C++ function that will execute when the JavaScript function is invoked.
//*
//* @return                 There is no explicit return value.
//*/
pub fn createCustomFunction(context: jsc.JSContextRef, globalObject: jsc.JSObjectRef, functionName: []const u8, functionCallback: jsc.JSObjectCallAsFunctionCallback) !void {
    // Creating a JavaScript string for the function name
    const functionString = jsc.JSStringCreateWithUTF8CString(functionName.ptr);

    // Creating a JavaScript function object with the provided callback
    const functionObject = jsc.JSObjectMakeFunctionWithCallback(context, functionString, functionCallback);

    // Attaching the function to the global object
    jsc.JSObjectSetProperty(context, globalObject, functionString, functionObject, jsc.kJSPropertyAttributeNone, null);

    // Releasing the JavaScript string
    jsc.JSStringRelease(functionString);
}
