const std = @import("std");

const cubyz = @import("cubyz");
const user = cubyz.user;

pub fn registerCommand(
	comptime exec: fn(args: []u8, source: user.User) void,
	comptime name: []const u8,
	comptime description: []const u8,
	comptime usage: []const u8,
) void {
	const funcName = cubyz.callback.registerCallback(struct{
		fn wrap(argPtr: [*]u8, argLen: u32, source: u32) callconv(.{ .wasm_mvp = .{} }) void {
			exec(argPtr[0..argLen], .{.id = source});
		}
	}.wrap);
	registerCommandImpl(funcName.ptr, funcName.len, name.ptr, name.len, description.ptr, description.len, usage.ptr, usage.len);
}

extern fn registerCommandImpl(
	funcName: [*]const u8, funcNameLen: u32,
	name: [*]const u8, nameLen: u32,
	description: [*]const u8, descriptionLen: u32,
	usage: [*]const u8, usageLen: u32
) void;