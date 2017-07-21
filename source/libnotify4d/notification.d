module libnotify4d.notification;
import std.string,
       std.traits;
import core.memory;
import gobject;
import glib.gvariant,
       glib.gerror,
       glib.gtypes,
       glib.gmain;
import libnotify4d.notify;

extern (C) {
  struct NotifyNotificationPrivate;

  struct NotifyNotification {
    GObject                    parent_object;
    NotifyNotificationPrivate *priv;
  }

  struct NotifyNotificationClass {
    GObjectClass    parent_class;

    /* Signals */
    void function (NotifyNotification*) closed;
  }


  /**
  * NotifyUrgency:
  * @NOTIFY_URGENCY_LOW: Low urgency. Used for unimportant notifications.
  * @NOTIFY_URGENCY_NORMAL: Normal urgency. Used for most standard notifications.
  * @NOTIFY_URGENCY_CRITICAL: Critical urgency. Used for very important notifications.
  *
  * The urgency level of the notification.
  */
  enum NotifyUrgency {
    NOTIFY_URGENCY_LOW,
    NOTIFY_URGENCY_NORMAL,
    NOTIFY_URGENCY_CRITICAL,
  }

  /**
  * NotifyActionCallback:
  * @notification:
  * @action:
  * @user_data:
  *
  * An action callback function.
  */
  alias NotifyActionCallback = void function (NotifyNotification *notification,
                                              char               *action,
                                              gpointer            user_data);

  /**
  * NOTIFY_ACTION_CALLBACK:
  * @func: The function to cast.
  *
  * A convenience macro for casting a function to a #NotifyActionCallback. This
  * is much like G_CALLBACK().
  */
  NotifyActionCallback NOTIFY_ACTION_CALLBACK (F)(F func) if (isCallable!F && arity!func == 3) {
    return cast(NotifyActionCallback)(func);
  }

  NotifyNotification* notify_notification_new                  (const char         *summary,
                                                                const char         *_body,
                                                                const char         *icon);

  gboolean            notify_notification_update                (NotifyNotification *notification,
                                                                 const char         *summary,
                                                                 const char         *_body,
                                                                 const char         *icon);

  gboolean            notify_notification_show                  (NotifyNotification *notification,
                                                                 GError            **error);

  void                notify_notification_set_timeout           (NotifyNotification *notification,
                                                                 gint                timeout);

  void                notify_notification_set_category          (NotifyNotification *notification,
                                                                 const char         *category);

  void                notify_notification_set_urgency           (NotifyNotification *notification,
                                                                 NotifyUrgency       urgency);

  void                notify_notification_set_hint              (NotifyNotification *notification,
                                                                const char         *key,
                                                                GVariant           *value);

  void                notify_notification_set_app_name          (NotifyNotification *notification,
                                                                 const char         *app_name);

  void                notify_notification_clear_hints           (NotifyNotification *notification);

  void                notify_notification_add_action            (NotifyNotification *notification,
                                                                 const char         *action,
                                                                 const char         *label,
                                                                 NotifyActionCallback callback,
                                                                 gpointer            user_data,
                                                                 GFreeFunc           free_func);

  void                notify_notification_clear_actions         (NotifyNotification *notification);
  gboolean            notify_notification_close                 (NotifyNotification *notification,
                                                                 GError            **error);

  gint                notify_notification_get_closed_reason     (const NotifyNotification *notification);
}

class Notification {
  NotifyNotification* notification;
  string              summary,
                      _body,
                      icon;
  GMainLoop*          loop;
  int                 timeout;
  bool                timeout_added;

  private {
    static void*[size_t] frames;
    static size_t[]      clear_ids;
    static size_t        global_id;
  }

  this () {
    if (!Notify.isInitted) {
      Notify.init("libnotify4d");
    }

    this.notification = Notification.notificationNew(this.summary,
                                                     this._body,
                                                     this.icon);
    this.loop = g_main_loop_new(null, FALSE);
  }

  ~this() {
    if (this.timeout_added && g_main_loop_is_running(this.loop)) {
      g_main_loop_quit(this.loop);
    }
    g_main_loop_unref(this.loop);
    Notification.clearFrames();
  }

