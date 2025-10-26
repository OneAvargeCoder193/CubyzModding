const std = @import("std");

const cubyz = @import("cubyz");
const User = cubyz.user.User;
const world = cubyz.world;
const Block = world.Block;
const Vec3d = cubyz.vec.Vec3d;
const Vec3i = cubyz.vec.Vec3i;

pub fn execute(args: []u8, source: User) void {
	const val = if(args.len == 0) 1 else std.fmt.parseInt(i32, args, 10) catch {
		source.sendMessage("Up value must be a real number.", .{});
		return;
	};

	const pos = source.getPosition() + Vec3d{0, 0, @floatFromInt(val)};
	const under = @as(Vec3i, @intFromFloat(@floor(pos))) - Vec3i{0, 0, 1};
	world.setBlock(Block.parse("cubyz:glass/white"), under);
	source.setPosition(pos);
}