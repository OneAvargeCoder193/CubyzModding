const std = @import("std");

const main = @import("root");
const cubyz = main.cubyz;
const game = cubyz.game;
const vec = cubyz.vec;
const Vec3d = vec.Vec3d;

pub const User = packed struct(u32) {
	id: u32,
	
	pub fn sendMessage(self: User, comptime fmt: []const u8, args: anytype) void {
		const msg = std.fmt.allocPrint(cubyz.allocator, fmt, args) catch unreachable;
		defer cubyz.allocator.free(msg);
		sendMessageImpl(self, msg.ptr, @intCast(msg.len));
	}

	pub fn addHealth(self: User, amount: f32, damageType: game.DamageType) void {
		addHealthImpl(self, amount, damageType);
	}

	pub fn getPosition(self: User) Vec3d {
		var out: Vec3d = undefined;
		getPositionImpl(self, &out[0], &out[1], &out[2]);
		return out;
	}

	pub fn setPosition(self: User, pos: Vec3d) void {
		setPositionImpl(self, pos[0], pos[1], pos[2]);
	}
};

extern fn addHealthImpl(user: User, amount: f32, damageType: game.DamageType) void;
extern fn sendMessageImpl(user: User, message: [*]u8, messageLen: u32) void;
extern fn getPositionImpl(user: User, x: *f64, y: *f64, z: *f64) void; // zig doesn't seem to support multi values as far as I can tell
extern fn setPositionImpl(user: User, x: f64, y: f64, z: f64) void;