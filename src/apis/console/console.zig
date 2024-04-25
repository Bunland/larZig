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
        try this.consoleCustomFunction(ctx, consoleObject, constants.prompt, this.Prompt);

        defer counters.deinit();

        for (counters.items) |value| {
            defer allocator.free(value.label);
        }

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

    fn isInstanceOf(ctx: jsc.JSContextRef, value: jsc.JSValueRef, instanceType: [*]const u8) bool {
        const instanceTypeString = jsc.JSStringCreateWithUTF8CString(instanceType);
        defer jsc.JSStringRelease(instanceTypeString);
        const instanceTypeValue = jsc.JSObjectGetProperty(ctx, jsc.JSContextGetGlobalObject(ctx), instanceTypeString, null);
        const instanceTypeConstructor = @as(*jsc.struct_OpaqueJSValue, @constCast(instanceTypeValue).?);
        const isInstance = jsc.JSValueIsInstanceOfConstructor(ctx, value, instanceTypeConstructor, null);
        return isInstance;
    }

    fn Log(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef, thisObject: jsc.JSObjectRef, argumentsCount: usize, arguments: [*c]const jsc.JSValueRef, exception: [*c]jsc.JSValueRef) callconv(.C) jsc.JSValueRef {
        _ = exception;
        _ = globalObject;
        _ = thisObject;
        var i: usize = 0;
        while (i < argumentsCount) : (i += 1) {
            if (jsc.JSValueIsObject(ctx, arguments[i]) and !jsc.JSValueIsNull(ctx, arguments[i]) and !jsc.JSValueIsUndefined(ctx, arguments[i])) {
                if (isInstanceOf(ctx, arguments[i], "Error") or
                    isInstanceOf(ctx, arguments[i], "RegExp") or
                    isInstanceOf(ctx, arguments[i], "Date") or
                    isInstanceOf(ctx, arguments[i], "Function") or
                    isInstanceOf(ctx, arguments[i], "Promise") or
                    isInstanceOf(ctx, arguments[i], "Map") or
                    isInstanceOf(ctx, arguments[i], "Set") or
                    isInstanceOf(ctx, arguments[i], "Int32Array"))
                {
                    const str = convertJSVToString(ctx, arguments[i]) catch |err| {
                        std.debug.print("Err {}", .{err});
                        return jsc.JSValueMakeUndefined(ctx);
                    };
                    defer allocator.free(str);
                    std.debug.print("{s} ", .{str});
                } else {
                    const str = convertJSVToJson(ctx, arguments[i]) catch |err| {
                        std.debug.print("Err {}", .{err});
                        return jsc.JSValueMakeUndefined(ctx);
                    };
                    defer allocator.free(str);

                    std.debug.print("{s} ", .{str});
                }
            } else {
                const str = convertJSVToString(ctx, arguments[i]) catch |err| {
                    std.debug.print("Err {}", .{err});
                    return jsc.JSValueMakeUndefined(ctx);
                };
                defer allocator.free(str);
                std.debug.print("{s} ", .{str});
            }
        }
        std.debug.print("\n", .{});
        return jsc.JSValueMakeUndefined(ctx);
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

        if (argumentsCount > 0) {
            label = this.convertJSVToString(ctx, arguments[0]) catch |err| {
                std.debug.print("Err : {}\n", .{err});
                return jsc.JSValueMakeUndefined(ctx);
            };
        }

        while (i < counters.items.len) : (i += 1) {
            if (std.mem.eql(u8, counters.items[i].label, label)) {
                counters.items[i].count += 1;
                std.debug.print("{s}: {d}\n", .{ label, counters.items[i].count });
                return jsc.JSValueMakeUndefined(ctx);
            }
        }

        const new_counter = Counter{ .label = label, .count = 1 };
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
        // defer allocator.free(label);

        if (argumentsCount > 0) {
            label = this.convertJSVToString(ctx, arguments[0]) catch |err| {
                std.debug.print("Err: {}\n", .{err});
                return jsc.JSValueMakeUndefined(ctx);
            };
        }

        var found: bool = false;

        while (i < counters.items.len) : (i += 1) {
            if (std.mem.eql(u8, counters.items[i].label, label)) {
                counters.items[i].count = 0;
                found = true;
                break;
            }
        }

        if (!found) {
            std.debug.print("Warning: Count for \'{s}\' does not exist\n", .{label});
            return jsc.JSValueMakeUndefined(ctx);
        }

        return jsc.JSValueMakeUndefined(ctx);
    }

    fn Prompt(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef, thisObject: jsc.JSObjectRef, argumentsCount: usize, arguments: [*c]const jsc.JSValueRef, exception: [*c]jsc.JSValueRef) callconv(.C) jsc.JSValueRef {
        _ = exception;
        _ = globalObject;
        _ = thisObject;
        // _ = argumentsCount;
        // _ = arguments;

        if (argumentsCount < 1) {
            std.debug.print("The function requires 1 argument\n", .{});
            return jsc.JSValueMakeUndefined(ctx);
        }

        const message = this.convertJSVToString(ctx, arguments[0]) catch |err| {
            std.debug.print("Err {}\n", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };

        std.debug.print("{s}", .{message});

        var stdIn = std.io.getStdIn().reader();
        var buffer: [4096]u8 = undefined;
        const bytes_entered = stdIn.read(&buffer) catch |err| {
            std.debug.print("Err: {}\n", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };
        const entered = buffer[0..bytes_entered];
        const str = std.mem.trim(u8, entered, " \r\n\t");

        const str_copy = allocator.alloc(u8, str.len) catch |err| {
            std.debug.print("Err: {}\n", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };
        defer allocator.free(str_copy);

        @memcpy(str_copy, str);


        const str_final = jsc.JSStringCreateWithUTF8CString(str_copy.ptr);
        defer jsc.JSStringRelease(str_final);

        return jsc.JSValueMakeString(ctx, str_final);
    }
};
