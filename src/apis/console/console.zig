const std = @import("std");
const jsc = @import("../../jsc/jsc.zig");

pub fn Log(context: jsc.JSContextRef, globalObject: jsc.JSObjectRef, thisObject: jsc.JSObjectRef, argumentsCount: usize, arguments: [*c]const jsc.JSValueRef, exception: [*c]jsc.JSValueRef) callconv(.C) jsc.JSValueRef {
    _ = thisObject;
    _ = globalObject;

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

    std.debug.print("\n", .{});
    return jsc.JSValueMakeUndefined(context);
}

pub fn consoleLogFunction(context: jsc.JSContextRef, globaObject: jsc.JSObjectRef) !void {
    const consoleName = jsc.JSStringCreateWithUTF8CString("console");
    const consoleObject = jsc.JSObjectMake(context, null, null);
    jsc.JSObjectSetProperty(context, globaObject, consoleName, consoleObject, jsc.kJSPropertyAttributeNone, null);

    const logFunctionName = jsc.JSStringCreateWithUTF8CString("log");

    const logFunctionObject = jsc.JSObjectMakeFunctionWithCallback(context, logFunctionName, Log);
    jsc.JSObjectSetProperty(context, consoleObject, logFunctionName, logFunctionObject, jsc.kJSPropertyAttributeNone, null);

    jsc.JSStringRelease(consoleName);
}
