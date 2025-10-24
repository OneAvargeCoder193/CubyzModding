const std = @import("std");
const builtin = @import("builtin");

const main = @import("root");
const cubyz = main.cubyz;

pub const Side = enum(u1) {
	client = 0,
	server = 1,
};

pub const Degrees = enum(u2) {
	@"0" = 0,
	@"90" = 1,
	@"180" = 2,
	@"270" = 3,
};

pub fn Array3D(comptime T: type) type { // MARK: Array3D
	return struct {
		const Self = @This();
		mem: []T,
		width: u32,
		depth: u32,
		height: u32,

		pub fn init(allocator: std.mem.Allocator, width: u32, depth: u32, height: u32) Self {
			return .{
				.mem = allocator.alloc(T, width*height*depth) catch unreachable,
				.width = width,
				.depth = depth,
				.height = height,
			};
		}

		pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
			allocator.free(self.mem);
		}

		pub fn get(self: Self, x: usize, y: usize, z: usize) T {
			std.debug.assert(x < self.width and y < self.depth and z < self.height);
			return self.mem[(x*self.depth + y)*self.height + z];
		}

		pub fn set(self: Self, x: usize, y: usize, z: usize, t: T) void {
			std.debug.assert(x < self.width and y < self.depth and z < self.height);
			self.mem[(x*self.depth + y)*self.height + z] = t;
		}

		pub fn ptr(self: Self, x: usize, y: usize, z: usize) *T {
			std.debug.assert(x < self.width and y < self.depth and z < self.height);
			return &self.mem[(x*self.depth + y)*self.height + z];
		}

		pub fn clone(self: Self, allocator: std.mem.Allocator) Self {
			const new = Self.init(allocator, self.width, self.depth, self.height);
			@memcpy(new.mem, self.mem);
			return new;
		}
	};
}

const endian: std.builtin.Endian = .big;

pub const BinaryReader = struct {
	remaining: []const u8,

	pub const AllErrors = error{OutOfBounds, IntOutOfBounds, InvalidEnumTag, InvalidFloat};

	pub fn init(data: []const u8) BinaryReader {
		return .{.remaining = data};
	}

	pub fn readVec(self: *BinaryReader, T: type) error{OutOfBounds, IntOutOfBounds, InvalidFloat}!T {
		const typeInfo = @typeInfo(T).vector;
		var result: T = undefined;
		inline for(0..typeInfo.len) |i| {
			switch(@typeInfo(typeInfo.child)) {
				.int => {
					result[i] = try self.readInt(typeInfo.child);
				},
				.float => {
					result[i] = try self.readFloat(typeInfo.child);
				},
				else => unreachable,
			}
		}
		return result;
	}

	pub fn readInt(self: *BinaryReader, T: type) error{OutOfBounds, IntOutOfBounds}!T {
		if(@mod(@typeInfo(T).int.bits, 8) != 0) {
			const fullBits = comptime std.mem.alignForward(u16, @typeInfo(T).int.bits, 8);
			const FullType = std.meta.Int(@typeInfo(T).int.signedness, fullBits);
			const val = try self.readInt(FullType);
			return std.math.cast(T, val) orelse return error.IntOutOfBounds;
		}
		const bufSize = @divExact(@typeInfo(T).int.bits, 8);
		if(self.remaining.len < bufSize) return error.OutOfBounds;
		defer self.remaining = self.remaining[bufSize..];
		return std.mem.readInt(T, self.remaining[0..bufSize], endian);
	}

	pub fn readVarInt(self: *BinaryReader, T: type) !T {
		comptime std.debug.assert(@typeInfo(T).int.signedness == .unsigned);
		comptime std.debug.assert(@bitSizeOf(T) > 8); // Why would you use a VarInt for this?
		var result: T = 0;
		var shift: std.meta.Int(.unsigned, std.math.log2_int_ceil(usize, @bitSizeOf(T))) = 0;
		while(true) {
			const nextByte = try self.readInt(u8);
			const value: T = nextByte & 0x7f;
			result |= try std.math.shlExact(T, value, shift);
			if(nextByte & 0x80 == 0) break;
			shift = try std.math.add(@TypeOf(shift), shift, 7);
		}
		return result;
	}

	pub fn readFloat(self: *BinaryReader, T: type) error{OutOfBounds, IntOutOfBounds, InvalidFloat}!T {
		const IntT = std.meta.Int(.unsigned, @typeInfo(T).float.bits);
		const result: T = @bitCast(try self.readInt(IntT));
		if(!std.math.isFinite(result)) return error.InvalidFloat;
		return result;
	}

	pub fn readEnum(self: *BinaryReader, T: type) error{OutOfBounds, IntOutOfBounds, InvalidEnumTag}!T {
		const int = try self.readInt(@typeInfo(T).@"enum".tag_type);
		return std.meta.intToEnum(T, int);
	}

	pub fn readBool(self: *BinaryReader) error{OutOfBounds, IntOutOfBounds, InvalidEnumTag}!bool {
		const int = try self.readInt(u1);
		return int != 0;
	}

	pub fn readUntilDelimiter(self: *BinaryReader, comptime delimiter: u8) ![:delimiter]const u8 {
		const len = std.mem.indexOfScalar(u8, self.remaining, delimiter) orelse return error.OutOfBounds;
		defer self.remaining = self.remaining[len + 1 ..];
		return self.remaining[0..len :delimiter];
	}

	pub fn readSlice(self: *BinaryReader, length: usize) error{OutOfBounds, IntOutOfBounds}![]const u8 {
		if(self.remaining.len < length) return error.OutOfBounds;
		defer self.remaining = self.remaining[length..];
		return self.remaining[0..length];
	}
};

