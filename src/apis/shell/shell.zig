const std = @import("std");
const jsc = @import("../../jsc/jsc.zig");

const c = @cImport({
    @cInclude("stdlib.h");
});

pub const Shell = struct {
    const this = @This();
    const allocator = std.heap.page_allocator;

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

    pub fn Shell(
        ctx: jsc.JSContextRef,
        globalObject: jsc.JSObjectRef,
        thisObject: jsc.JSObjectRef,
        argumentsCount: usize,
        arguments: [*c]const jsc.JSValueRef,
        exception: [*c]jsc.JSValueRef,
    ) callconv(.C) jsc.JSValueRef {
        _ = exception;
        _ = globalObject;
        _ = thisObject;

        if (argumentsCount < 1) {
            std.debug.print("The function requires 1 arguments\n", .{});
            return jsc.JSValueMakeUndefined(ctx);
        }

        const command = this.converJSVToString(ctx, arguments[0]) catch |err| {
            std.debug.print("Err {}\n", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };

        _ = c.system(@as([*c]const u8, @ptrCast(command)));

        return jsc.JSValueMakeBoolean(ctx, true);
        //
        // return jsc.JSValueMakeFromJSONString(ctx, thisObject);
    }
};
