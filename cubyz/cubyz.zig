const std = @import("std");

pub const assets = @import("assets.zig");
pub const callback = @import("callback.zig");
pub const chat = @import("chat.zig");
pub const command = @import("command.zig");
pub const game = @import("game.zig");
pub const graphics = @import("graphics.zig");
pub const gui = @import("gui.zig");
pub const user = @import("user.zig");
pub const utils = @import("utils.zig");
pub const vec = @import("vec.zig");
pub const world = @import("world.zig");
pub const zon = @import("zon.zig");

pub const allocator = std.heap.wasm_allocator;
var worldArena: std.heap.ArenaAllocator = undefined;
pub var worldArenaAllocator: std.mem.Allocator = undefined;
var globalArena: std.heap.ArenaAllocator = undefined;
pub var globalArenaAllocator: std.mem.Allocator = undefined;

pub export fn alloc(len: u32) [*]u8 {
	return (allocator.alloc(u8, len) catch unreachable).ptr;
}

pub export fn free(ptr: [*]u8, len: u32) void {
	allocator.free(ptr[0..len]);
}

pub export fn init() void {
	globalArena = std.heap.ArenaAllocator.init(allocator);
	globalArenaAllocator = globalArena.allocator();
}

pub export fn deinit() void {
	globalArena.deinit();
}

pub export fn initWorldArena() void {
	worldArena = std.heap.ArenaAllocator.init(allocator);
	worldArenaAllocator = worldArena.allocator();
}

pub export fn deinitWorldArena() void {
	worldArena.deinit();
}