pub const BinaryWriter = struct {
	data: main.List(u8),

	pub fn init(allocator: std.mem.Allocator) BinaryWriter {
		return .{.data = .init(allocator) catch unreachable};
	}

	pub fn initCapacity(allocator: std.mem.Allocator, capacity: usize) BinaryWriter {
		return .{.data = .initCapacity(allocator, capacity) catch unreachable};
	}

	pub fn deinit(self: *BinaryWriter) void {
		self.data.deinit();
	}

	pub fn writeVec(self: *BinaryWriter, T: type, value: T) void {
		const typeInfo = @typeInfo(T).vector;
		inline for(0..typeInfo.len) |i| {
			switch(@typeInfo(typeInfo.child)) {
				.int => {
					self.writeInt(typeInfo.child, value[i]);
				},
				.float => {
					self.writeFloat(typeInfo.child, value[i]);
				},
				else => unreachable,
			}
		}
	}

	pub fn writeInt(self: *BinaryWriter, T: type, value: T) void {
		if(@mod(@typeInfo(T).int.bits, 8) != 0) {
			const fullBits = comptime std.mem.alignForward(u16, @typeInfo(T).int.bits, 8);
			const FullType = std.meta.Int(@typeInfo(T).int.signedness, fullBits);
			return self.writeInt(FullType, value);
		}
		const bufSize = @divExact(@typeInfo(T).int.bits, 8);
		std.mem.writeInt(T, self.data.addMany(bufSize)[0..bufSize], value, endian);
	}

	pub fn writeVarInt(self: *BinaryWriter, T: type, value: T) void {
		comptime std.debug.assert(@typeInfo(T).int.signedness == .unsigned);
		comptime std.debug.assert(@bitSizeOf(T) > 8); // Why would you use a VarInt for this?
		var remaining: T = value;
		while(true) {
			var writeByte: u8 = @intCast(remaining & 0x7f);
			remaining >>= 7;
			if(remaining != 0) writeByte |= 0x80;
			self.writeInt(u8, writeByte);
			if(remaining == 0) break;
		}
	}

	pub fn writeFloat(self: *BinaryWriter, T: type, value: T) void {
		const IntT = std.meta.Int(.unsigned, @typeInfo(T).float.bits);
		self.writeInt(IntT, @bitCast(value));
	}

	pub fn writeEnum(self: *BinaryWriter, T: type, value: T) void {
		self.writeInt(@typeInfo(T).@"enum".tag_type, @intFromEnum(value));
	}

	pub fn writeBool(self: *BinaryWriter, value: bool) void {
		self.writeInt(u1, @intFromBool(value));
	}

	pub fn writeSlice(self: *BinaryWriter, slice: []const u8) void {
		self.data.appendSlice(slice);
	}

	pub fn writeWithDelimiter(self: *BinaryWriter, slice: []const u8, delimiter: u8) void {
		std.debug.assert(!std.mem.containsAtLeast(u8, slice, 1, &.{delimiter}));
		self.writeSlice(slice);
		self.data.append(delimiter);
	}
};

