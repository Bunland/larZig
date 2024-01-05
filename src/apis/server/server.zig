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

    var server_fd: i32 = undefined;
    var new_socket: i32 = undefined;
    var address = c.sockaddr_in{ .sin_family = c.AF_INET, .sin_addr = c.in_addr{ .s_addr = c.INADDR_ANY }, .sin_zero = [_]u8{0} ** 8 };
    var addrlen: c.socklen_t = @sizeOf(c.sockaddr_in);

    pub fn setPort(port: u16) void {
        address.sin_port = c.htons(port);
    }

    pub fn config() void {
        server_fd = c.socket(c.AF_INET, c.SOCK_STREAM, 0);
        if (server_fd == 0) {
            std.debug.print("Failed to create socket\n", .{});
            // return error.SocketCreationFailed;
        }

        if (c.bind(server_fd, @as(*c.sockaddr, @ptrCast(&address)), addrlen) < 0) {
            std.debug.print("Failed to bind\n", .{});
            // return error.BindFailed;
        }

        if (c.listen(server_fd, 10) < 0) {
            std.debug.print("Failed to listen\n", .{});
            // return error.ListenFailed;
        }
    }

    pub fn myHandler(n_socket: i32) void {
        std.debug.print("estoy aca\n", .{});

        var buffer: [2048]u8 = undefined;
        const bytesRead = c.read(n_socket, &buffer, buffer.len);
        if (bytesRead < 0) {
            std.debug.print("Failed to read\n", .{});
            return;
        }
        std.debug.print("Received: {s}\n", .{std.mem.sliceTo(buffer[0..@as(usize, @intCast(bytesRead))], 0)});

        const response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nHello, world!\n";
        _ = c.write(n_socket, response, @as(usize, response.len));
        std.debug.print("Message sent\n", .{});
        _ = c.close(n_socket);
    }

    pub fn handleRequest(handler: *const fn (i32) void) void {
        while (true) {
            new_socket = c.accept(server_fd, @as(*c.sockaddr, @ptrCast(&address)), &addrlen);
            if (new_socket < 0) {
                std.debug.print("Error AcceptFiled", .{});
                // return error.AcceptFiled;
            }
            handler(new_socket);
        }
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

    pub fn start(ctx: jsc.JSContextRef, globalObject: jsc.JSObjectRef, thisObject: jsc.JSObjectRef, argumentsCount: usize, arguments: [*c]const jsc.JSValueRef, execption: [*c]jsc.JSValueRef) callconv(.C) jsc.JSValueRef {
        _ = arguments;
        _ = globalObject;
        _ = thisObject;
        _ = execption;

        if (argumentsCount < 1) {
            std.debug.print("The function requires 1 arguments\n", .{});
            return jsc.JSValueMakeUndefined(ctx);
        }

        this.setPort(4000);
        this.config();
        this.handleRequest(this.myHandler);

        const hello = jsc.JSStringCreateWithUTF8CString("Hello Server");
        defer jsc.JSStringRelease(hello);
        return jsc.JSValueMakeString(ctx, hello);
    }
};
