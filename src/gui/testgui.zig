const cubyz = @import("cubyz");
const chat = cubyz.chat;
const vec = cubyz.vec;
const Vec2f = vec.Vec2f;
const gui = cubyz.gui;
const GuiComponent = gui.GuiComponent;
const VerticalList = GuiComponent.VerticalList;
const Button = GuiComponent.Button;
const Label = GuiComponent.Label;
const CheckBox = GuiComponent.CheckBox;
const TextInput = GuiComponent.TextInput;

const padding: f32 = 8;

pub var window = gui.WindowConfig{
	.contentSize = Vec2f{128, 256},
	.scale = 0.75,
	.closeIfMouseIsGrabbed = true,
};

pub const id = "testgui";

var textInput: TextInput = undefined;

pub fn open() void {
	textInput = TextInput.init(.{0, 0}, 128, 16*4 + 8, "Test Wasm Text Input", onNewline, .{.onUp = onUp, .onDown = onDown});
	const list = VerticalList.init(.{padding, 16 + padding}, 300, 16);
	list.add(Button.initText(.{0, 0}, 128, "Test Wasm Button", sendMessage));
	list.add(Label.init(.{0, 0}, 128, "Test Wasm Label", .center));
	list.add(CheckBox.init(.{0, 0}, 128, "Test Wasm Checkbox", false, checkBoxChanged));
	list.add(textInput);
	list.finish(.center);
	gui.setRootComponent(id, list.toComponent(), padding);
}

fn sendMessage() void {
	chat.showMessage("Button clicked", .{});
}

fn checkBoxChanged(checked: bool) void {
	chat.showMessage("Checkbox changed to: {}", .{checked});
}

fn onNewline() void {
	textInput.clear();
}

fn onUp() void {
	textInput.setText("You pressed up");
}

fn onDown() void {
	textInput.setText("You pressed down");
}

pub fn close() void {
	if(gui.getRootComponent(id)) |root| {
		root.deinit();
	}
}