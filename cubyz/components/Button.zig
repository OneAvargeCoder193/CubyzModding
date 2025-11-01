const cubyz = @import("cubyz");
const vec = cubyz.vec;
const Vec2f = vec.Vec2f;

const gui = cubyz.gui;
const GuiComponent = gui.GuiComponent;

const Button = @This();

index: u32,

pub fn initText(pos: Vec2f, width: f32, text: []const u8, callback: ?fn() void) Button {
	const callbackName = cubyz.callback.registerCallback(callback, struct{
		fn wrap(func: ?fn() void) fn(u32) callconv(.{ .wasm_mvp = .{} }) void {
			return struct{
				fn function(_: u32) callconv(.{ .wasm_mvp = .{} }) void {
					if(func == null) return;
					func.?();
				}
			}.function;
		}
	}.wrap);
	return .{
		.index = initTextButtonImpl(pos[0], pos[1], width, text.ptr, @intCast(text.len), callbackName.ptr, @intCast(callbackName.len)),
	};
}

pub fn deinit(self: Button) void {
	self.toComponent().deinit();
}

pub fn toComponent(self: Button) GuiComponent {
	return .{.button = self};
}

extern fn initTextButtonImpl(posX: f32, posY: f32, width: f32, textPtr: [*]const u8, textLen: u32, callbackPtr: [*]const u8, callbackLen: u32) u32;