const std = @import("std");
const net = std.net;
pub const alloc = std.heap.page_allocator;

pub const Server = struct {
    allocator: std.mem.Allocator,
    port: u16,
    address: []const u8,
    listener: net.Server,
    pagesPath: []const u8,
};

pub const Request = struct {
    method: Method,
    path: []const u8,
    version: []const u8,
    headers: []const u8,
};

pub const Method = enum {
    GET,
    POST,
    PUT,
    DELETE,
    HEAD,
    OPTIONS,
    TRACE,
    CONNECT,
};
pub const View = struct {
    page : []u8,
    page_len : u32,
    model :  std.json.Value

};