/// Implementation of https://en.wikipedia.org/wiki/Alias_method
pub fn AliasTable(comptime T: type) type { // MARK: AliasTable
	return struct {
		const AliasData = struct {
			chance: u16,
			alias: u16,
		};
		items: []T,
		aliasData: []AliasData,
		ownsSlice: bool = false,
		random: std.Random,

		fn initAliasData(self: *@This(), totalChance: f32, currentChances: []f32) void {
			const desiredChance = totalChance/@as(f32, @floatFromInt(self.aliasData.len));

			var rand = std.Random.DefaultPrng.init(0);
			self.random = rand.random();

			var lastOverfullIndex: u16 = 0;
			var lastUnderfullIndex: u16 = 0;
			outer: while(true) {
				while(currentChances[lastOverfullIndex] <= desiredChance) {
					lastOverfullIndex += 1;
					if(lastOverfullIndex == self.items.len)
						break :outer;
				}
				while(currentChances[lastUnderfullIndex] >= desiredChance) {
					lastUnderfullIndex += 1;
					if(lastUnderfullIndex == self.items.len)
						break :outer;
				}
				const delta = desiredChance - currentChances[lastUnderfullIndex];
				currentChances[lastUnderfullIndex] = desiredChance;
				currentChances[lastOverfullIndex] -= delta;
				self.aliasData[lastUnderfullIndex] = .{
					.alias = lastOverfullIndex,
					.chance = @intFromFloat(delta/desiredChance*std.math.maxInt(u16)),
				};
				if(currentChances[lastOverfullIndex] < desiredChance) {
					lastUnderfullIndex = @min(lastUnderfullIndex, lastOverfullIndex);
				}
			}
		}

		pub fn init(allocator: std.mem.Allocator, items: []T) @This() {
			var self: @This() = .{
				.items = items,
				.aliasData = allocator.alloc(AliasData, items.len) catch unreachable,
			};
			if(items.len == 0) return self;
			@memset(self.aliasData, AliasData{.chance = 0, .alias = 0});
			const currentChances = cubyz.allocator.alloc(f32, items.len);
			defer cubyz.allocator.free(currentChances);
			var totalChance: f32 = 0;
			for(items, 0..) |*item, i| {
				totalChance += item.chance;
				currentChances[i] = item.chance;
			}

			var rand = std.Random.DefaultPrng.init(0);
			self.random = rand.random();

			self.initAliasData(totalChance, currentChances);

			return self;
		}

		pub fn initFromContext(allocator: std.mem.Allocator, slice: anytype) @This() {
			const items = allocator.alloc(T, slice.len) catch unreachable;
			for(slice, items) |context, *result| {
				result.* = context.getItem();
			}
			var self: @This() = .{
				.items = items,
				.aliasData = allocator.alloc(AliasData, items.len),
				.ownsSlice = true,
			};
			if(items.len == 0) return self;
			@memset(self.aliasData, AliasData{.chance = 0, .alias = 0});
			const currentChances = cubyz.allocator.alloc(f32, items.len);
			defer cubyz.allocator.free(currentChances);
			var totalChance: f32 = 0;
			for(slice, 0..) |context, i| {
				totalChance += context.chance;
				currentChances[i] = context.chance;
			}

			self.initAliasData(totalChance, currentChances);

			return self;
		}

		pub fn deinit(self: *const @This(), allocator: std.mem.Allocator) void {
			allocator.free(self.aliasData);
			if(self.ownsSlice) {
				allocator.free(self.items);
			}
		}

		pub fn sample(self: *const @This()) *T {
			const initialIndex = self.random.intRangeLessThan(u16, @as(u16, @intCast(self.items.len)));
			if(self.random.int(u16) < self.aliasData[initialIndex].chance) {
				return &self.items[self.aliasData[initialIndex].alias];
			}
			return &self.items[initialIndex];
		}
	};
}