const std = @import("std");

const main = @import("root");
const cubyz = main.cubyz;
const user = main.user;

var commandTable: std.StringHashMapUnmanaged(*const fn(args: []u8, source: user.User) void) = .empty;

extern fn registerCommandImpl(
	name: [*]u8, nameLen: usize,
	description: [*]u8, descriptionLen: usize,
	usage: [*]u8, usageLen: usize
) void;

pub fn registerCommand(
	exec: *const fn(args: []u8, source: user.User) void,
	name: []const u8,
	description: []const u8,
	usage: []const u8,
) void {
	commandTable.put(main.allocator, name, exec) catch unreachable;
	registerCommandImpl(@constCast(name.ptr), name.len, @constCast(description.ptr), description.len, @constCast(usage.ptr), usage.len);
}

export fn executeCommand(namePtr: [*]u8, nameLen: usize, argPtr: [*]u8, argLen: usize, source: u32) void {
	const name = namePtr[0..nameLen];
	const args = argPtr[0..argLen];
	commandTable.get(name).?(args, .{.id = source});
}

pub fn deinit() void {
	commandTable.deinit(main.allocator);
}