  this (string summary, string _body, string icon) {
    this.summary = summary;
    this._body   = _body;
    this.icon    = icon;

    this();
  }

  this (string summary, string _body) {
    this.summary = summary;
    this._body   = _body;

    this();
  }

  private struct ActionFrame(CallBack, T) {
    GMainLoop* loop;
    CallBack   callback;
    T*         payload;
  }

  private static void clearFrames() {
    foreach (id; Notification.clear_ids) {
      GC.free(Notification.frames[id]);
      this.frames.remove(id);
    }

    Notification.clear_ids = [];
  }

  private static void addFrames(AF: ActionFrame!(CallBack, T), CallBack: CallBack, T: T)(AF** afp) {
    Notification.frames[Notification.global_id++] = cast(void*)*afp;
  }

  static NotifyNotification* notificationNew(string summary, string _body, string icon) {
    return notify_notification_new(summary.toStringz,
                                   _body.toStringz,
                                   icon.toStringz);
  }

  void setSummary(string summary) {
    this.summary = summary;
  }

  void update(string summary, string _body, string icon) {
    notify_notification_update(this.notification,
                               summary.toStringz,
                               _body.toStringz,
                               icon.toStringz);
  }

  void update() {
    this.update(this.summary, this._body, this.icon);
  }

  void show() {
    GError* error;

    gboolean ret = notify_notification_show(this.notification, &error);

    if (!ret) {
      string message = cast(string)error.message.fromStringz;

      new Error(message);
    }

    if (this.timeout_added) {
      g_main_loop_run(this.loop);
    }
  }

  void setTimeout(int timeout) {
    this.timeout = timeout;
    notify_notification_set_timeout(this.notification, timeout);
  }

  void setCategory(string category) {
    notify_notification_set_category(this.notification, category.toStringz);
  }

  void setUrgency(NotifyUrgency urgency) {
    notify_notification_set_urgency(this.notification, urgency);
  }

  void setHint(string key, GVariant* value) {
    notify_notification_set_hint(this.notification, key.toStringz, value);
  }

  void setAppName(string app_name) {
    notify_notification_set_app_name(this.notification, app_name.toStringz);
  }
  
  void clearHints() {
    notify_notification_clear_hints(this.notification);
  }

  void addAction(CallBack: void function (NotifyNotification*, char*, T*), T: T)
                (string action, string label, CallBack callback, T* user_data = null, GFreeFunc free_func = null) {

    NotifyActionCallback cb = (NotifyNotification* notification, char* action, gpointer user_data) {
      ActionFrame!(CallBack, T) af = *cast(ActionFrame!(CallBack, T)*)user_data;
      GMainLoop* loop     = af.loop;
      CallBack   callback = af.callback;
      T*         payload  = af.payload;

      callback(notification, action, payload);

      Notification.clearFrames();

      g_main_loop_quit (loop);
    };

    ActionFrame!(CallBack, T)* af = cast(ActionFrame!(CallBack, T)*)GC.malloc(ActionFrame!(CallBack, T).sizeof);
    *af = ActionFrame!(CallBack, T)(loop, callback, user_data);
    Notification.addFrames(&af);

    notify_notification_add_action (this.notification,
                                    action.toStringz,
                                    label.toStringz,
                                    cb,
                                    af,
                                    free_func);

    if (!this.timeout_added) {
      g_timeout_add(this.timeout + 4000, cast(GSourceFunc)(&g_main_loop_quit), this.loop);
      this.timeout_added = true;
    }
  }

  void addAction(CallBack: void function (NotifyNotification*, char*, T*), T: T)
                (string label, CallBack callback, T* user_data = null, GFreeFunc free_func = null) {
    this.addAction(label, label, callback, user_data, free_func);
  }

  void clearActions() {
    notify_notification_clear_actions(this.notification);
  }

  void close() {
    GError* error;

    if (this.timeout_added && g_main_loop_is_running(this.loop)) {
      g_main_loop_quit(this.loop);
    }

    auto ret = notify_notification_close(this.notification, &error);

    if (!ret) {
      string message = cast(string)error.message.fromStringz;

      new Error(message);
    }
  }

  int getClosedReason() {
    return notify_notification_get_closed_reason(this.notification);
  }
}