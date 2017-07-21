module libnotify4d.notify;
import std.string;
import std.exception;
import glib.gtypes,
       glib.glist;

extern (C) {
  gboolean notify_init(const char* app_name);
  void     notify_uninit();
  gboolean notify_is_initted();

  char* notify_get_app_name();
  void  notify_set_app_name(const char* app_name);

  GList* notify_get_server_caps();

  gboolean notify_get_server_info(char** ret_name,
                                  char** ret_vender,
                                  char** ret_version,
                                  char** ret_spec_version);
}

class Notify {
  this (string name) {
    auto ret = Notify.init(name);
    enforce(ret, "Failed to initailize notify with notify_init");
  }

  ~this () {
    Notify.uninit;
  }

  static bool init(string app_name) {
    return cast(bool)notify_init(app_name.toStringz);
  }

  static void uninit() {
    notify_uninit;
  }

  static bool isInitted() {
    return cast(bool)notify_is_initted;
  }

  static string getAppName() {
    return cast(string)notify_get_app_name().fromStringz;
  }

  static string[] getServerCaps() {
    string[] ret;
    auto r = notify_get_server_caps;

    while (r !is null) {
  	  ret ~= cast(string)(cast(char*)r.data).fromStringz;
	  	r = g_list_next(r);
	  }

    return ret;
  }

  static string[string] getServerInfo() {
    string[string] ret;
    char* ret_name,
          ret_vender,
          ret_version,
          ret_spec_version;

    bool r = cast(bool)notify_get_server_info(&ret_name,
                                              &ret_vender,
                                              &ret_version,
                                              &ret_spec_version);

    if (r) {
      ret["ret_name"]         = cast(string)ret_name.fromStringz;
      ret["ret_vender"]       = cast(string)ret_vender.fromStringz;
      ret["ret_version"]      = cast(string)ret_version.fromStringz;
      ret["ret_spec_version"] = cast(string)ret_spec_version.fromStringz;
    }

    return ret;
  }
}