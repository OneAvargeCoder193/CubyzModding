const std = @import("std");

pub const command = @import("command.zig");
pub const game = @import("game.zig");
pub const gui = @import("gui.zig");
pub const user = @import("user.zig");
pub const utils = @import("utils.zig");
pub const vec = @import("vec.zig");
pub const world = @import("world.zig");

pub const allocator = std.heap.wasm_allocator;

pub export fn alloc(len: u32) [*]u8 {
	return (allocator.alloc(u8, len) catch unreachable).ptr;
}

pub export fn free(ptr: [*]u8, len: u32) void {
	allocator.free(ptr[0..len]);
}

pub export fn init() void {
	
}

pub export fn deinit() void {
	
}