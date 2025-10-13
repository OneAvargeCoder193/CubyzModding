const main = @import("root");

pub const Side = enum(u1) {
	client = 0,
	server = 1,
};