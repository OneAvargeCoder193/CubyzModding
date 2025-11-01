const cubyz = @import("cubyz");
const vec = cubyz.vec;
const Vec2f = vec.Vec2f;

const gui = cubyz.gui;
const GuiComponent = gui.GuiComponent;

const VerticalList = @This();

index: u32,

pub fn init(pos: Vec2f, maxHeight: f32, padding: f32) VerticalList {
	return .{
		.index = initVerticalListImpl(pos[0], pos[1], maxHeight, padding),
	};
}

pub fn deinit(self: VerticalList) void {
	self.toComponent().deinit();
}

pub fn toComponent(self: VerticalList) GuiComponent {
	return .{.verticalList = self};
}

pub fn add(self: VerticalList, _other: anytype) void {
	var other: gui.GuiComponent = undefined;
	if(@TypeOf(_other) == GuiComponent) {
		other = _other;
	} else {
		other = _other.toComponent();
	}
	addVerticalListImpl(self.index, other.index());
}

pub fn finish(self: VerticalList, alignment: gui.Alignment) void {
	finishVerticalListImpl(self.index, @intFromEnum(alignment));
}

extern fn initVerticalListImpl(posX: f32, posY: f32, maxHeight: f32, padding: f32) u32;
extern fn addVerticalListImpl(index: u32, other: u32) void;
extern fn finishVerticalListImpl(index: u32, alignment: u32) void;