const cubyz = @import("cubyz");
const vec = cubyz.vec;
const Vec2f = vec.Vec2f;

const gui = cubyz.gui;
const GuiComponent = gui.GuiComponent;

const Button = @This();

index: u32,

pub fn initText(pos: Vec2f, width: f32, text: []const u8) Button {
	return .{
		.index = initTextButtonImpl(pos[0], pos[1], width, text.ptr, @intCast(text.len)),
	};
}

pub fn deinit(self: Button) void {
	self.toComponent().deinit();
}

pub fn toComponent(self: Button) GuiComponent {
	return .{.button = self};
}

extern fn initTextButtonImpl(posX: f32, posY: f32, width: f32, textPtr: [*]const u8, textLen: u32) u32;