// main.zig
const std = @import("std");
const print = std.debug.print;

const jsc = @import("./jsc/jsc.zig");
const c = @import("./c/c.zig");
const api = @import("./api/api.zig");
const inter = @import("./interpreter/interpreter.zig");

pub fn main() !void {
    const context = jsc.JSGlobalContextCreate(null);
    const globalObject = jsc.JSContextGetGlobalObject(context);
    const allocator = std.heap.page_allocator;

    try api.Apis(context, globalObject);

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("Insufficient arguments\n", .{});
        return;
    }

    if (std.mem.eql(u8, args[1], "run") and args[2].len > 0) {
        // std.debug.print("{s}\n", .{args[2]});
        try inter.interpreter(allocator, args[2], context);
    }

    jsc.JSGlobalContextRelease(context);
}
