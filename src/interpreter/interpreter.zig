const std = @import("std");
const jsc = @import("../jsc/jsc.zig");
const rd = @import("../utils/readScript.zig");

//*
//* Reads the content of a file and returns it as a null-terminated UTF-8 encoded string.
//*
//* @param allocator  The memory allocator for allocating memory.
//* @param filename   The name of the file to be read.
//*
//* @return           A null-terminated UTF-8 encoded string containing the file content.
//*/
// fn readScript(allocator: std.mem.Allocator, filename: []const u8) ![]const u8 {
//     // Reading the file content
//     const content = try std.fs.cwd().readFileAllocOptions(allocator, filename, std.math.maxInt(usize), null, 1, 0);

//     // Allocating memory for the content + null terminator
//     const buffer = try allocator.alloc(u8, content.len + 1);

//     // Copying the file content to the buffer
//     std.mem.copy(u8, buffer[0..content.len], content);

//     // Appending null-terminator
//     buffer[content.len] = 0;

//     // Returning the null-terminated UTF-8 encoded string
//     return buffer;
// }

///*
//* Interprets and executes a JavaScript file within a provided JavaScript context.
//*
//* @param allocator The memory allocator for allocating memory.
//* @param filename  The name of the JavaScript file to be interpreted.
//* @param context   The JavaScript context in which the file will be evaluated.
//*
//* @return          There is no explicit return value.
//*/
pub fn interpreter(allocator: std.mem.Allocator, filename: []const u8, context: jsc.JSContextRef) !void {

    // Reading the file content
    const fileContents = try rd.readScript(allocator, filename);

    // Freeing allocated memory for file content at the end of the scope
    defer allocator.free(fileContents);

    // Creating a JavaScript string from the file content
    const jsCode = jsc.JSStringCreateWithUTF8CString(fileContents.ptr);

    // Evaluating the JavaScript code
    const result = jsc.JSEvaluateScript(context, jsCode, null, null, 0, null);

    _ = result;

    // // Converting the result to a string representation
    // const jsString = jsc.JSValueToStringCopy(context, result, null);

    // // Allocating memory for the string buffer
    // var buffer = try allocator.alloc(u8, jsc.JSStringGetMaximumUTF8CStringSize(jsString));

    // // Freeing the buffer memory at the end of the scope
    // defer allocator.free(buffer);

    // // Getting the length of the string
    // const string_length = jsc.JSStringGetUTF8CString(jsString, buffer.ptr, buffer.len);

    // // Slicing the buffer to get the string
    // const string = buffer[0..string_length];

    // // Printing the string
    // std.debug.print("{s}\n", .{string});

    // // Releasing the JavaScript string
    // jsc.JSStringRelease(jsString);
}
