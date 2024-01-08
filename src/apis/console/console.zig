// Import standard and jsc libraries
const std = @import("std");
const jsc = @import("../../jsc/jsc.zig");

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
        try this.consoleCustomFunction(ctx, consoleObject, "log", this.Log);
        try this.consoleCustomFunction(ctx, consoleObject, "print", this.Log);
        try this.consoleCustomFunction(ctx, consoleObject, "assert", this.Assert);
        try this.consoleCustomFunction(ctx, consoleObject, "clear", this.Clear);
        try this.consoleCustomFunction(ctx, consoleObject, "count", this.Count);
        try this.consoleCustomFunction(ctx, consoleObject, "countReset", this.CountReset);

        defer counters.deinit();

        // for (counters.items) |value| {
        //     allocator.free(value.label);
        // }

        // defer {
        //     const deinit_status = gpa.deinit();
        //     if (deinit_status == .leak) {
        //         std.debug.print("memory leak \n", .{});
        //     }
        // }
    }

    fn converJSVToString(ctx: jsc.JSContextRef, argument: jsc.JSValueRef) ![]const u8 {
        // Get a copy of the JavaScript value as a string.
        const arg = jsc.JSValueToStringCopy(ctx, argument, null);
        defer jsc.JSStringRelease(arg);

        // Allocate a buffer for the UTF-8 string.
        const buffer = try allocator.alloc(u8, jsc.JSStringGetMaximumUTF8CStringSize(arg) - 1);
        // defer allocator.free(buffer);

        // Get the UTF-8 representation of the JavaScript string.
        const argLen = jsc.JSStringGetUTF8CString(arg, buffer.ptr, buffer.len);

        const str = try allocator.alloc(u8, argLen);
        std.mem.copy(u8, str, buffer[0..argLen]);

        // Return the dynamically allocated UTF-8 string.
        // return buffer[0..argLen];
        return str;
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
            const message = this.converJSVToString(ctx, arguments[1]) catch |err| {
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
        defer allocator.free(label);

        if (argumentsCount > 0) {
            label = this.converJSVToString(ctx, arguments[0]) catch |err| {
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
            label = this.converJSVToString(ctx, arguments[0]) catch |err| {
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
