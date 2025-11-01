const std = @import("std");

fn getComptimeId(comptime value: anytype) comptime_int {
	return @intFromError(@field(anyerror, @typeName(opaque{const val = value;})));
}

pub fn registerCallback(comptime func: anytype, comptime callback: anytype) []const u8 {
	const funcId = getComptimeId(func);
	const name = std.fmt.comptimePrint("callback{d}", .{funcId});
	@export(&callback(func), .{.name = name});
	return name;
}