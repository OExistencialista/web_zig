const std = @import("std");
const net = std.net;
const rh = @import("request_handler.zig");
const addressString = "127.0.0.1";
const port = 8080;
        
pub fn main() !void {   
    const alloc = std.heap.page_allocator;
    var server = try rh.init_server(.{
        .address = addressString,
        .port = port,
        .pagesPath = "/pages"
    }, alloc);
    try server.start();
    server.deinit();
    }


