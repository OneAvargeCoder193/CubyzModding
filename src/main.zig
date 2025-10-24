const std = @import("std");

pub const cubyz = @import("cubyz.zig");
pub const user = cubyz.user;
pub const game = cubyz.game;
pub const utils = cubyz.utils;
pub const command = cubyz.command;
pub const vec = cubyz.vec;
pub const world = cubyz.world;
pub const blueprint = cubyz.blueprint;
const Vec3d = vec.Vec3d;
const Vec3i = vec.Vec3i;
const User = user.User;
const Block = world.Block;
const Blueprint = blueprint.Blueprint;

fn executeCat(args: []u8, source: User) void {
	source.sendMessage("{s}", .{args});
}

fn executeDamage(args: []u8, source: User) void {
	const amount = std.fmt.parseFloat(f32, args) catch {
		source.sendMessage("Damage value must be a real number.", .{});
		return;
	};
	source.sendMessage("I love wasm!!\n", .{});
	source.addHealth(-amount, .kill);
}

fn executeUp(args: []u8, source: User) void {
	const val = if(args.len == 0) 1 else std.fmt.parseInt(i32, args, 10) catch {
		source.sendMessage("Up value must be a real number.", .{});
		return;
	};

	const pos = source.getPosition() + Vec3d{0, 0, @floatFromInt(val)};
	const under = @as(Vec3i, @intFromFloat(@floor(pos))) - Vec3i{0, 0, 1};
	world.setBlock(Block.parse("cubyz:glass/white"), under);
	source.setPosition(pos);
}

pub export fn registerCommands() void {
	command.registerCommand(executeCat, "cat", "Repeats the player", "/cat <text>");
	command.registerCommand(executeDamage, "damage", "Damages the player", "/damage <amount>");
	command.registerCommand(executeUp, "up", "Moves the player up and places glass below", "/up <height>");
}