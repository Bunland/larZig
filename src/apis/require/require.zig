// Import necessary modules
const std = @import("std");
const jsc = @import("../../jsc/jsc.zig");
const rd = @import("../../utils/readScript.zig");

// Define the Require function that acts as a callback from JavaScript
pub fn Require(context: jsc.JSContextRef, globalObject: jsc.JSObjectRef, thisObject: jsc.JSObjectRef, argumentCount: usize, arguments: [*c]const jsc.JSValueRef, exception: [*c]jsc.JSValueRef) callconv(.C) jsc.JSValueRef {
    _ = thisObject;
    _ = globalObject;

    // Use Zig's standard allocator
    const allocator = std.heap.page_allocator;

    // Check that at least one argument was provided from JavaScript
    if (argumentCount < 1) {
        return jsc.JSValueMakeUndefined(context);
    }

    // Convert the first argument (file path) from JavaScript to a string
    const string = jsc.JSValueToStringCopy(context, arguments[0], exception);
    // Allocate memory for a buffer and copy the UTF-8 representation of the string into that buffer
    var buffer = allocator.alloc(u8, jsc.JSStringGetMaximumUTF8CStringSize(string)) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        return jsc.JSValueMakeUndefined(context);
    };
    // Free the memory at the end of the block
    defer allocator.free(buffer);

    // Get the length of the UTF-8 string and create a slice representing the string
    const string_length = jsc.JSStringGetUTF8CString(string, buffer.ptr, buffer.len);
    const result: []const u8 = buffer[0 .. string_length - 1];

    // Use the custom readScript function to read the content of the file and handle errors
    const fileContents = rd.readScript(allocator, result) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        return jsc.JSValueMakeUndefined(context);
    };
    // Free the memory at the end of the block
    defer allocator.free(fileContents);

    // Create an exportObject in the JavaScript context
    const exportName = jsc.JSStringCreateWithUTF8CString("exports");
    const exportObject = jsc.JSObjectMake(context, null, null);
    jsc.JSObjectSetProperty(context, jsc.JSContextGetGlobalObject(context), exportName, exportObject, jsc.kJSPropertyAttributeNone, exception);

    // Create a JavaScript string and evaluate the script
    const jsCode = jsc.JSStringCreateWithUTF8CString(fileContents.ptr);
    const evalResult = jsc.JSEvaluateScript(context, jsCode, null, null, 0, exception);
    if (evalResult == null) {
        // Handle the error, log it, or return an appropriate value
        std.debug.print("Error evaluating script\n", .{});
        return jsc.JSValueMakeUndefined(context);
    }

    // Get the exported value from the JavaScript context
    const exportValue = jsc.JSObjectGetProperty(context, jsc.JSContextGetGlobalObject(context), exportName, exception);

    // Release the used memory
    jsc.JSStringRelease(jsCode);
    jsc.JSStringRelease(exportName);
    jsc.JSStringRelease(string);

    // Return the exported value
    return exportValue;
}

// Define a function to create a 'require' function in the JavaScript context
pub fn requireFunction(context: jsc.JSContextRef, globalObject: jsc.JSObjectRef) !void {
    // Create a JSString representing the name "require"
    const requireName = jsc.JSStringCreateWithUTF8CString("require");
    // Create a JavaScript function named 'require' with the callback set to the 'Require' function
    const requireFunctionName = jsc.JSObjectMakeFunctionWithCallback(context, requireName, Require);
    // Set the 'require' property on the global object to the created function
    jsc.JSObjectSetProperty(context, globalObject, requireName, requireFunctionName, jsc.kJSPropertyAttributeNone, null);
    // Release the used memory for the JSString
    jsc.JSStringRelease(requireName);
}
