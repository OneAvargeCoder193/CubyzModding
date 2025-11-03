const std = @import("std");
const builtin = @import("builtin");

const cubyz = @import("cubyz");

pub const ZonElement = union(enum) { // MARK: Zon
	int: i64,
	float: f64,
	string: []const u8,
	stringOwned: []const u8,
	bool: bool,
	null: void,
	array: *std.ArrayList(ZonElement),
	object: *std.StringHashMap(ZonElement),

	pub fn initObject() ZonElement {
		const map = cubyz.allocator.create(std.StringHashMap(ZonElement)) catch unreachable;
		map.* = .init(cubyz.allocator);
		return .{.object = map};
	}

	pub fn initArray() ZonElement {
		const list = cubyz.allocator.create(std.ArrayList(ZonElement)) catch unreachable;
		list.* = .{};
		return .{.array = list};
	}

	pub fn getAtIndex(self: *const ZonElement, comptime _type: type, index: usize, replacement: _type) _type {
		if(self.* != .array) {
			return replacement;
		} else {
			if(index < self.array.items.len) {
				return self.array.items[index].as(_type, replacement);
			} else {
				return replacement;
			}
		}
	}

	pub fn getChildAtIndex(self: *const ZonElement, index: usize) ZonElement {
		if(self.* != .array) {
			return .null;
		} else {
			if(index < self.array.items.len) {
				return self.array.items[index];
			} else {
				return .null;
			}
		}
	}

	pub fn get(self: *const ZonElement, comptime _type: type, key: []const u8, replacement: _type) _type {
		if(self.* != .object) {
			return replacement;
		} else {
			if(self.object.get(key)) |elem| {
				return elem.as(_type, replacement);
			} else {
				return replacement;
			}
		}
	}

	pub fn getChild(self: *const ZonElement, key: []const u8) ZonElement {
		return self.getChildOrNull(key) orelse .null;
	}

	pub fn getChildOrNull(self: *const ZonElement, key: []const u8) ?ZonElement {
		if(self.* == .object) return self.object.get(key);
		return null;
	}

	pub fn clone(self: *const ZonElement) ZonElement {
		return switch(self.*) {
			.int, .float, .string, .bool, .null => self.*,
			.stringOwned => |stringOwned| .{.stringOwned = cubyz.allocator.dupe(u8, stringOwned) catch unreachable},
			.array => |array| blk: {
				const out = ZonElement.initArray();

				for(0..array.items.len) |i| {
					out.array.append(cubyz.allocator, array.items[i].clone()) catch unreachable;
				}

				break :blk out;
			},
			.object => |object| blk: {
				const out = ZonElement.initObject();

				var iter = object.iterator();
				while(iter.next()) |entry| {
					out.put(entry.key_ptr.*, entry.value_ptr.clone());
				}

				break :blk out;
			},
		};
	}

	pub const JoinPriority = enum {preferLeft, preferRight};

	fn joinGetNew(left: ZonElement, priority: JoinPriority, right: ZonElement) ZonElement {
		switch(left) {
			.int, .float, .string, .stringOwned, .bool, .null => {
				return switch(priority) {
					.preferLeft => left.clone(),
					.preferRight => right.clone(),
				};
			},
			.array => {
				const out = left.clone();
				for(right.array.items) |item| {
					out.array.append(cubyz.allocator, item.clone()) catch unreachable;
				}
				return out;
			},
			.object => {
				const out = left.clone();

				out.join(priority, right);
				return out;
			},
		}

		return .null;
	}

	pub fn join(left: *const ZonElement, priority: JoinPriority, right: ZonElement) void {
		if(right == .null) {
			return;
		}
		if(left.* != .object or right != .object) {
			return;
		}

		var iter = right.object.iterator();
		while(iter.next()) |entry| {
			if(left.object.get(entry.key_ptr.*)) |val| {
				left.put(entry.key_ptr.*, val.joinGetNew(priority, entry.value_ptr.*, .{.allocator = left.object.allocator, .IAssertThatTheProvidedAllocatorCantFail = {}}));
			} else {
				left.put(entry.key_ptr.*, entry.value_ptr.clone(.{.allocator = left.object.allocator, .IAssertThatTheProvidedAllocatorCantFail = {}}));
			}
		}
	}

	pub fn as(self: *const ZonElement, comptime T: type, replacement: T) T {
		comptime var typeInfo: std.builtin.Type = @typeInfo(T);
		comptime var innerType = T;
		inline while(typeInfo == .optional) {
			innerType = typeInfo.optional.child;
			typeInfo = @typeInfo(innerType);
		}
		switch(typeInfo) {
			.int => {
				switch(self.*) {
					.int => return std.math.cast(innerType, self.int) orelse replacement,
					.float => return std.math.lossyCast(innerType, std.math.round(self.float)),
					else => return replacement,
				}
			},
			.float => {
				switch(self.*) {
					.int => return @floatFromInt(self.int),
					.float => return @floatCast(self.float),
					else => return replacement,
				}
			},
			.vector => {
				const len = typeInfo.vector.len;
				const elems = self.toSlice();
				if(elems.len != len) return replacement;
				var result: innerType = undefined;
				if(innerType == T) result = replacement;
				inline for(0..len) |i| {
					if(innerType == T) {
						result[i] = elems[i].as(typeInfo.vector.child, result[i]);
					} else {
						result[i] = elems[i].as(?typeInfo.vector.child, null) orelse return replacement;
					}
				}
				return result;
			},
			else => {
				switch(innerType) {
					[]const u8 => {
						switch(self.*) {
							.string => return self.string,
							.stringOwned => return self.stringOwned,
							else => return replacement,
						}
					},
					bool => {
						switch(self.*) {
							.bool => return self.bool,
							else => return replacement,
						}
					},
					else => {
						@compileError("Unsupported type '" ++ @typeName(T) ++ "'.");
					},
				}
			},
		}
	}

	fn createElementFromRandomType(value: anytype, allocator: std.mem.Allocator) ZonElement {
		switch(@typeInfo(@TypeOf(value))) {
			.void => return .null,
			.null => return .null,
			.bool => return .{.bool = value},
			.int, .comptime_int => return .{.int = @intCast(value)},
			.float, .comptime_float => return .{.float = @floatCast(value)},
			.@"union" => {
				if(@TypeOf(value) == ZonElement) {
					return value;
				} else {
					@compileError("Unknown value type.");
				}
			},
			.pointer => |ptr| {
				if(ptr.child == u8 and ptr.size == .slice) {
					return .{.string = value};
				} else {
					const childInfo = @typeInfo(ptr.child);
					if(ptr.size == .one and childInfo == .array and childInfo.array.child == u8) {
						return .{.string = value};
					} else {
						@compileError("Unknown value type.");
					}
				}
			},
			.optional => {
				if(value) |val| {
					return createElementFromRandomType(val, allocator);
				} else {
					return .null;
				}
			},
			.vector => {
				const len = @typeInfo(@TypeOf(value)).vector.len;
				const result = initArray();
				result.array.ensureCapacity(len);
				inline for(0..len) |i| {
					result.array.appendAssumeCapacity(createElementFromRandomType(value[i], allocator)) catch unreachable;
				}
				return result;
			},
			else => {
				if(@TypeOf(value) == ZonElement) {
					return value;
				} else {
					@compileError("Unknown value type.");
				}
			},
		}
	}

	pub fn append(self: *const ZonElement, value: anytype) void {
		self.array.append(cubyz.allocator, createElementFromRandomType(value, self.array.allocator)) catch unreachable;
	}

	pub fn put(self: *const ZonElement, key: []const u8, value: anytype) void {
		const result = createElementFromRandomType(value, self.object.allocator);

		if(self.object.contains(key)) {
			self.getChild(key).deinit();

			self.object.put(key, result) catch unreachable;
			return;
		}

		self.object.put(self.object.cubyz.allocator.dupe(u8, key) catch unreachable, result) catch unreachable;
	}

	pub fn putOwnedString(self: *const ZonElement, key: []const u8, value: []const u8) void {
		const result = ZonElement{.stringOwned = self.object.cubyz.allocator.dupe(u8, value) catch unreachable};

		if(self.object.contains(key)) {
			self.getChild(key).deinit();

			self.object.put(key, result) catch unreachable;
			return;
		}

		self.object.put(self.object.cubyz.allocator.dupe(u8, key) catch unreachable, result) catch unreachable;
	}

	pub fn toSlice(self: *const ZonElement) []ZonElement {
		switch(self.*) {
			.array => |arr| {
				return arr.items;
			},
			else => return &.{},
		}
	}

	pub fn deinit(self: *const ZonElement) void {
		switch(self.*) {
			.int, .float, .bool, .null, .string => return,
			.stringOwned => {
				cubyz.allocator.free(self.stringOwned);
			},
			.array => {
				for(self.array.items) |*elem| {
					elem.deinit();
				}
				self.array.clearAndFree(cubyz.allocator);
				cubyz.allocator.destroy(self.array);
			},
			.object => {
				var iterator = self.object.iterator();
				while(true) {
					const elem = iterator.next() orelse break;
					cubyz.allocator.free(elem.key_ptr.*);
					elem.value_ptr.deinit();
				}
				self.object.clearAndFree();
				cubyz.allocator.destroy(self.object);
			},
		}
	}

	pub fn isNull(self: *const ZonElement) bool {
		return self.* == .null;
	}

	fn escape(list: *std.ArrayList(u8), string: []const u8) void {
		for(string) |char| {
			switch(char) {
				'\\' => list.appendSlice(cubyz.allocator, "\\\\") catch unreachable,
				'\n' => list.appendSlice(cubyz.allocator, "\\n") catch unreachable,
				'\"' => list.appendSlice(cubyz.allocator, "\\\"") catch unreachable,
				'\t' => list.appendSlice(cubyz.allocator, "\\t") catch unreachable,
				else => list.append(cubyz.allocator, char) catch unreachable,
			}
		}
	}
	fn writeTabs(list: *std.ArrayList(u8), tabs: u32) void {
		for(0..tabs) |_| {
			list.append(cubyz.allocator, '\t') catch unreachable;
		}
	}
	fn isValidIdentifierName(str: []const u8) bool {
		if(str.len == 0) return false;
		if(!std.ascii.isAlphabetic(str[0]) and str[0] != '_') return false;
		for(str[1..]) |c| {
			if(!std.ascii.isAlphanumeric(c) and c != '_') return false;
		}
		return true;
	}
	fn recurseToString(zon: ZonElement, list: *std.ArrayList(u8), tabs: u32, comptime visualCharacters: bool) void {
		switch(zon) {
			.int => |value| {
				list.writer().print("{d}", .{value}) catch unreachable;
			},
			.float => |value| {
				list.writer().print("{e}", .{value}) catch unreachable;
			},
			.bool => |value| {
				if(value) {
					list.appendSlice(cubyz.allocator, "true") catch unreachable;
				} else {
					list.appendSlice(cubyz.allocator, "false") catch unreachable;
				}
			},
			.null => {
				list.appendSlice(cubyz.allocator, "null") catch unreachable;
			},
			.string, .stringOwned => |value| {
				if(isValidIdentifierName(value)) {
					// Can use an enum literal:
					list.append(cubyz.allocator, '.') catch unreachable;
					list.appendSlice(cubyz.allocator, value) catch unreachable;
				} else {
					list.append(cubyz.allocator, '\"') catch unreachable;
					escape(list, value);
					list.append(cubyz.allocator, '\"') catch unreachable;
				}
			},
			.array => |array| {
				if(visualCharacters) list.append(cubyz.allocator, '.') catch unreachable;
				list.append(cubyz.allocator, '{') catch unreachable;
				for(array.items, 0..) |elem, i| {
					if(i != 0) {
						list.append(cubyz.allocator, ',') catch unreachable;
					}
					if(visualCharacters) list.append(cubyz.allocator, '\n') catch unreachable;
					if(visualCharacters) writeTabs(list, tabs + 1);
					recurseToString(elem, list, tabs + 1, visualCharacters);
				}
				if(visualCharacters and array.items.len != 0) list.append(cubyz.allocator, ',') catch unreachable;
				if(visualCharacters) list.append(cubyz.allocator, '\n') catch unreachable;
				if(visualCharacters) writeTabs(list, tabs);
				list.append(cubyz.allocator, '}') catch unreachable;
			},
			.object => |obj| {
				if(visualCharacters) list.append(cubyz.allocator, '.') catch unreachable;
				list.append(cubyz.allocator, '{') catch unreachable;
				var iterator = obj.iterator();
				var first: bool = true;
				while(true) {
					const elem = iterator.next() orelse break;
					if(!first) {
						list.append(cubyz.allocator, ',') catch unreachable;
					}
					if(visualCharacters) list.append(cubyz.allocator, '\n') catch unreachable;
					if(visualCharacters) writeTabs(list, tabs + 1);
					if(isValidIdentifierName(elem.key_ptr.*)) {
						if(visualCharacters) list.append(cubyz.allocator, '.') catch unreachable;
						list.appendSlice(elem.key_ptr.*) catch unreachable;
					} else {
						if(visualCharacters) list.append(cubyz.allocator, '@') catch unreachable;
						list.append(cubyz.allocator, '\"') catch unreachable;
						escape(list, elem.key_ptr.*);
						list.append(cubyz.allocator, '\"') catch unreachable;
					}
					if(visualCharacters) list.append(cubyz.allocator, ' ') catch unreachable;
					list.append(cubyz.allocator, '=') catch unreachable;
					if(visualCharacters) list.append(cubyz.allocator, ' ') catch unreachable;

					recurseToString(elem.value_ptr.*, list, tabs + 1, visualCharacters);
					first = false;
				}
				if(visualCharacters and !first) list.append(cubyz.allocator, ',') catch unreachable;
				if(visualCharacters) list.append(cubyz.allocator, '\n') catch unreachable;
				if(visualCharacters) writeTabs(list, tabs);
				list.append(cubyz.allocator, '}') catch unreachable;
			},
		}
	}
	pub fn toString(zon: ZonElement) []const u8 {
		var string: std.ArrayList(u8) = .{};
		recurseToString(zon, &string, 0, true);
		return string.toOwnedSlice(cubyz.allocator) catch unreachable;
	}

	/// Ignores all the visual characters(spaces, tabs and newlines) and allows adding a custom prefix(which is for example required by networking).
	pub fn toStringEfficient(zon: ZonElement, prefix: []const u8) []const u8 {
		var string: std.ArrayList(u8) = .{};
		string.appendSlice(cubyz.allocator, prefix) catch unreachable;
		recurseToString(zon, &string, 0, false);
		return string.toOwnedSlice(cubyz.allocator) catch unreachable;
	}

	pub fn parseFromString(string: []const u8) ZonElement {
		var index: u32 = 0;
		Parser.skipWhitespaceAndComments(string, &index);
		return Parser.parseElement(string, &index);
	}
};

