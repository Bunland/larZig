const std = @import("std");
const jsc = @import("../jsc/jsc.zig");
const fng = @import("../function_generator/function_generator.zig");

const mts = @import("../apis/maths/maths.zig");
const log = @import("../apis/console/console.zig");
const req = @import("../apis/require/require.zig");

///*
//* Registers APIs within the provided JavaScript context and global object.
//*
//* @param context       The JavaScript context where the APIs will be registered.
//* @param globalObject  The global object to which the APIs will be added.
//*
//* @return              There is no explicit return value.
//*/

pub fn Apis(context: jsc.JSContextRef, globalObject: jsc.JSObjectRef) !void {
    // Attempts to create a custom function "Add" and add it to the provided context and global object
    try fng.createCustomFunction(context, globalObject, "Add", mts.Add);
    try fng.createCustomFunction(context, globalObject, "Mult", mts.Mult);

    try log.consoleLogFunction(context, globalObject);
    try req.requireFunction(context, globalObject);
}
