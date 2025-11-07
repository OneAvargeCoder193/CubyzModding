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

pub fn registerCallback(comptime callback: anytype) []const u8 {
	const funcId = getComptimeId(callback);
	const name = std.fmt.comptimePrint("callback{d}", .{funcId});
	@export(&callback, .{.name = name});
	return name;
}

pub const Result = enum(u1) {
	handled = 0,
	ignored = 1,
};

fn registerCallbackInit(comptime callback: type) []const u8 {
	return registerCallback(struct{
		fn wrap(ptr: [*]const u8, len: u32) callconv(.{.wasm_mvp = .{}}) *callback {
			const zon = ZonElement.parseFromString(ptr[0..len]);
			const allocated = cubyz.globalArenaAllocator.create(callback) catch unreachable;
			allocated.* = callback.init(zon);
			return allocated;
		}
	}.wrap);
}

pub fn registerClientBlockCallback(comptime callback: type) void {
	const list = "ClientBlockCallback";
	const initName = registerCallbackInit(callback);
	const runName = registerCallback(struct{
		fn wrap(self: *callback, block: u32, x: i32, y: i32, z: i32) callconv(.{.wasm_mvp = .{}}) u32 {
			return @intFromEnum(callback.run(self.*, @bitCast(block), .{x, y, z}));
		}
	}.wrap);
	registerCallbackImpl(list.ptr, list.len, callback.id.ptr, callback.id.len, initName.ptr, initName.len, runName.ptr, runName.len);
}

pub fn registerServerBlockCallback(comptime callback: type) void {
	const list = "ServerBlockCallback";
	const initName = registerCallbackInit(callback);
	const runName = registerCallback(struct{
		fn wrap(self: *callback, block: u32, x: i32, y: i32, z: i32) callconv(.{.wasm_mvp = .{}}) u32 {
			return @intFromEnum(callback.run(self.*, @bitCast(block), .{x, y, z}));
		}
	}.wrap);
	registerCallbackImpl(list.ptr, list.len, callback.id.ptr, callback.id.len, initName.ptr, initName.len, runName.ptr, runName.len);
}

pub fn registerTouchBlockCallback(comptime callback: type) void {
	const list = "BlockTouchCallback";
	const initName = registerCallbackInit(callback);
	const runName = registerCallback(struct{
		fn wrap(self: *callback, user: u32, block: u32, x: i32, y: i32, z: i32, dt: f64) callconv(.{.wasm_mvp = .{}}) u32 {
			return @intFromEnum(callback.run(self.*, .{.id = user}, @bitCast(block), .{x, y, z}, dt));
		}
	}.wrap);
	registerCallbackImpl(list.ptr, list.len, callback.id.ptr, callback.id.len, initName.ptr, initName.len, runName.ptr, runName.len);
}

extern fn registerCallbackImpl(listNamePtr: [*]const u8, listNameLen: u32, idPtr: [*]const u8, idLen: u32, initNamePtr: [*]const u8, initNameLen: u32, runNamePtr: [*]const u8, runNameLen: u32) void;