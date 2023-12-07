const std = @import("std");

pub fn readScript(allocator: std.mem.Allocator, filename: []const u8) ![]const u8 {
    // Reading the file content
    const content = try std.fs.cwd().readFileAllocOptions(allocator, filename, std.math.maxInt(usize), null, 1, 0);

    // Allocating memory for the content + null terminator
    const buffer = try allocator.alloc(u8, content.len + 1);

    // Copying the file content to the buffer
    std.mem.copy(u8, buffer[0..content.len], content);

    // Appending null-terminator
    buffer[content.len] = 0;

    // Returning the null-terminated UTF-8 encoded string
    return buffer;
}
