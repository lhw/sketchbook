//valac --pkg gio-2.0 --pkg libsoup-2.4 --pkg json-glib-1.0 --pkg posix light-control.vala
using Soup;
using Json;
using Posix;

[DBus (name = "de.ring0.lhw.light")]
public class Light : GLib.Object {
	SessionSync session = new SessionSync();

	public bool switch_on(int channel, int device) {
		return send_switch(channel, device, true);
	} 
	public bool switch_off(int channel, int device) {
		return send_switch(channel, device, false);
	}
	private bool send_switch(int channel, int device, bool status) {
		string uri = "http://192.168.1.11/?c=%d&d=%d&s=%s".printf(channel, device, status ? "on" : "off");
		Message msg = new Message("GET", uri);
		session.send_message(msg);
		try {
			var p = new Parser();
			p.load_from_data((string)msg.response_body.flatten().data, -1);
			var root = p.get_root().get_object();
			return root.get_boolean_member("result");
		} catch (Error e) {
			return false;
		}
	}

	static void on_bus_aquired(DBusConnection con) {
		try {
			Light l = new Light();
			con.register_object("/de/ring0/lhw/light", l);
		}
		catch(IOError e) {
			syslog(LOG_ERR, e.message);
		}
	}
	static void main(string[] args) {
		pid_t pid, sid;

		pid = fork();
		if(pid < 0)
			exit(EXIT_FAILURE);
		if(pid > 0)
			exit(EXIT_SUCCESS);

		umask(0);
		openlog(args[0],LOG_NOWAIT|LOG_PID,LOG_USER);
		syslog(LOG_NOTICE, "Successfully started daemon\n");
		sid = setsid();
		if(sid < 0) {
			syslog(LOG_ERR, "Could not create process group\n");
			exit(EXIT_FAILURE);
		}
		close(STDIN_FILENO);
		close(STDOUT_FILENO);
		close(STDERR_FILENO);

		Bus.own_name(BusType.SESSION, "de.ring0.lhw.light", BusNameOwnerFlags.NONE, on_bus_aquired, () => {}, () => syslog(LOG_ERR, "Failed to connect to session dbus"));
		new MainLoop().run();
		exit(EXIT_SUCCESS);
	}
}
