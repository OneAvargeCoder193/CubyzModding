const std = @import("std");
const builtin = @import("builtin");

const main = @import("root");
const cubyz = main.cubyz;

pub const Side = enum(u1) {
	client = 0,
	server = 1,
};