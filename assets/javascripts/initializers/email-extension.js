import { withPluginApi } from "discourse/lib/plugin-api";
import DiscourseURL from "discourse/lib/url";

const pluginId = "email-extension";

function init(api) {
  const curUser = api.getCurrentUser();

  api.includePostAttributes("can_reply_via_email");

  api.addPostMenuButton("reply-via-email", (post) => {
    if (
      !api.container.lookup("site-settings:main")
        .email_extension_reply_by_email_address
    ) {
      return;
    }
    if (!post.can_reply_via_email) {
      return;
    }
    if (curUser) {
      return {
        action: "replyViaEmail",
        position: "second-last-hidden",
        className: "reply-via-email",
        icon: "envelope-square",
        title: "email_extension.reply_via_email",
      };
    } else {
      return {
        action: "replyViaEmail",
        position: "first",
        className: "reply-via-email",
        icon: "envelope-square",
        title: "email_extension.reply_via_email",
      };
    }
  });

  api.attachWidgetAction("post", "replyViaEmail", function () {
    if (!this.siteSettings.email_extension_reply_by_email_address) {
      return;
    }

    const topic = this.model.topic;

    const prefix =
      (this.siteSettings.email_extension_topic_reply_subject_headers.split &&
        this.siteSettings.email_extension_topic_reply_subject_headers.split(
          "|"
        )[0]) ||
      "Re:";
    const subject = `${prefix} ${topic?.title || ""}`;

    const address =
      this.siteSettings.email_extension_reply_by_email_address.replace(
        "%{post_id}",
        this.model.id
      );
    DiscourseURL.routeTo(`mailto:${address}?subject=${encodeURI(subject)}`);
  });
}

export default {
  name: pluginId,

  initialize(container) {
    if (!container.lookup("site-settings:main").email_extension_enabled) {
      return;
    }
    withPluginApi("1.6.0", init);
  },
};
