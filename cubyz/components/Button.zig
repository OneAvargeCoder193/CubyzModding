const cubyz = @import("cubyz");
const vec = cubyz.vec;
const Vec2f = vec.Vec2f;

const gui = cubyz.gui;
const GuiComponent = gui.GuiComponent;

const graphics = cubyz.graphics;
const Texture = graphics.Texture;

const Button = @This();

index: u32,

pub fn initText(pos: Vec2f, width: f32, text: []const u8, callback: ?fn() void) Button {
	const callbackName = cubyz.callback.registerCallback(wrap(callback));
	return .{
		.index = initTextButtonImpl(pos[0], pos[1], width, text.ptr, text.len, callbackName.ptr, callbackName.len),
	};
}

pub fn initIcon(pos: Vec2f, size: Vec2f, iconTexture: Texture, hasShadow: bool, callback: ?fn() void) Button {
	const callbackName = cubyz.callback.registerCallback(wrap(callback));
	return .{
		.index = initIconButtonImpl(pos[0], pos[1], size[0], size[1], iconTexture.id, hasShadow, callbackName.ptr, callbackName.len),
	};
}

pub fn deinit(self: Button) void {
	self.toComponent().deinit();
}

fn wrap(func: ?fn() void) fn(u32) callconv(.{ .wasm_mvp = .{} }) void {
	return struct{
		fn function(_: u32) callconv(.{ .wasm_mvp = .{} }) void {
			if(func == null) return;
			func.?();
		}
	}.function;
}

pub fn toComponent(self: Button) GuiComponent {
	return .{.button = self};
}

extern fn initTextButtonImpl(posX: f32, posY: f32, width: f32, textPtr: [*]const u8, textLen: u32, callbackPtr: [*]const u8, callbackLen: u32) u32;
extern fn initIconButtonImpl(posX: f32, posY: f32, sizeX: f32, sizeY: f32, texture: u32, hasShadow: bool, callbackPtr: [*]const u8, callbackLen: u32) u32;