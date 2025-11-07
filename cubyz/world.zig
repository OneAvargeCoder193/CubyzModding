const cubyz = @import("cubyz");
const Model = cubyz.models.Model;
const vec = cubyz.vec;
const Vec3i = vec.Vec3i;

pub const Block = packed struct(u32) {
	typ: u16,
	data: u16,

	pub const air = Block{.typ = 0, .data = 0};

	pub fn parse(id: []const u8) Block {
		return parseBlockImpl(id.ptr, id.len);
	}

	pub fn modelIndexStart(self: Block) Model {
		return modelIndexStartImpl(@bitCast(self));
	}
};

pub fn setBlock(block: Block, pos: Vec3i) void {
	setBlockImpl(block, pos[0], pos[1], pos[2]);
}

pub fn getBlock(pos: Vec3i) Block {
	return getBlockImpl(pos[0], pos[1], pos[2]);
}

pub const Neighbor = enum(u3) { // MARK: Neighbor
	dirUp = 0,
	dirDown = 1,
	dirPosX = 2,
	dirNegX = 3,
	dirPosY = 4,
	dirNegY = 5,

	pub inline fn toInt(self: Neighbor) u3 {
		return @intFromEnum(self);
	}

	/// Index to relative position
	pub fn relX(self: Neighbor) i32 {
		const arr = [_]i32{0, 0, 1, -1, 0, 0};
		return arr[@intFromEnum(self)];
	}
	/// Index to relative position
	pub fn relY(self: Neighbor) i32 {
		const arr = [_]i32{0, 0, 0, 0, 1, -1};
		return arr[@intFromEnum(self)];
	}
	/// Index to relative position
	pub fn relZ(self: Neighbor) i32 {
		const arr = [_]i32{1, -1, 0, 0, 0, 0};
		return arr[@intFromEnum(self)];
	}
	/// Index to relative position
	pub fn relPos(self: Neighbor) Vec3i {
		return .{self.relX(), self.relY(), self.relZ()};
	}

	pub fn fromRelPos(pos: Vec3i) ?Neighbor {
		if(@reduce(.Add, @abs(pos)) != 1) {
			return null;
		}
		return switch(pos[0]) {
			1 => return .dirPosX,
			-1 => return .dirNegX,
			else => switch(pos[1]) {
				1 => return .dirPosY,
				-1 => return .dirNegY,
				else => switch(pos[2]) {
					1 => return .dirUp,
					-1 => return .dirDown,
					else => return null,
				},
			},
		};
	}

	/// Index to bitMask for bitmap direction data
	pub inline fn bitMask(self: Neighbor) u6 {
		return @as(u6, 1) << @intFromEnum(self);
	}
	/// To iterate over all neighbors easily
	pub const iterable = [_]Neighbor{@enumFromInt(0), @enumFromInt(1), @enumFromInt(2), @enumFromInt(3), @enumFromInt(4), @enumFromInt(5)};
	/// Marks the two dimension that are orthogonal
	pub fn orthogonalComponents(self: Neighbor) Vec3i {
		const arr = [_]Vec3i{
			.{1, 1, 0},
			.{1, 1, 0},
			.{0, 1, 1},
			.{0, 1, 1},
			.{1, 0, 1},
			.{1, 0, 1},
		};
		return arr[@intFromEnum(self)];
	}
	pub fn textureX(self: Neighbor) Vec3i {
		const arr = [_]Vec3i{
			.{-1, 0, 0},
			.{1, 0, 0},
			.{0, 1, 0},
			.{0, -1, 0},
			.{-1, 0, 0},
			.{1, 0, 0},
		};
		return arr[@intFromEnum(self)];
	}
	pub fn textureY(self: Neighbor) Vec3i {
		const arr = [_]Vec3i{
			.{0, -1, 0},
			.{0, -1, 0},
			.{0, 0, 1},
			.{0, 0, 1},
			.{0, 0, 1},
			.{0, 0, 1},
		};
		return arr[@intFromEnum(self)];
	}

	pub inline fn reverse(self: Neighbor) Neighbor {
		return @enumFromInt(@intFromEnum(self) ^ 1);
	}

	pub inline fn isPositive(self: Neighbor) bool {
		return @intFromEnum(self) & 1 == 0;
	}
	const VectorComponentEnum = enum(u2) {x = 0, y = 1, z = 2};
	pub fn vectorComponent(self: Neighbor) VectorComponentEnum {
		const arr = [_]VectorComponentEnum{.z, .z, .x, .x, .y, .y};
		return arr[@intFromEnum(self)];
	}

	pub fn extractDirectionComponent(self: Neighbor, in: anytype) @TypeOf(in[0]) {
		switch(self) {
			inline else => |val| {
				return in[@intFromEnum(comptime val.vectorComponent())];
			},
		}
	}

	// Returns the neighbor that is rotated by 90 degrees counterclockwise around the z axis.
	pub inline fn rotateZ(self: Neighbor) Neighbor {
		const arr = [_]Neighbor{.dirUp, .dirDown, .dirPosY, .dirNegY, .dirNegX, .dirPosX};
		return arr[@intFromEnum(self)];
	}
};

extern fn parseBlockImpl(id: [*]const u8, idLen: u32) Block;
extern fn modelIndexStartImpl(block: Block) Model;
extern fn setBlockImpl(block: Block, x: i32, y: i32, z: i32) void;
extern fn getBlockImpl(x: i32, y: i32, z: i32) Block;