const std = @import("std");
const builtin = @import("builtin");

pub const Side = enum(u1) {
	client = 0,
	server = 1,
};