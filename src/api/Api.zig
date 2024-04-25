// Import standard, jsc, Maths, and Console libraries
const std = @import("std");
const jsc = @import("../jsc/jsc.zig");
const Maths = @import("../apis//maths/maths.zig").Maths;
const Console = @import("../apis/console/console.zig").Console;

const Fs = @import("../apis/fs/fs.zig").Fs;
const Server = @import("../apis//server/server.zig").Server;
const constants = @import("../constants/constants.zig");
const Shell = @import("../apis/shell/shell.zig").Shell;

// Define the Apis structure
pub const Apis = struct {
    const this = @This();

    // Initialize the APIs
    pub fn init(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef) !void {
        try this.LarApis(ctx, globalObject);
    }

    // Define the LarApis function
    fn LarApis(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef) !void {
        _ = this;
        const larStr = jsc.JSStringCreateWithUTF8CString(constants.lar);
        defer jsc.JSStringRelease(larStr);

        const larGlobalObject = jsc.JSObjectMake(ctx, null, null);
        jsc.JSObjectSetProperty(ctx, globalObject, larStr, larGlobalObject, jsc.kJSClassAttributeNone, null);

        // Initialize the Console
        try Console.init(ctx, globalObject);

        // Create a custom function
        try this.larCustomFunction(ctx, globalObject, "Add", Maths.Add);

        // Server
        // try this.larCustomFunction(ctx, larGlobalObject, "Server", Server.start);

        // Fs
        try this.larCustomFunction(ctx, larGlobalObject, constants.writeFile, Fs.writeFile);
        try this.larCustomFunction(ctx, larGlobalObject, constants.readFile, Fs.readFile);
        try this.larCustomFunction(ctx, larGlobalObject, constants.removeFile, Fs.removeFile);
        try this.larCustomFunction(ctx, larGlobalObject, constants.existsFile, Fs.existsFile);

        // Shell
        try this.larCustomFunction(ctx, larGlobalObject, constants.shell, Shell.Shell);
    }

    // Define a custom function
    fn larCustomFunction(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef, functionName: []const u8, functionCallBack: jsc.JSObjectCallAsFunctionCallback) !void {
        const functionString = jsc.JSStringCreateWithUTF8CString(functionName.ptr);
        defer jsc.JSStringRelease(functionString);

        const functionObject = jsc.JSObjectMakeFunctionWithCallback(ctx, functionString, functionCallBack);
        jsc.JSObjectSetProperty(ctx, globalObject, functionString, functionObject, jsc.kJSPropertyAttributeNone, null);
    }
};
