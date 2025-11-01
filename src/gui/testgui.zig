const cubyz = @import("cubyz");
const vec = cubyz.vec;
const Vec2f = vec.Vec2f;
const gui = cubyz.gui;
const GuiComponent = gui.GuiComponent;
const Label = GuiComponent.Label;

const padding: f32 = 8;

pub var window = gui.WindowConfig{
	.contentSize = Vec2f{128, 256},
	.scale = 0.75,
	.closeIfMouseIsGrabbed = true,
};

pub const id = "testgui";

pub fn open() void {
	const label = Label.init(.{padding, 16 + padding}, 300, "LABEL", .left);
	gui.setRootComponent(id, label.toComponent(), padding);
}

pub fn close() void {
	if(gui.getRootComponent(id)) |root| {
		root.deinit();
	}
}