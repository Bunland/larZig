// Import standard and jsc libraries
const std = @import("std");
const jsc = @import("../../jsc/jsc.zig");

const constants = @import("../../constants/constants.zig");

const Counter = struct { label: []const u8, count: usize };

// Define the Console structure
pub const Console = struct {
    const this = @This();

    const allocator = std.heap.page_allocator;
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();

    var counters = std.ArrayList(Counter).init(allocator);

    // Initialize the console
    pub fn init(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef) !void {
        // Create a console object and set it as a property of the global object
        const console = jsc.JSStringCreateWithUTF8CString("console");
        defer jsc.JSStringRelease(console);

        const consoleObject = jsc.JSObjectMake(ctx, null, null);
        jsc.JSObjectSetProperty(ctx, globalObject, console, consoleObject, jsc.kJSClassAttributeNone, null);

        // Create a custom function for the console
        try this.consoleCustomFunction(ctx, consoleObject, constants.log, this.Log);
        try this.consoleCustomFunction(ctx, consoleObject, constants.assert, this.Assert);
        try this.consoleCustomFunction(ctx, consoleObject, constants.clear, this.Clear);
        try this.consoleCustomFunction(ctx, consoleObject, constants.count, this.Count);
        try this.consoleCustomFunction(ctx, consoleObject, constants.countReset, this.CountReset);
        try this.consoleCustomFunction(ctx, consoleObject, constants.debug, this.Log);

        for (counters.items) |value| {
            allocator.free(value.label);
        }

        counters.deinit();

        // defer {
        //     const deinit_status = gpa.deinit();
        //     if (deinit_status == .leak) {
        //         std.debug.print("memory leak \n", .{});
        //     }
        // }
    }

    fn convertJSVToString(ctx: jsc.JSContextRef, argument: jsc.JSValueRef) ![]const u8 {
        // Get a copy of the JavaScript value as a string.
        const arg = jsc.JSValueToStringCopy(ctx, argument, null);
        defer jsc.JSStringRelease(arg);

        // Allocate a buffer for the UTF-8 string.
        const buffer = try allocator.alloc(u8, jsc.JSStringGetMaximumUTF8CStringSize(arg) - 1);
        // defer allocator.free(buffer);

        // Get the UTF-8 representation of the JavaScript string.
        const arglen = jsc.JSStringGetUTF8CString(arg, buffer.ptr, buffer.len);
        // const str = try allocator.alloc(u8, arglen);
        // std.mem.copy(u8, str, buffer[0..arglen]);

        // Return the dynamically allocated UTF-8 string.
        return buffer[0..arglen];
        // return str;
    }

    fn convertJSVToJson(ctx: jsc.JSContextRef, argument: jsc.JSValueRef) ![]const u8 {
        const jsonString = jsc.JSValueCreateJSONString(ctx, argument, 0, null);
        defer jsc.JSStringRelease(jsonString);

        const buffer = try allocator.alloc(u8, jsc.JSStringGetMaximumUTF8CStringSize(jsonString) - 1);
        // defer allocator.free(buffer);

        const arglen = jsc.JSStringGetUTF8CString(jsonString, buffer.ptr, buffer.len);
        // const str = try allocator.alloc(u8, arglen);
        // std.mem.copy(u8, str, buffer[0..arglen]);

        return buffer[0..arglen];
        // return str;
    }

    // Define a custom function for the console
    fn consoleCustomFunction(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef, functionName: []const u8, functionCallBack: jsc.JSObjectCallAsFunctionCallback) !void {
        // Create a function object and set it as a property of the global object
        const logFunctionName = jsc.JSStringCreateWithUTF8CString(functionName.ptr);
        defer jsc.JSStringRelease(logFunctionName);

        const logFunctionObject = jsc.JSObjectMakeFunctionWithCallback(ctx, logFunctionName, functionCallBack);
        jsc.JSObjectSetProperty(ctx, globalObject, logFunctionName, logFunctionObject, jsc.kJSPropertyAttributeNone, null);
    }

    // fn Log(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef, thisObject: jsc.JSObjectRef, argumentsCount: usize, arguments: [*c]const jsc.JSValueRef, exception: [*c]jsc.JSValueRef) callconv(.C) jsc.JSValueRef {
    //     _ = exception;

    //     _ = globalObject;
    //     _ = thisObject;
    //     // Loop through the arguments and print them
    //     var i: usize = 0;
    //     while (i < argumentsCount) : (i += 1) {
    //         // Check if the argument is an object and not null or undefined
    //         // if (jsc.JSValueIsObject(ctx, arguments[i]) and !jsc.JSValueIsNull(ctx, arguments[i]) and !jsc.JSValueIsUndefined(ctx, arguments[i])) {
    //         // const str = this.convertJSVToJson(ctx, arguments[i]) catch |err| {
    //         // std.debug.print("Error: {}\n", .{err});
    //         // return jsc.JSValueMakeUndefined(ctx);
    //         // };
    //         // defer allocator.free(str);
    //         // std.debug.print("{s} ", .{str});
    //         // } else {
    //         const str = this.convertJSVToString(ctx, arguments[i]) catch |err| {
    //             std.debug.print("Error: {}\n", .{err});
    //             return jsc.JSValueMakeUndefined(ctx);
    //         };
    //         defer allocator.free(str);
    //         std.debug.print("{s} ", .{str});
    //         // }
    //     }

    //     // Print a newline and return undefined
    //     std.debug.print("\n", .{});
    //     return jsc.JSValueMakeUndefined(ctx);
    // }

    fn Log(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef, thisObject: jsc.JSObjectRef, argumentsCount: usize, arguments: [*c]const jsc.JSValueRef, exception: [*c]jsc.JSValueRef) callconv(.C) jsc.JSValueRef {
        _ = exception;
        _ = globalObject;
        _ = thisObject;
        // Loop through the arguments and print them
        var i: usize = 0;
        while (i < argumentsCount) : (i += 1) {
            // Check if the argument is an object and not null or undefined
            if (jsc.JSValueIsObject(ctx, arguments[i]) and !jsc.JSValueIsNull(ctx, arguments[i]) and !jsc.JSValueIsUndefined(ctx, arguments[i])) {
                // Check if the object is a RegExp
                if (isRegExp(ctx, arguments[i])) {
                    const str = convertRegExpToString(ctx, arguments[i]) catch |err| {
                        std.debug.print("Error: {}\n", .{err});
                        return jsc.JSValueMakeUndefined(ctx);
                    };
                    defer allocator.free(str);
                    std.debug.print("{s} ", .{str});
                } else {
                    const str = this.convertJSVToJson(ctx, arguments[i]) catch |err| {
                        std.debug.print("Error: {}\n", .{err});
                        return jsc.JSValueMakeUndefined(ctx);
                    };
                    defer allocator.free(str);
                    std.debug.print("here: {s} ", .{str});
                }
            } else {
                const str = this.convertJSVToString(ctx, arguments[i]) catch |err| {
                    std.debug.print("Error: {}\n", .{err});
                    return jsc.JSValueMakeUndefined(ctx);
                };
                defer allocator.free(str);
                std.debug.print("{s} ", .{str});
            }
        }

        // Print a newline and return undefined
        std.debug.print("\n", .{});
        return jsc.JSValueMakeUndefined(ctx);
    }

    fn isRegExp(ctx: jsc.JSContextRef, value: jsc.JSValueRef) bool {
        const regexpString = jsc.JSStringCreateWithUTF8CString("RegExp");
        defer jsc.JSStringRelease(regexpString);
        const regexpConstructorValue = jsc.JSObjectGetProperty(ctx, jsc.JSContextGetGlobalObject(ctx), regexpString, null);
        const regexpConstructor = @as(*jsc.struct_OpaqueJSValue, @constCast(regexpConstructorValue));
        const isInstance = jsc.JSValueIsInstanceOfConstructor(ctx, value, regexpConstructor, null);
        return isInstance;
    }

    fn convertRegExpToString(ctx: jsc.JSContextRef, value: jsc.JSValueRef) ![]const u8 {
        const toStringString = jsc.JSStringCreateWithUTF8CString("toString");
        defer jsc.JSStringRelease(toStringString);
        const valueObject = jsc.JSValueToObject(ctx, value, null) orelse return error.CouldNotConvertValueToObject;
        const toStringFunctionValue = jsc.JSObjectGetProperty(ctx, valueObject, toStringString, null);
        const toStringFunction = @as(*jsc.struct_OpaqueJSValue, @constCast(toStringFunctionValue));
        const resultStringValue = jsc.JSObjectCallAsFunction(ctx, toStringFunction, valueObject, 0, null, null);
        const resultString = @as(*jsc.struct_OpaqueJSValue, @constCast(resultStringValue));
        return convertJSVToString(ctx, resultString);
    }

    fn Assert(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef, thisObject: jsc.JSObjectRef, argumentsCount: usize, arguments: [*c]const jsc.JSValueRef, exception: [*c]jsc.JSValueRef) callconv(.C) jsc.JSValueRef {
        _ = globalObject;
        _ = thisObject;
        _ = exception;

        if (argumentsCount < 2) {
            std.debug.print("Assertion failed\n", .{});
            return jsc.JSValueMakeUndefined(ctx);
        }

        const boolValue = jsc.JSValueToBoolean(ctx, arguments[0]);
        if (!boolValue) {
            const message = this.convertJSVToString(ctx, arguments[1]) catch |err| {
                std.debug.print("Error: {}\n", .{err});
                return jsc.JSValueMakeUndefined(ctx);
            };
            defer allocator.free(message);

            std.debug.print("Assertion failed: {s}\n", .{message});
            return jsc.JSValueMakeUndefined(ctx);
        }

        return jsc.JSValueMakeUndefined(ctx);
    }

    fn Clear(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef, thisObject: jsc.JSObjectRef, argumentsCount: usize, arguments: [*c]const jsc.JSValueRef, exception: [*c]jsc.JSValueRef) callconv(.C) jsc.JSValueRef {
        _ = globalObject;
        _ = thisObject;
        _ = argumentsCount;
        _ = arguments;
        _ = exception;

        std.debug.print("\x1B[H\x1B[2J", .{});
        return jsc.JSValueMakeUndefined(ctx);
    }

    fn Count(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef, thisObject: jsc.JSObjectRef, argumentsCount: usize, arguments: [*c]const jsc.JSValueRef, exception: [*c]jsc.JSValueRef) callconv(.C) jsc.JSValueRef {
        _ = globalObject;
        _ = thisObject;
        _ = exception;

        var i: usize = 0;

        var label: []const u8 = "default";
        // defer allocator.free(label);

        if (argumentsCount > 0) {
            label = this.convertJSVToString(ctx, arguments[0]) catch |err| {
                std.debug.print("Err : {}\n", .{err});
                return jsc.JSValueMakeUndefined(ctx);
            };
        }

        while (i < counters.items.len) : (i += 1) {
            if (std.mem.eql(u8, counters.items[i].label, label)) {
                counters.items[i].count += 1;
                std.debug.print("{s}: {}\n", .{ label, counters.items[i].count });
                return jsc.JSValueMakeUndefined(ctx);
            }
        }

        var new_counter = Counter{ .label = label, .count = 1 };
        counters.append(new_counter) catch |err| {
            std.debug.print("Err {}", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };
        std.debug.print("{s}: {}\n", .{ label, new_counter.count });
        return jsc.JSValueMakeUndefined(ctx);
    }

    fn CountReset(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef, thisObject: jsc.JSObjectRef, argumentsCount: usize, arguments: [*c]const jsc.JSValueRef, exception: [*c]jsc.JSValueRef) callconv(.C) jsc.JSValueRef {
        _ = globalObject;
        _ = thisObject;
        _ = exception;

        var i: usize = 0;
        var label: []const u8 = "default";
        defer allocator.free(label);

        if (argumentsCount > 0) {
            label = this.convertJSVToString(ctx, arguments[0]) catch |err| {
                std.debug.print("Err: {}\n", .{err});
                return jsc.JSValueMakeUndefined(ctx);
            };
        }

        while (i < counters.items.len) : (i += 1) {
            if (std.mem.eql(u8, counters.items[i].label, label)) {
                counters.items[i].count = 0;
                return jsc.JSValueMakeUndefined(ctx);
            } else {
                std.debug.print("Warning: Count for \'{s}\' does not exist\n", .{label});
                return jsc.JSValueMakeUndefined(ctx);
            }
        }
        return jsc.JSValueMakeUndefined(ctx);
    }
};
