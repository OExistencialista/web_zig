const view = @import("../root.zig").View;
const allocator = @import("../root.zig").alloc;
const std = @import("std");
const dir = "home";

const homeControler = struct {


fn get_page() ![]u8 {


    const currentDir = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(currentDir);

    const filePath = try std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ currentDir, dir, path });

    std.debug.print("{s}\n", .{filePath});
    const file = try std.fs.openFileAbsolute(filePath, .{});
    defer file.close();
    const file_info = try file.stat();
    const file_size = file_info.size;
    const file_buffer = try allocator.alloc(u7, file_size);
    _ = try file.readAll(file_buffer);
    return file_buffer;
}




};