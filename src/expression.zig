const std = @import("std");
const cubyz = @import("cubyz");

const TokenType = enum {
	ident,
	number,
	op,
	lparen,
	rparen,
};

const Token = struct {
	typ: TokenType,
	value: []const u8,
};

const Op = enum {plus, minus, mul, div, negate, greater, less, greaterEqual, lessEqual, equal, notEqual, @"and", @"or", @"not"};
const ShuntingYardToken = union(enum) {
	ident: []const u8,
	number: f64,
	op: Op,
};

fn isOperatorChar(c: u8) bool {
	return std.mem.indexOf(u8, "+-*/<>!", &[_]u8{c}) != null;
}

fn tokenize(allocator: std.mem.Allocator, input: []const u8) ![]const Token {
	var list: std.ArrayList(Token) = .{};
	var i: usize = 0;
	const len = input.len;

	while (i < len) : (i += 1) {
        const c = input[i];
        if (std.ascii.isWhitespace(c)) continue;

        if (std.ascii.isAlphabetic(c)) {
            const start = i;
            while (i < len and (std.ascii.isAlphanumeric(input[i]) or input[i] == '_')) : (i += 1) {}
            try list.append(allocator, Token{ .typ = .ident, .value = input[start..i] });
            i -= 1;
            continue;
        }

        if (std.ascii.isDigit(c)) {
            const start = i;
            while (i < len and (std.ascii.isDigit(input[i]) or input[i] == '.')) : (i += 1) {}
            try list.append(allocator, Token{ .typ = .number, .value = input[start..i] });
            i -= 1;
            continue;
        }

        if (c == '(') {
			try list.append(allocator, Token{ .typ = .lparen, .value = input[i..i+1] });
		} else if (c == ')') {
			try list.append(allocator, Token{ .typ = .rparen, .value = input[i..i+1] });
		} else if (i + 1 < len and
			((c == '&' and input[i + 1] == '&') or
			(c == '|' and input[i + 1] == '|') or
			(c == '<' and input[i + 1] == '=') or
			(c == '>' and input[i + 1] == '=') or
			(c == '=' and input[i + 1] == '=') or
			(c == '!' and input[i + 1] == '='))) {
            try list.append(allocator, Token{ .typ = .op, .value = input[i..i+2] });
            i += 1;
        } else if (isOperatorChar(c)) {
			try list.append(allocator, Token{ .typ = .op, .value = input[i..i+1] });
		} else {
			return error.InvalidCharacter;
		}
    }

	return list.toOwnedSlice(allocator);
}

fn precedence(op: ShuntingYardToken) i32 {
	return switch (op) {
		.op => |o| switch (o) {
			.@"or" => 1,
			.@"and" => 2,
			.equal, .notEqual => 3,
			.greater, .less, .greaterEqual, .lessEqual => 3,
			.plus, .minus => 4,
			.mul, .div => 5,
			.negate, .@"not" => 6,
		},
		else => 0,
	};
}

fn mapOp(value: []const u8, unary: bool) Op {
	if (unary and std.mem.eql(u8, value, "-")) return Op.negate;
	if (std.mem.eql(u8, value, "+")) return Op.plus;
	if (std.mem.eql(u8, value, "-")) return Op.minus;
	if (std.mem.eql(u8, value, "*")) return Op.mul;
	if (std.mem.eql(u8, value, "/")) return Op.div;
	if (std.mem.eql(u8, value, ">")) return Op.greater;
	if (std.mem.eql(u8, value, "<")) return Op.less;
	if (std.mem.eql(u8, value, ">=")) return Op.greaterEqual;
	if (std.mem.eql(u8, value, "<=")) return Op.lessEqual;
	if (std.mem.eql(u8, value, "==")) return Op.equal;
	if (std.mem.eql(u8, value, "!=")) return Op.notEqual;
	if (std.mem.eql(u8, value, "&&")) return Op.@"and";
	if (std.mem.eql(u8, value, "||")) return Op.@"or";
	if (std.mem.eql(u8, value, "!")) return Op.@"not";
	return Op.plus; // fallback
}

