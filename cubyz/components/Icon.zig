const cubyz = @import("cubyz");
const vec = cubyz.vec;
const Vec2f = vec.Vec2f;

const gui = cubyz.gui;
const GuiComponent = gui.GuiComponent;

const graphics = cubyz.graphics;
const Texture = graphics.Texture;

const Icon = @This();

index: u32,

pub fn init(pos: Vec2f, size: Vec2f, texture: Texture, hasShadow: bool) Icon {
	return .{
		.index = initIconImpl(pos[0], pos[1], size[0], size[1], texture.id, hasShadow),
	};
}

pub fn deinit(self: Icon) void {
	self.toComponent().deinit();
}

pub fn toComponent(self: Icon) GuiComponent {
	return .{.icon = self};
}

extern fn initIconImpl(posX: f32, posY: f32, sizeX: f32, sizeY: f32, textureId: u32, hasShadow: bool) u32;