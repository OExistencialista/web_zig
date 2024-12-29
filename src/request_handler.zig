const std = @import("std");
const net = std.net;
const Request = @import("root.zig").Request;
const Method = @import("root.zig").Method;
const View = @import("root.zig").View;
const db = @import("db_connector.zig");

pub const ServerConfig = struct {
    address: []const u8,
    port: u16,
    pagesPath: []const u8,
};

pub const Server = struct {
    allocator: std.mem.Allocator,
    port: u16,
    address: []const u8,
    listener: net.Server,
    pagesPath: []const u8,

    fn handleConnection(self: *Server) !void {
        const conn = try self.listener.accept();
        defer conn.stream.close();
        const reader = conn.stream.reader();
        var buffer: [4096]u8 = undefined;
        const read_result = try reader.read(buffer[0..]);

        const request = try parseRequest(buffer[0..read_result]);

        const response = try self.get_response(request);

        try conn.stream.writeAll(response);

        try self.handleConnection();
    }

    pub fn start(self: *Server) !void {
        std.debug.print("Server started on {s}:{d}\n", .{ self.address, self.port });

        std.debug.print("teste", .{});

        const db_config = db.db_conn_config{
            .alloc = self.allocator,
            .conn_string = "host=/run/postgresql dbname=teste user=pedro password=123456",
        };
        var db_conn = try db.db_connection.init(db_config);
        defer db_conn.deinit();
        const result = try db_conn.raw_query("SELECT * FROM testes");
        std.debug.print("result: {s}\n", .{result});

        try self.handleConnection();
    }

    pub fn deinit(self: *Server) void {
        std.debug.print("Server stopped on {s}:{d}\n", .{ self.address, self.port });
        self.listener.deinit();
    }

    const mimes = .{ .{ "html", "text/html" }, .{ "css", "text/css" }, .{ "map", "application/json" }, .{ "svg", "image/svg+xml" }, .{ "jpg", "image/jpg" }, .{ "png", "image/png" } };

    fn get_mime(path: []const u8) []const u8 {
        var split = std.mem.split(u8, path[0..], ".");
        _ = split.next().?;
        const extension = split.next().?;
        inline for (mimes) |entry| {
            if (std.mem.eql(u8, entry[0], extension)) {
                return entry[1];
            }
        }
        return "text/plain";
    }

    fn get_response(self: *Server, request: Request) ![]const u8 {
        switch (request.method) {
            Method.GET => {
                const page = "teste teste";
                return std.fmt.allocPrint(self.allocator, "HTTP/1.1 200 OK\r\nContent-Type: {s}\r\nContent-Length: {d}\r\n\r\n{s}", .{ get_mime(request.path), page.len, page });
            },
            else => {
                return error.MethodNotAllowed;
            },
        }
    }
};

pub fn init_server(config: ServerConfig, allocator: std.mem.Allocator) !Server {
    const address = try net.Address.parseIp(config.address, config.port);
    const listener = try address.listen(.{});
    return Server{
        .port = config.port,
        .address = config.address,
        .listener = listener,
        .allocator = allocator,
        .pagesPath = config.pagesPath,
    };
}

fn parseRequest(buffer: []const u8) !Request {
    var lines = std.mem.split(u8, buffer, "\r\n");
    lines.reset();
    const request_line = lines.next().?;

    var parts = std.mem.split(u8, request_line, " ");

    const method_string = parts.next().?;
    var path = parts.next().?;
    if (path.len <= 1) {
        path = "/index.html";
    }

    const version = parts.next().?;

    const headers = lines.next().?;
    const method = try method_map(method_string);
    return Request{
        .method = method,
        .path = path,
        .version = version,
        .headers = headers,
    };
}

fn method_map(method: []const u8) !Method {
    const methodMap = .{
        .{ "GET", Method.GET },
        .{ "POST", Method.POST },
        .{ "PUT", Method.PUT },
        .{ "DELETE", Method.DELETE },
        .{ "HEAD", Method.HEAD },
        .{ "OPTIONS", Method.OPTIONS },
        .{ "TRACE", Method.TRACE },
        .{ "CONNECT", Method.CONNECT },
    };
    inline for (methodMap) |entry| {
        if (std.mem.eql(u8, entry[0], method)) {
            return entry[1];
        }
    }
    return error.InvalidMethod;
}
