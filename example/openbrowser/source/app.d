import libnotify4d;

void main() {
  Notification notification = new Notification("Test notification", "body");
  string       url          = "https://google.com";

  notification.addAction("click here", (NotifyNotification* notification, char* action, string* user_data) {
                                          import std.process;
                                          string url = *cast(string*)user_data;
                                          executeShell("xdg-open " ~ url);
                                       }, &url);

  notification.addAction("click here2", (NotifyNotification* notification, char* action, string* user_data) {
                                          import std.process;
                                          string url = *cast(string*)user_data;
                                          executeShell("xdg-open " ~ url);
                                       }, &url);
  notification.show;
}

