# libnotify4d
A D binding for libnotify  
  
  
## Requirements

* libnotify

  
  
## Example
### Send a notification

```D
import libnotify4d;

void main() {
  Notification notification = new Notification("Test notification", "body");
  notification.show;
}
```

  
  
### Open Browser by clicking action button
You can see this example at `example/openbrowser`  
  
```D
import libnotify4d;

void main() {
  Notification notification = new Notification("Test notification", "body");
  string       url          = "https://google.com";

  // add callback
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
```

  
  
# LICENSE
Copyright (C) 2017, alphaKAI  
This library is released under the MIT LICENSE.  
Please see `LICENSE` for details  