const Parser = struct { // MARK: Parser
	/// All whitespaces from unicode 14.
	const whitespaces = [_][]const u8{"\u{0009}", "\u{000A}", "\u{000B}", "\u{000C}", "\u{000D}", "\u{0020}", "\u{0085}", "\u{00A0}", "\u{1680}", "\u{2000}", "\u{2001}", "\u{2002}", "\u{2003}", "\u{2004}", "\u{2005}", "\u{2006}", "\u{2007}", "\u{2008}", "\u{2009}", "\u{200A}", "\u{2028}", "\u{2029}", "\u{202F}", "\u{205F}", "\u{3000}"};

	fn skipWhitespaceAndComments(chars: []const u8, index: *u32) void {
		outerLoop: while(index.* < chars.len) {
			whitespaceLoop: for(whitespaces) |whitespace| {
				for(whitespace, 0..) |char, i| {
					if(char != chars[index.* + i]) {
						continue :whitespaceLoop;
					}
				}
				index.* += @intCast(whitespace.len);
				continue :outerLoop;
			}
			if(chars[index.*] == '/' and chars[index.* + 1] == '/') {
				while(chars[index.*] != '\n') {
					index.* += 1;
				}
				index.* += 1;
				continue :outerLoop;
			}
			// Next character is no whitespace.
			return;
		}
	}

	/// Assumes that the region starts with a number character ('+', '-', '.' or a digit).
	fn parseNumber(chars: []const u8, index: *u32) ZonElement {
		var sign: i2 = 1;
		if(chars[index.*] == '-') {
			sign = -1;
			index.* += 1;
		} else if(chars[index.*] == '+') {
			index.* += 1;
		}
		var intPart: i64 = 0;
		if(index.* + 1 < chars.len and chars[index.*] == '0' and chars[index.* + 1] == 'x') {
			// Parse hex int
			index.* += 2;
			while(index.* < chars.len) : (index.* += 1) {
				switch(chars[index.*]) {
					'0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
						intPart = (chars[index.*] - '0') +% intPart*%16;
					},
					'a', 'b', 'c', 'd', 'e', 'f' => {
						intPart = (chars[index.*] - 'a' + 10) +% intPart*%16;
					},
					'A', 'B', 'C', 'D', 'E', 'F' => {
						intPart = (chars[index.*] - 'A' + 10) +% intPart*%16;
					},
					else => {
						break;
					},
				}
			}
			return .{.int = sign*intPart};
		}
		while(index.* < chars.len) : (index.* += 1) {
			switch(chars[index.*]) {
				'0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
					intPart = (chars[index.*] - '0') +% intPart*%10;
				},
				else => {
					break;
				},
			}
		}
		if(index.* >= chars.len or (chars[index.*] != '.' and chars[index.*] != 'e' and chars[index.*] != 'E')) { // This is an int
			return .{.int = sign*intPart};
		}
		// So this is a float apparently.

		var floatPart: f64 = 0;
		var currentFactor: f64 = 0.1;
		if(chars[index.*] == '.') {
			index.* += 1;
			while(index.* < chars.len) : (index.* += 1) {
				switch(chars[index.*]) {
					'0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
						floatPart += @as(f64, @floatFromInt(chars[index.*] - '0'))*currentFactor;
						currentFactor *= 0.1;
					},
					else => {
						break;
					},
				}
			}
		}
		var exponent: i64 = 0;
		var exponentSign: i2 = 1;
		if(index.* < chars.len and (chars[index.*] == 'e' or chars[index.*] == 'E')) {
			index.* += 1;
			if(index.* < chars.len and chars[index.*] == '-') {
				exponentSign = -1;
				index.* += 1;
			} else if(index.* < chars.len and chars[index.*] == '+') {
				index.* += 1;
			}
			while(index.* < chars.len) : (index.* += 1) {
				switch(chars[index.*]) {
					'0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
						exponent = (chars[index.*] - '0') +% exponent*%10;
					},
					else => {
						break;
					},
				}
			}
		}
		return .{.float = @as(f64, @floatFromInt(sign))*(@as(f64, @floatFromInt(intPart)) + floatPart)*std.math.pow(f64, 10, @as(f64, @floatFromInt(exponentSign*exponent)))};
	}

	fn parseString(chars: []const u8, index: *u32) []const u8 {
		var builder: std.ArrayList(u8) = .{};
		while(index.* < chars.len) : (index.* += 1) {
			if(chars[index.*] == '\"') {
				index.* += 1;
				break;
			} else if(chars[index.*] == '\\') {
				index.* += 1;
				if(index.* >= chars.len)
					break;
				switch(chars[index.*]) {
					't' => {
						builder.append(cubyz.allocator, '\t') catch unreachable;
					},
					'n' => {
						builder.append(cubyz.allocator, '\n') catch unreachable;
					},
					'r' => {
						builder.append(cubyz.allocator, '\r') catch unreachable;
					},
					else => {
						builder.append(cubyz.allocator, chars[index.*]) catch unreachable;
					},
				}
			} else {
				builder.append(cubyz.allocator, chars[index.*]) catch unreachable;
			}
		}
		return builder.toOwnedSlice(cubyz.allocator) catch unreachable;
	}

	fn parseIdentifierOrStringOrEnumLiteral(chars: []const u8, index: *u32) []const u8 {
		var builder: std.ArrayList(u8) = .{};
		if(index.* == chars.len) return &.{};
		if(chars[index.*] == '@') {
			index.* += 1;
		}
		if(index.* == chars.len) return &.{};
		if(chars[index.*] == '"') {
			index.* += 1;
			return parseString(chars, index);
		}
		while(index.* < chars.len) : (index.* += 1) {
			switch(chars[index.*]) {
				'a'...'z', 'A'...'Z', '0'...'9', '_' => |c| builder.append(cubyz.allocator, c) catch unreachable,
				else => break,
			}
		}
		return builder.toOwnedSlice(cubyz.allocator) catch unreachable;
	}

	fn parseArray(chars: []const u8, index: *u32) ZonElement {
		const list = cubyz.allocator.create(std.ArrayList(ZonElement)) catch unreachable;
		list.* = .{};
		while(index.* < chars.len) {
			skipWhitespaceAndComments(chars, index);
			if(index.* >= chars.len) break;
			if(chars[index.*] == '}') {
				index.* += 1;
				return .{.array = list};
			}
			list.append(cubyz.allocator, parseElement(chars, index)) catch unreachable;
			skipWhitespaceAndComments(chars, index);
			if(index.* < chars.len and chars[index.*] == ',') {
				index.* += 1;
			}
		}
		return .{.array = list};
	}

	fn parseObject(chars: []const u8, index: *u32) ZonElement {
		const map = cubyz.allocator.create(std.StringHashMap(ZonElement)) catch unreachable;
		map.* = .init(cubyz.allocator);
		while(index.* < chars.len) {
			skipWhitespaceAndComments(chars, index);
			if(index.* >= chars.len) break;
			if(chars[index.*] == '}') {
				index.* += 1;
				return .{.object = map};
			}
			if(chars[index.*] == '.') index.* += 1; // Just ignoring the dot in front of identifiers, the file might as well not have for all I care.
			const key: []const u8 = parseIdentifierOrStringOrEnumLiteral(chars, index);
			skipWhitespaceAndComments(chars, index);
			while(index.* < chars.len and chars[index.*] != '=') {
				index.* += 1;
			}
			index.* += 1;
			skipWhitespaceAndComments(chars, index);
			const value: ZonElement = parseElement(chars, index);
			if(map.fetchPut(key, value) catch unreachable) |old| {
				cubyz.allocator.free(old.key);
				old.value.deinit();
			}
			skipWhitespaceAndComments(chars, index);
			if(index.* < chars.len and chars[index.*] == ',') {
				index.* += 1;
			}
		}
		return .{.object = map};
	}

	/// Assumes that the region starts with a non-space character.
	fn parseElement(chars: []const u8, index: *u32) ZonElement {
		if(index.* >= chars.len) {
			return .null;
		}
		sw: switch(chars[index.*]) {
			'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '-' => {
				return parseNumber(chars, index);
			},
			't' => { // Value can only be true.
				index.* += 4;
				return .{.bool = true};
			},
			'f' => { // Value can only be false.
				index.* += 5;
				return .{.bool = false};
			},
			'n' => { // Value can only be null.
				index.* += 4;
				return .{.null = {}};
			},
			'\"' => {
				index.* += 1;
				return .{.stringOwned = parseString(chars, index)};
			},
			'.' => {
				index.* += 1;
				if(chars[index.*] == '{') continue :sw '{';
				if(std.ascii.isDigit(chars[index.*])) {
					index.* -= 1;
					return parseNumber(chars, index);
				}
				return .{.stringOwned = parseIdentifierOrStringOrEnumLiteral(chars, index)};
			},
			'{' => {
				index.* += 1;
				skipWhitespaceAndComments(chars, index);
				var foundEqualSign: bool = false;
				var i: usize = index.*;
				while(i < chars.len) : (i += 1) {
					if(chars[i] == '"') {
						i += 1;
						while(chars[i] != '"' and i < chars.len) {
							if(chars[i] == '\\') i += 1;
							i += 1;
						}
						continue;
					}
					if(chars[i] == ',' or chars[i] == '{') break;
					if(chars[i] == '=') {
						foundEqualSign = true;
						break;
					}
				}
				if(foundEqualSign) {
					return parseObject(chars, index);
				} else {
					return parseArray(chars, index);
				}
			},
			else => {
				index.* += 1;
				return .null;
			},
		}
	}
};