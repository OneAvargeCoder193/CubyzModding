const std = @import("std");

const main = @import("root");
const cubyz = main.cubyz;
const game = cubyz.game;

pub const User = struct {
	id: u32,
	
	pub fn sendMessage(self: User, comptime fmt: []const u8, args: anytype) void {
		const msg = std.fmt.allocPrint(cubyz.allocator, fmt, args) catch unreachable;
		defer cubyz.allocator.free(msg);
		sendMessageImpl(self.id, msg.ptr, msg.len);
	}

	pub fn addHealth(self: User, amount: f32, damageType: game.DamageType) void {
		addHealthImpl(self.id, amount, damageType);
	}
};

extern fn addHealthImpl(user: u32, amount: f32, damageType: game.DamageType) void;
extern fn sendMessageImpl(user: u32, message: [*]u8, messageLen: usize) void;