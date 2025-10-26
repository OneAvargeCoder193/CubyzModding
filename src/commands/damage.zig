const std = @import("std");

const cubyz = @import("cubyz");
const User = cubyz.user.User;

pub fn execute(args: []u8, source: User) void {
	const amount = std.fmt.parseFloat(f32, args) catch {
		source.sendMessage("Damage value must be a real number.", .{});
		return;
	};
	source.sendMessage("I love wasm!!\n", .{});
	source.addHealth(-amount, .kill);
}