fn shuntingYard(allocator: std.mem.Allocator, tokens: []const Token) ![]ShuntingYardToken {
	var output: std.ArrayList(ShuntingYardToken) = .{};
	var ops: std.ArrayList(Token) = .{};

	var prevWasOperatorOrParen: bool = true; // start-of-expression counts as "operator"

	for (tokens) |t| {
		switch (t.typ) {
			.number => {
				const val = try std.fmt.parseFloat(f64, t.value);
				try output.append(allocator, ShuntingYardToken{ .number = val });
				prevWasOperatorOrParen = false;
			},
			.ident => {
				try output.append(allocator, ShuntingYardToken{ .ident = t.value });
				prevWasOperatorOrParen = false;
			},
			.op => {
				const unary = prevWasOperatorOrParen and (std.mem.eql(u8, t.value, "-") or std.mem.eql(u8, t.value, "!"));
				const curOp = ShuntingYardToken{ .op = mapOp(t.value, unary) };

				while (ops.items.len > 0 and ops.items[ops.items.len - 1].typ == .op) {
					const top = ops.items[ops.items.len - 1];
					const topOp = ShuntingYardToken{ .op = mapOp(top.value, false) };
					if (precedence(topOp) >= precedence(curOp)) {
						_ = ops.pop() orelse break;
						try output.append(allocator, topOp);
					} else break;
				}
				try ops.append(allocator, t);
				prevWasOperatorOrParen = true;
			},
			.lparen => {
				try ops.append(allocator, t);
				prevWasOperatorOrParen = true;
			},
			.rparen => {
				while (ops.items.len > 0 and ops.items[ops.items.len - 1].typ != .lparen) {
					const top = ops.pop() orelse break;
					try output.append(allocator, ShuntingYardToken{ .op = mapOp(top.value, false) });
				}
				if (ops.items.len == 0) return error.MismatchedParentheses;
				_ = ops.pop(); // remove '('
				prevWasOperatorOrParen = false;
			},
		}
	}

	while (ops.items.len > 0) {
		const t = ops.pop() orelse break;
		if (t.typ == .lparen) return error.MismatchedParentheses;
		try output.append(allocator, ShuntingYardToken{ .op = mapOp(t.value, false) });
	}

	return output.toOwnedSlice(allocator);
}

const Value = union(enum) {
	number: f64,
	boolean: bool,

	pub fn init(value: anytype) Value {
		std.debug.assert(
			@TypeOf(value) == i32 or 
			@TypeOf(value) == i64 or 
			@TypeOf(value) == f32 or 
			@TypeOf(value) == f64 or 
			@TypeOf(value) == comptime_int or 
			@TypeOf(value) == comptime_float or 
			@TypeOf(value) == bool
		);

		return switch(@typeInfo(@TypeOf(value))) {
			.int => .{.number = @floatFromInt(value)},
			.float => .{.number = @floatCast(value)},
			.comptime_int, .comptime_float => .{.number = @as(f64, value)},
			.bool => .{.boolean = value},
			else => unreachable,
		};
	}

	pub fn getNumber(self: Value) ExpressionError!f64 {
		if(self == .number) {
			return self.number;
		}
		return ExpressionError.IllegalType;
	}

	pub fn getBoolean(self: Value) ExpressionError!bool {
		if(self == .boolean) {
			return self.boolean;
		}
		return ExpressionError.IllegalType;
	}

	pub fn toString(self: Value, allocator: std.mem.Allocator) []const u8 {
		return switch(self) {
			.number => |num| std.fmt.allocPrint(allocator, "{d}\n", .{num}) catch unreachable,
			.boolean => |boolean| allocator.dupe(u8, if(boolean) "true" else "false") catch unreachable,
		};
	}
};
pub const ExpressionError = error { InvalidCharacter, InvalidEquation, IllegalName, IllegalType };

fn getArgument(arguments: anytype, _name: []const u8) ExpressionError!Value {
	const Names = comptime blk: {
		const info = @typeInfo(@TypeOf(arguments));
		const fields = info.@"struct".fields;
		var enumFields: [fields.len]std.builtin.Type.EnumField = undefined;
		for(fields, 0..) |field, i| {
			enumFields[i] = .{
				.name = field.name,
				.value = i,
			};
		}

		break :blk @Type(.{.@"enum" = .{
			.tag_type = u32,
			.fields = &enumFields,
			.decls = &.{},
			.is_exhaustive = true,
		}});
	};

	const name = std.meta.stringToEnum(Names, _name) orelse return ExpressionError.IllegalName;
	switch(name) {
		inline else => |comptimeName| {
			const field = @field(arguments, @tagName(comptimeName));
			return Value.init(field);
		}
	}
}

