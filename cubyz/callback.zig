const std = @import("std");

const cubyz = @import("cubyz");
const vec = cubyz.vec;
const Vec3i = vec.Vec3i;
const world = cubyz.world;
const Block = world.Block;
const User = cubyz.user.User;
const ZonElement = cubyz.zon.ZonElement;

fn getComptimeId(comptime value: anytype) comptime_int {
	return @intFromError(@field(anyerror, @typeName(opaque{const val = value;})));
}

pub fn registerCallback(comptime func: anytype, comptime callback: anytype) []const u8 {
	const funcId = getComptimeId(func);
	const name = std.fmt.comptimePrint("callback{d}", .{funcId});
	@export(&callback(func), .{.name = name});
	return name;
}

pub const Result = enum(u1) {
	handled = 0,
	ignored = 1,
};

fn registerCallbackInit(comptime callback: type) []const u8 {
	return registerCallback(callback.init, struct{
		fn wrapper(func: fn(ZonElement) callback) fn([*]const u8, u32) callconv(.{ .wasm_mvp = .{} }) *callback {
			return struct{
				fn function(ptr: [*]const u8, len: u32) callconv(.{.wasm_mvp = .{}}) *callback {
					const zon = ZonElement.parseFromString(ptr[0..len]);
					const allocated = cubyz.globalArenaAllocator.create(callback) catch unreachable;
					allocated.* = func(zon);
					return allocated;
				}
			}.function;
		}
	}.wrapper);
}

pub fn registerClientBlockCallback(comptime callback: type) void {
	const list = "ClientBlockCallback";
	const initName = registerCallbackInit(callback);
	const runName = registerCallback(callback.run, struct{
		fn wrapper(func: fn(callback, Block, Vec3i) Result) fn(*callback, u32, i32, i32, i32) callconv(.{ .wasm_mvp = .{} }) u32 {
			return struct{
				fn function(self: *callback, block: u32, x: i32, y: i32, z: i32) callconv(.{.wasm_mvp = .{}}) u32 {
					return @intFromEnum(func(self.*, @bitCast(block), .{x, y, z}));
				}
			}.function;
		}
	}.wrapper);
	registerCallbackImpl(list.ptr, @intCast(list.len), callback.id.ptr, @intCast(callback.id.len), initName.ptr, @intCast(initName.len), runName.ptr, @intCast(runName.len));
}

pub fn registerServerBlockCallback(comptime callback: type) void {
	const list = "ServerBlockCallback";
	const initName = registerCallbackInit(callback);
	const runName = registerCallback(callback.run, struct{
		fn wrapper(func: fn(callback, Block, Vec3i) Result) fn(*callback, u32, i32, i32, i32) callconv(.{ .wasm_mvp = .{} }) u32 {
			return struct{
				fn function(self: *callback, block: u32, x: i32, y: i32, z: i32) callconv(.{.wasm_mvp = .{}}) u32 {
					return @intFromEnum(func(self.*, @bitCast(block), .{x, y, z}));
				}
			}.function;
		}
	}.wrapper);
	registerCallbackImpl(list.ptr, @intCast(list.len), callback.id.ptr, @intCast(callback.id.len), initName.ptr, @intCast(initName.len), runName.ptr, @intCast(runName.len));
}

pub fn registerTouchBlockCallback(comptime callback: type) void {
	const list = "BlockTouchCallback";
	const initName = registerCallbackInit(callback);
	const runName = registerCallback(callback.run, struct{
		fn wrapper(func: fn(callback, User, Block, Vec3i, f64) Result) fn(*callback, u32, u32, i32, i32, i32, f64) callconv(.{ .wasm_mvp = .{} }) u32 {
			return struct{
				fn function(self: *callback, user: u32, block: u32, x: i32, y: i32, z: i32, dt: f64) callconv(.{.wasm_mvp = .{}}) u32 {
					return @intFromEnum(func(self.*, .{.id = user}, @bitCast(block), .{x, y, z}, dt));
				}
			}.function;
		}
	}.wrapper);
	registerCallbackImpl(list.ptr, @intCast(list.len), callback.id.ptr, @intCast(callback.id.len), initName.ptr, @intCast(initName.len), runName.ptr, @intCast(runName.len));
}

extern fn registerCallbackImpl(listNamePtr: [*]const u8, listNameLen: u32, idPtr: [*]const u8, idLen: u32, initNamePtr: [*]const u8, initNameLen: u32, runNamePtr: [*]const u8, runNameLen: u32) void;