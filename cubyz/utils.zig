const std = @import("std");
const builtin = @import("builtin");

const cubyz = @import("cubyz");

pub const Side = enum(u1) {
	client = 0,
	server = 1,
};


const endian: std.builtin.Endian = .big;
pub const BinaryWriter = struct {
	data: std.ArrayList(u8) = .{},

	pub fn initCapacity(capacity: usize) BinaryWriter {
		return .{.data = .initCapacity(cubyz.allocator, capacity)};
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
		std.mem.writeInt(T, self.data.addManyAsArray(cubyz.allocator, bufSize) catch unreachable, value, endian);
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
		self.data.appendSlice(cubyz.allocator, slice) catch unreachable;
	}

	pub fn writeWithDelimiter(self: *BinaryWriter, slice: []const u8, delimiter: u8) void {
		std.debug.assert(!std.mem.containsAtLeast(u8, slice, 1, &.{delimiter}));
		self.writeSlice(slice);
		self.data.append(cubyz.allocator, delimiter) catch unreachable;
	}
};