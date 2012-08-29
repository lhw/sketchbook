using Gtk;

public class LightControlApplet : Window {
	private StatusIcon tray_icon;
	private Menu menu_system;

	public LightControlApplet() {
		tray_icon = new StatusIcon.from_stock(Stock.DIALOG_INFO);
		tray_icon.set_tooltip_text("Light Control");
		tray_icon.set_visible(true);


		//tray_icon.activate.connect(system_menu);
	}

	public static int main(string[] args) {
		Gtk.init(ref args);
		var applet = new LightControlApplet();
		applet.hide();
		Gtk.main();
		return 0;
	}
}
