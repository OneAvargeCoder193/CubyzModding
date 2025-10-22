const std = @import("std");

const main = @import("root");
const cubyz = main.cubyz;
const user = main.user;

var commandTable: std.StringHashMapUnmanaged(*const fn(args: []u8, source: user.User) void) = .empty;

extern fn registerCommandImpl(
	name: [*]u8, nameLen: u32,
	description: [*]u8, descriptionLen: u32,
	usage: [*]u8, usageLen: u32
) void;

pub fn registerCommand(
	exec: *const fn(args: []u8, source: user.User) void,
	name: []const u8,
	description: []const u8,
	usage: []const u8,
) void {
	commandTable.put(cubyz.allocator, name, exec) catch unreachable;
	registerCommandImpl(@constCast(name.ptr), @intCast(name.len), @constCast(description.ptr), @intCast(description.len), @constCast(usage.ptr), @intCast(usage.len));
}

export fn executeCommand(namePtr: [*]u8, nameLen: u32, argPtr: [*]u8, argLen: u32, source: u32) void {
	const name = namePtr[0..nameLen];
	const args = argPtr[0..argLen];
	commandTable.get(name).?(args, .{.id = source});
}

pub fn deinit() void {
	commandTable.deinit(cubyz.allocator);
}