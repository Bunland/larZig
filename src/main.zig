// Import standard, jsc, Apis, and Interpreter libraries
const std = @import("std");
const print = std.debug.print;
const jsc = @import("./jsc/jsc.zig");
const Apis = @import("./api/Api.zig").Apis;
const Interpreter = @import("./interpreter/interpreter.zig").Interpreter;

// Define the main function
pub fn main() !void {
    // Create a global context
    const context = jsc.JSGlobalContextCreate(null);
    const globalObject = jsc.JSContextGetGlobalObject(context);
    const allocator = std.heap.page_allocator;

    // Initialize the APIs
    try Apis.init(context, globalObject);

    // Get the command line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Check if there are enough arguments
    if (args.len < 3) {
        std.debug.print("Insufficient arguments\n", .{});
        return;
    }

    // If the first argument is "run" and the second argument is not empty, initialize the interpreter
    if (std.mem.eql(u8, args[1], "run") and args[2].len > 0) {
        try Interpreter.init(allocator, args[2], context);
    }

    // Release the global context
    jsc.JSGlobalContextRelease(context);
}