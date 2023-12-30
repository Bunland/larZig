// Import standard and jsc libraries
const std = @import("std");
const jsc = @import("../../jsc/jsc.zig");

// Define the Console structure
pub const Console = struct {
    const this = @This();

    // Initialize the console
    pub fn init(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef) !void {
        // Create a console object and set it as a property of the global object
        const console = jsc.JSStringCreateWithUTF8CString("console");
        defer jsc.JSStringRelease(console);

        const consoleObject = jsc.JSObjectMake(ctx, null, null);
        jsc.JSObjectSetProperty(ctx, globalObject, console, consoleObject, jsc.kJSClassAttributeNone, null);

        // Create a custom function for the console
        try this.consoleCustomFunction(ctx, consoleObject, "log", this.Log);
        try this.consoleCustomFunction(ctx, consoleObject, "print", this.Log);

    }

    // Define a custom function for the console
    fn consoleCustomFunction(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef, functionName: []const u8, functionCallBack: jsc.JSObjectCallAsFunctionCallback) !void {
        // Create a function object and set it as a property of the global object
        const logFunctionName = jsc.JSStringCreateWithUTF8CString(functionName.ptr);
        defer jsc.JSStringRelease(logFunctionName);

        const logFunctionObject = jsc.JSObjectMakeFunctionWithCallback(ctx, logFunctionName, functionCallBack);
        jsc.JSObjectSetProperty(ctx, globalObject, logFunctionName, logFunctionObject, jsc.kJSPropertyAttributeNone, null);
    }

    // Define the Log function
    fn Log(context: jsc.JSContextRef, globalObject: jsc.JSObjectRef, thisObject: jsc.JSObjectRef, argumentsCount: usize, arguments: [*c]const jsc.JSValueRef, exception: [*c]jsc.JSValueRef) callconv(.C) jsc.JSValueRef {
        _ = globalObject;
        _ = thisObject;
        // Loop through the arguments and print them
        const allocator = std.heap.page_allocator;
        var i: usize = 0;
        while (i < argumentsCount) : (i += 1) {
            const string = jsc.JSValueToStringCopy(context, arguments[i], exception);
            var buffer = allocator.alloc(u8, jsc.JSStringGetMaximumUTF8CStringSize(string)) catch |err| {
                std.debug.print("Error: {}\n", .{err});
                return jsc.JSValueMakeUndefined(context);
            };
            defer allocator.free(buffer);
            const string_length = jsc.JSStringGetUTF8CString(string, buffer.ptr, buffer.len);
            std.debug.print("{s}", .{buffer[0..string_length]});
            jsc.JSStringRelease(string);
        }

        // Print a newline and return undefined
        std.debug.print("\n", .{});
        return jsc.JSValueMakeUndefined(context);
    }
};