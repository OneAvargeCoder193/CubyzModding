const std = @import("std");

const cubyz = @import("cubyz");
const user = cubyz.user;

pub fn registerCommand(
	comptime exec: fn(args: []u8, source: user.User) void,
	comptime name: []const u8,
	comptime description: []const u8,
	comptime usage: []const u8,
) void {
	const funcName = cubyz.callback.registerCallback(exec, struct{
		fn wrap(func: fn(args: []u8, source: user.User) void) fn(argPtr: [*]u8, argLen: u32, source: u32) callconv(.{ .wasm_mvp = .{} }) void {
			return struct{
				fn function(argPtr: [*]u8, argLen: u32, source: u32) callconv(.{ .wasm_mvp = .{} }) void {
					func(argPtr[0..argLen], .{.id = source});
				}
			}.function;
		}
	}.wrap);
	registerCommandImpl(funcName.ptr, @intCast(funcName.len), name.ptr, @intCast(name.len), description.ptr, @intCast(description.len), usage.ptr, @intCast(usage.len));
}

extern fn registerCommandImpl(
	funcName: [*]const u8, funcNameLen: u32,
	name: [*]const u8, nameLen: u32,
	description: [*]const u8, descriptionLen: u32,
	usage: [*]const u8, usageLen: u32
) void;