pub fn executeExpression(equation: []const u8, arguments: anytype) ExpressionError!Value {
	const tokens = tokenize(cubyz.allocator, equation) catch {
		return ExpressionError.InvalidCharacter;
	};
	defer cubyz.allocator.free(tokens);

	const rpn = shuntingYard(cubyz.allocator, tokens) catch {
		return ExpressionError.InvalidEquation;
	};
	defer cubyz.allocator.free(rpn);

	var stack: std.ArrayList(Value) = .{};
	defer stack.deinit(cubyz.allocator);

	for(rpn) |token| {
		switch(token) {
			.ident => |identifier| stack.append(cubyz.allocator, try getArgument(arguments, identifier)) catch unreachable,
			.number => |num| stack.append(cubyz.allocator, Value.init(num)) catch unreachable,
			.op => |operand| {
				switch(operand) {
					.plus => {
						const a = try stack.pop().?.getNumber();
						const b = try stack.pop().?.getNumber();
						stack.append(cubyz.allocator, Value.init(b + a)) catch unreachable;
					},
					.minus => {
						const a = try stack.pop().?.getNumber();
						const b = try stack.pop().?.getNumber();
						stack.append(cubyz.allocator, Value.init(b - a)) catch unreachable;
					},
					.mul => {
						const a = try stack.pop().?.getNumber();
						const b = try stack.pop().?.getNumber();
						stack.append(cubyz.allocator, Value.init(b * a)) catch unreachable;
					},
					.div => {
						const a = try stack.pop().?.getNumber();
						const b = try stack.pop().?.getNumber();
						stack.append(cubyz.allocator, Value.init(b / a)) catch unreachable;
					},
					.negate => {
						const num = try stack.pop().?.getNumber();
						stack.append(cubyz.allocator, Value.init(-num)) catch unreachable;
					},
					.greater => {
						const a = try stack.pop().?.getNumber();
						const b = try stack.pop().?.getNumber();
						stack.append(cubyz.allocator, Value.init(b > a)) catch unreachable;
					},
					.less => {
						const a = try stack.pop().?.getNumber();
						const b = try stack.pop().?.getNumber();
						stack.append(cubyz.allocator, Value.init(b < a)) catch unreachable;
					},
					.greaterEqual => {
						const a = try stack.pop().?.getNumber();
						const b = try stack.pop().?.getNumber();
						stack.append(cubyz.allocator, Value.init(b >= a)) catch unreachable;
					},
					.lessEqual => {
						const a = try stack.pop().?.getNumber();
						const b = try stack.pop().?.getNumber();
						stack.append(cubyz.allocator, Value.init(b <= a)) catch unreachable;
					},
					.equal => {
						const aValue = stack.pop().?;
						switch(aValue) {
							.number => |a| {
								const b = try stack.pop().?.getNumber();
								stack.append(cubyz.allocator, Value.init(b == a)) catch unreachable;
							},
							.boolean => |a| {
								const b = try stack.pop().?.getBoolean();
								stack.append(cubyz.allocator, Value.init(b == a)) catch unreachable;
							},
						}
					},
					.notEqual => {
						const aValue = stack.pop().?;
						switch(aValue) {
							.number => |a| {
								const b = try stack.pop().?.getNumber();
								stack.append(cubyz.allocator, Value.init(b != a)) catch unreachable;
							},
							.boolean => |a| {
								const b = try stack.pop().?.getBoolean();
								stack.append(cubyz.allocator, Value.init(b != a)) catch unreachable;
							},
						}
					},
					.@"and" => {
						const a = try stack.pop().?.getBoolean();
						const b = try stack.pop().?.getBoolean();
						stack.append(cubyz.allocator, Value.init(b and a)) catch unreachable;
					},
					.@"or" => {
						const a = try stack.pop().?.getBoolean();
						const b = try stack.pop().?.getBoolean();
						stack.append(cubyz.allocator, Value.init(b or a)) catch unreachable;
					},
					.@"not" => {
						const boolean = try stack.pop().?.getBoolean();
						stack.append(cubyz.allocator, Value.init(!boolean)) catch unreachable;
					},
				}
			},
		}
	}

	return stack.pop().?;
}