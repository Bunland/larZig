const std = @import("std");
const jsc = @import("../../jsc/jsc.zig");

pub const Fs = struct {
    const this = @This();
    const allocator = std.heap.page_allocator;

    /// Converts a JavaScript value to a UTF-8 string.
    ///
    /// ## Parameters
    /// - `ctx`: The JavaScript context.
    /// - `argument`: The JavaScript value to be converted to a string.
    /// ## Returns
    /// Returns a dynamically allocated UTF-8 string.
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

    /// Writes content to a file.
    ///
    /// ## Parameters
    /// - `ctx`: The JavaScript context.
    /// - `globalObject`: The global object associated with the script.
    /// - `thisObject`: The JavaScript object representing the current instance.
    /// - `argumentsCount`: The number of arguments passed to the function.
    /// - `arguments`: An array of JavaScript values representing the function arguments.
    /// - `exception`: An array to store any exception information.
    /// ## Returns
    /// Returns a JavaScript boolean value indicating the success of the operation.
    pub fn writeFile(
        ctx: jsc.JSContextRef,
        globalObject: jsc.JSObjectRef,
        thisObject: jsc.JSObjectRef,
        argumentsCount: usize,
        arguments: [*c]const jsc.JSValueRef,
        exception: [*c]jsc.JSValueRef,
    ) callconv(.C) jsc.JSValueRef {
        _ = exception;
        // Ignore globalObject and thisObject parameters.
        _ = globalObject;
        _ = thisObject;

        // Check if the required number of arguments is provided.
        if (argumentsCount < 2) {
            std.debug.print("The function requires 2 arguments\n", .{});
            return jsc.JSValueMakeUndefined(ctx);
        }

        // Extract and convert the file name from the first argument.
        const fileName = this.converJSVToString(ctx, arguments[0]) catch |err| {
            std.debug.print("{}\n", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };
        defer allocator.free(fileName);

        // Extract and convert the content from the second argument.
        const content = this.converJSVToString(ctx, arguments[1]) catch |err| {
            std.debug.print("{}\n", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };
        defer allocator.free(content);

        // // Create a file in the current working directory for reading.
        const file = std.fs.cwd().createFile(fileName, .{ .read = true }) catch |err| {
            std.debug.print("Could not create file.\n Err: {}\n", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };

        defer file.close();

        // Write the content to the file.
        file.writeAll(content) catch |err| {
            std.debug.print("Could not write the file.\n Err: {}", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };

        // Return success as a boolean value.
        return jsc.JSValueMakeBoolean(ctx, true);
    }

    /// Reads content from a file.
    ///
    /// ## Parameters
    /// - `ctx`: The JavaScript context.
    /// - `globalObject`: The global object associated with the script.
    /// - `thisObject`: The JavaScript object representing the current instance.
    /// - `argumentsCount`: The number of arguments passed to the function.
    /// - `arguments`: An array of JavaScript values representing the function arguments.
    /// - `exception`: An array to store any exception information.
    /// ## Returns
    /// Returns a JavaScript string containing the content of the file.
    pub fn readFile(
        ctx: jsc.JSContextRef,
        globalObject: jsc.JSObjectRef,
        thisObject: jsc.JSObjectRef,
        argumentsCount: usize,
        arguments: [*c]const jsc.JSValueRef,
        exception: [*c]jsc.JSValueRef,
    ) callconv(.C) jsc.JSValueRef {
        _ = exception;
        // Ignore globalObject and thisObject parameters.
        _ = globalObject;
        _ = thisObject;

        // Check if the required number of arguments is provided.
        if (argumentsCount < 1) {
            std.debug.print("The function requires 1 argument\n", .{});
            return jsc.JSValueMakeUndefined(ctx);
        }

        // Extract and convert the file name from the first argument.
        const filename = converJSVToString(ctx, arguments[0]) catch |err| {
            std.debug.print("Error: {}\n", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };
        defer allocator.free(filename);

        // Read the content of the file and allocate a buffer.
        const file = std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize)) catch |err| {
            std.debug.print("Could not open the file Err: {}\n", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };
        defer allocator.free(file);

        // Allocate a buffer for the content.
        const str = allocator.alloc(u8, file.len + 1) catch |err| {
            std.debug.print("Err: {}\n", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };

        defer allocator.free(str);

        // Copy the file content to the buffer and null-terminate.
        // @memcpy(str, file);

        std.mem.copyForwards(u8, str, file);

        str[file.len] = 0;

        // Create a JavaScript string from the buffer.
        const resultContent = jsc.JSStringCreateWithUTF8CString(str.ptr);
        defer jsc.JSStringRelease(resultContent);

        // Return the JavaScript string containing the file content.
        return jsc.JSValueMakeString(ctx, resultContent);
    }

    /// Removes a file.
    ///
    /// ## Parameters
    /// - `ctx`: The JavaScript context.
    /// - `globalObject`: The global object associated with the script.
    /// - `thisObject`: The JavaScript object representing the current instance.
    /// - `argumentsCount`: The number of arguments passed to the function.
    /// - `arguments`: An array of JavaScript values representing the function arguments.
    /// - `exception`: An array to store any exception information.
    /// ## Returns
    /// Returns a JavaScript boolean value indicating the success of the operation.
    pub fn removeFile(
        ctx: jsc.JSContextRef,
        globalObject: jsc.JSObjectRef,
        thisObject: jsc.JSObjectRef,
        argumentsCount: usize,
        arguments: [*c]const jsc.JSValueRef,
        exception: [*c]jsc.JSValueRef,
    ) callconv(.C) jsc.JSValueRef {
        _ = exception;
        // Ignore globalObject and thisObject parameters.
        _ = globalObject;
        _ = thisObject;

        // Check if the required number of arguments is provided.
        if (argumentsCount < 1) {
            std.debug.print("The function requires 1 argument\n", .{});
            return jsc.JSValueMakeUndefined(ctx);
        }

        // Extract and convert the file name from the first argument.
        const filename = converJSVToString(ctx, arguments[0]) catch |err| {
            std.debug.print("Error: {}\n", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };

        // Defer freeing the filename.
        defer allocator.free(filename);

        // Attempt to delete the file.
        std.fs.cwd().deleteFile(filename) catch |err| {
            // Handle the case where the file is not found.
            if (err == error.FileNotFound) {
                // std.debug.print("Could not delete file Err: {}\n", .{err});
                return jsc.JSValueMakeBoolean(ctx, false);
            }
        };

        // Return success as a boolean value.
        return jsc.JSValueMakeBoolean(ctx, true);
    }

    /// Checks if a file exists.
    ///
    /// ## Parameters
    /// - `ctx`: The JavaScript context.
    /// - `globalObject`: The global object associated with the script.
    /// - `thisObject`: The JavaScript object representing the current instance.
    /// - `argumentsCount`: The number of arguments passed to the function.
    /// - `arguments`: An array of JavaScript values representing the function arguments.
    /// - `exception`: An array to store any exception information.
    /// ## Returns
    /// Returns a JavaScript boolean value indicating whether the file exists.
    pub fn existsFile(
        ctx: jsc.JSContextRef,
        globalObject: jsc.JSObjectRef,
        thisObject: jsc.JSObjectRef,
        argumentsCount: usize,
        arguments: [*c]const jsc.JSValueRef,
        exception: [*c]jsc.JSValueRef,
    ) callconv(.C) jsc.JSValueRef {
        _ = exception;
        // Ignore globalObject and thisObject parameters.
        _ = globalObject;
        _ = thisObject;

        // Check if the required number of arguments is provided.
        if (argumentsCount < 1) {
            std.debug.print("The function requires 1 argument\n", .{});
            return jsc.JSValueMakeUndefined(ctx);
        }

        // Extract and convert the file name from the first argument.
        const filename = converJSVToString(ctx, arguments[0]) catch |err| {
            std.debug.print("Error: {}\n", .{err});
            return jsc.JSValueMakeUndefined(ctx);
        };

        // Defer freeing the filename.
        defer allocator.free(filename);

        // Check if the file exists by attempting to access it in read-only mode.
        std.fs.cwd().access(filename, .{ .mode = .read_only }) catch |err| {
            // Handle the case where the file is not found.
            if (err == error.FileNotFound) {
                // std.debug.print("Err {}", .{err});
                return jsc.JSValueMakeBoolean(ctx, false);
            }
        };

        // Return success as a boolean value.
        return jsc.JSValueMakeBoolean(ctx, true);
    }
};
