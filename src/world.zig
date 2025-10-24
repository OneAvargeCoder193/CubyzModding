const main = @import("root");
const cubyz = main.cubyz;
const vec = cubyz.vec;
const Vec3i = vec.Vec3i;

pub const Block = packed struct(u32) {
	typ: u16,
	data: u16,

	pub const air = Block{.typ = 0, .data = 0};

	pub fn parse(id: []const u8) Block {
		return parseBlockImpl(@constCast(id.ptr), @intCast(id.len));
	}
};

pub fn setBlock(block: Block, pos: Vec3i) void {
	setBlockImpl(block, pos[0], pos[1], pos[2]);
}

pub fn getBlock(pos: Vec3i) Block {
	return getBlockImpl(pos[0], pos[1], pos[2]);
}

extern fn parseBlockImpl(id: [*]u8, idLen: u32) Block;
extern fn setBlockImpl(block: Block, x: i32, y: i32, z: i32) void;
extern fn getBlockImpl(x: i32, y: i32, z: i32) Block;