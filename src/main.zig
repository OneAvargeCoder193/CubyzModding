const std = @import("std");

pub const cubyz = @import("cubyz");
pub const assets = cubyz.assets;
pub const callback = cubyz.callback;
pub const user = cubyz.user;
pub const game = cubyz.game;
pub const gui = cubyz.gui;
pub const utils = cubyz.utils;
pub const command = cubyz.command;
pub const vec = cubyz.vec;
pub const world = cubyz.world;
const Vec3d = vec.Vec3d;
const Vec3i = vec.Vec3i;
const User = user.User;
const Block = world.Block;

const assetList = @import("build_options").assets;

pub export fn loadAssets() void {
	inline for(assetList) |asset| {
		const content = @embedFile("assets/" ++ asset);
		assets.registerAsset(asset, content);
	}
}

pub export fn registerCommands() void {
	command.registerCommand(@import("commands/calc.zig").execute, "calc", "Calculate equation", "/calc <equation>");
	command.registerCommand(@import("commands/cat.zig").execute, "cat", "Repeats the player", "/cat <text>");
	command.registerCommand(@import("commands/damage.zig").execute, "damage", "Damages the player", "/damage <amount>");
	command.registerCommand(@import("commands/up.zig").execute, "up", "Moves the player up and places glass below", "/up <height>");
}

pub export fn registerWindows() void {
	gui.registerWindow(@import("gui/testgui.zig"));
}

pub export fn initTouchBlockCallback() void {
	callback.registerTouchBlockCallback(@import("callbacks/block/touch/launch.zig"));
}