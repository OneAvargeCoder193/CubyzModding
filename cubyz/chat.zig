const std = @import("std");

const cubyz = @import("cubyz");

pub fn showMessage(comptime fmt: []const u8, args: anytype) void {
	const msg = std.fmt.allocPrint(cubyz.allocator, fmt, args) catch unreachable;
	defer cubyz.allocator.free(msg);
	showMessageImpl(msg.ptr, @intCast(msg.len));
}

extern fn showMessageImpl(msgPtr: [*]const u8, msgLen: u32) void;