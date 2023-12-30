const std = @import("std");
const jsc = @import("../../jsc/jsc.zig");

const c = @cImport({
    @cInclude("arpa/inet.h");
    @cInclude("unistd.h");
});

const ServerData = struct {
    id: u64,
    port: u16,
};

pub const Server = struct {
    const this = @This();
    const allocator = std.heap.page_allocator;

    pub fn parseJson(jsonString: []const u8) !ServerData {
        const result = try std.json.parseFromSlice(ServerData, allocator, jsonString, .{});
        return result;
    }

    fn converJSVToString(
        ctx: jsc.JSContextRef,
        argument: jsc.JSValueRef,
    ) ![]const u8 {
        // Get a copy of the JavaScript value as a string.
        const arg = jsc.JSValueToStringCopy(ctx, argument, null);
        defer jsc.JSStringRelease(arg);

        // Allocate a buffer for the UTF-8 string.
        const buffer = try allocator.alloc(u8, jsc.JSStringGetMaximumUTF8CStringSize(arg));

        // Get the UTF-8 representation of the JavaScript string.
        const argLen = jsc.JSStringGetUTF8CString(arg, buffer.ptr, buffer.len);

        // Return the dynamically allocated UTF-8 string.
        return buffer[0 .. argLen - 1];
    }

    pub fn server(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef, thisObject: jsc.JSObjectRef, argumentsCount: usize, arguments: [*c]const jsc.JSValueRef, execption: [*c]jsc.JSValueRef) callconv(.C) jsc.JSValueRef {
        _ = globalObject;
        _ = thisObject;
        _ = execption;

        if (argumentsCount < 1) {
            std.debug.print("THe function requires 1 arguments\n", .{});
            return jsc.JSValueMakeUndefined(ctx);
        }

        const obj = this.converJSVToString(ctx, arguments[0]) catch |err| {
            std.debug.print("Error: {}\n", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };
        defer allocator.free(obj);

        const value = std.json.parseFromSlice(ServerData, allocator, obj, .{}) catch |err| {
            std.debug.print("{any}", .{@TypeOf(err)});
            return undefined;
        };
        defer value.deinit();

        // const res = std.json.parseFromSlice(u8, allocator, obj, .{}) catch |err| {
        //     if (err == error.UnexpectedToken) {
        //         return jsc.JSValueMakeUndefined(ctx);
        //     }
        // };

        // const res = std.json.parseFromSlice(u8, allocator, obj, .{}) catch |err| {
        //     if (err == error.saom) {
        //     }
        // };

        std.debug.print("Here: {}\n", .{value.value.id});
        std.debug.print("Here: {}\n", .{value.value.port});

        const hello = jsc.JSStringCreateWithUTF8CString("Hello Server");
        defer jsc.JSStringRelease(hello);

        return jsc.JSValueMakeString(ctx, hello);
    }
};
