const std = @import("std");

const cubyz = @import("cubyz");
const User = cubyz.user.User;
const world = cubyz.world;
const Block = world.Block;
const Vec3d = cubyz.vec.Vec3d;
const Vec3i = cubyz.vec.Vec3i;

const expression = @import("../expression.zig");

pub fn execute(args: []u8, source: User) void {
	const result = expression.executeExpression(args, .{.x = 0, .y = 0, .z = 0}) catch |err| {
		switch(err) {
			expression.ExpressionError.InvalidCharacter => {
				source.sendMessage("#ff0000Invalid character passed into <equation> argument.", .{});
			},
			expression.ExpressionError.InvalidEquation => {
				source.sendMessage("#ff0000Invalid equation passed into <equation> argument.", .{});
			},
			expression.ExpressionError.IllegalName => {
				source.sendMessage("#ff0000Invalid identifier passed into <equation> argument, only accepts x, y, and z.", .{});
			},
			expression.ExpressionError.IllegalType => {
				source.sendMessage("#ff0000Invalid type in operator.", .{});
			},
		}
		return;
	};

	const string = result.toString(cubyz.allocator);
	defer cubyz.allocator.free(string);
	source.sendMessage("{s}", .{string});
}