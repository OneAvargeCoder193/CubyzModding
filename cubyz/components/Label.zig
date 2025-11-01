const cubyz = @import("cubyz");
const vec = cubyz.vec;
const Vec2f = vec.Vec2f;

const gui = cubyz.gui;
const GuiComponent = gui.GuiComponent;

const Label = @This();

index: u32,

pub fn init(pos: Vec2f, maxWidth: f32, text: []const u8, alignment: gui.Alignment) Label {
	return .{
		.index = initLabelImpl(pos[0], pos[1], maxWidth, text.ptr, @intCast(text.len), @intFromEnum(alignment)),
	};
}

pub fn deinit(self: Label) void {
	self.toComponent().deinit();
}

pub fn toComponent(self: Label) GuiComponent {
	return .{.label = self};
}

extern fn initLabelImpl(posX: f32, posY: f32, maxWidth: f32, textPtr: [*]const u8, textLen: u32, alignment: u32) u32;