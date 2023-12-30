const std = @import("std");
const jsc = @import("../../jsc/jsc.zig");

pub const Maths = struct {
    const this = @This();

    pub fn Add(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef, thisObject: jsc.JSObjectRef, argumentsCount: usize, arguments: [*c]const jsc.JSValueRef, execption: [*c]jsc.JSValueRef) callconv(.C) jsc.JSValueRef {
        _ = globalObject;
        _ = thisObject;
        _ = execption;

        if (argumentsCount < 2) {
            std.debug.print("The function requires 2 arguments\n", .{});
            return jsc.JSValueMakeUndefined(ctx);
        }

        var numa = jsc.JSValueToNumber(ctx, arguments[0], null);
        var numb = jsc.JSValueToNumber(ctx, arguments[1], null);
        var result = numa + numb;
        return jsc.JSValueMakeNumber(ctx, result);
    }
};
