const std = @import("std");

const cubyz = @import("cubyz");
const game = cubyz.game;
const vec = cubyz.vec;
const Vec3i = vec.Vec3i;
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

	pub fn getSelectedPosition1(self: User) ?Vec3i {
		var out: Vec3i = undefined;
		if(!getSelectedPosition1Impl(self, &out[0], &out[1], &out[2])) return null;
		return out;
	}

	pub fn getSelectedPosition2(self: User) ?Vec3i {
		var out: Vec3i = undefined;
		if(!getSelectedPosition2Impl(self, &out[0], &out[1], &out[2])) return null;
		return out;
	}

	pub fn setSelectedPosition1(self: User, pos: ?Vec3i) void {
		if(pos != null) {
			setSelectedPosition1Impl(self, true, pos[0], pos[1], pos[2]);
		} else {
			setSelectedPosition1Impl(self, false, 0, 0, 0);
		}
	}

	pub fn setSelectedPosition2(self: User, pos: ?Vec3i) void {
		if(pos != null) {
			setSelectedPosition2Impl(self, true, pos[0], pos[1], pos[2]);
		} else {
			setSelectedPosition2Impl(self, false, 0, 0, 0);
		}
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
extern fn sendMessageImpl(user: User, message: [*]const u8, messageLen: u32) void;
extern fn getSelectedPosition1Impl(user: User, x: *i32, y: *i32, z: *i32) bool;
extern fn getSelectedPosition2Impl(user: User, x: *i32, y: *i32, z: *i32) bool;
extern fn setSelectedPosition1Impl(user: User, exists: bool, x: i32, y: i32, z: i32) void;
extern fn setSelectedPosition2Impl(user: User, exists: bool, x: i32, y: i32, z: i32) void;
extern fn getPositionImpl(user: User, x: *f64, y: *f64, z: *f64) void;
extern fn setPositionImpl(user: User, x: f64, y: f64, z: f64) void;