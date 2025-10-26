const cubyz = @import("cubyz");
const User = cubyz.user.User;

pub fn execute(args: []u8, source: User) void {
	source.sendMessage("{s}", .{args});
}