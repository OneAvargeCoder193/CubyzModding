const std = @import("std");

const main = @import("root");

pub const user = @import("user.zig");
pub const game = @import("game.zig");
pub const command = @import("command.zig");
pub const utils = @import("utils.zig");

pub const allocator = std.heap.wasm_allocator;

pub export fn alloc(len: usize) [*]u8 {
	return (allocator.alloc(u8, len) catch unreachable).ptr;
}

pub export fn free(ptr: [*]u8, len: usize) void {
	allocator.free(ptr[0..len]);
}

pub export fn init() void {
	
}

pub export fn deinit() void {
	command.deinit();
}