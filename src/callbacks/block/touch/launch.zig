const std = @import("std");

const cubyz = @import("cubyz");
const ZonElement = cubyz.zon.ZonElement;
const User = cubyz.user.User;
const Block = cubyz.world.Block;
const Vec3i = cubyz.vec.Vec3i;
const Vec3d = cubyz.vec.Vec3d;

strength: f32,

pub const id = "launch";

pub fn init(zon: ZonElement) @This() {
	return .{
		.strength = zon.get(f32, "strength", 10),
	};
}

pub fn run(self: @This(), user: User, _: Block, _: Vec3i, _: f64) cubyz.callback.Result {
	user.setPosition(user.getPosition() + Vec3d{0, 0, self.strength});
	return .handled;
}
