const std = @import("std");

pub const cubyz = @import("cubyz.zig");
pub const user = cubyz.user;
pub const game = cubyz.game;
pub const utils = cubyz.utils;
pub const command = cubyz.command;

fn executeCat(args: []u8, source: user.User) void {
	source.sendMessage("{s}", .{args});
}

fn executeDamage(args: []u8, source: user.User) void {
	const amount = std.fmt.parseFloat(f32, args) catch {
		source.sendMessage("Damage value must be a real number.", .{});
		return;
	};
	source.sendMessage("I love wasm!!\n", .{});
	source.addHealth(-amount, .kill);
}

pub export fn registerCommands() void {
	command.registerCommand(executeCat, "cat", "Repeats the player", "/cat");
	command.registerCommand(executeDamage, "damage", "Damages the player", "/damage");
}