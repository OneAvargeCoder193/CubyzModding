const std = @import("std");

const main = @import("root");
const cubyz = main.cubyz;
const user = main.user;

fn typeId(comptime T: type) comptime_int {
    return @intFromError(@field(anyerror, @typeName(T)));
}

pub fn registerCommand(
	comptime exec: fn(args: []u8, source: user.User) void,
	comptime name: []const u8,
	comptime description: []const u8,
	comptime usage: []const u8,
) void {
	const id = typeId(opaque{const _name = name;});
	const funcName = std.fmt.comptimePrint("command{d}", .{id});
	@export(&struct {
		fn execute(argPtr: [*]u8, argLen: u32, source: u32) callconv(.{ .wasm_mvp = .{} }) void {
			exec(argPtr[0..argLen], .{.id = source});
		}
	}.execute, .{.name = funcName});
	registerCommandImpl(funcName.ptr, @intCast(funcName.len), name.ptr, @intCast(name.len), description.ptr, @intCast(description.len), usage.ptr, @intCast(usage.len));
}

extern fn registerCommandImpl(
	funcName: [*]const u8, funcNameLen: u32,
	name: [*]const u8, nameLen: u32,
	description: [*]const u8, descriptionLen: u32,
	usage: [*]const u8, usageLen: u32
) void;