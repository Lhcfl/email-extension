import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DiscourseURL from "discourse/lib/url";

export default class ReplyViaEmail extends Component {
  // indicates if the button will be prompty displayed or hidden behind the show more button
  static hidden(args) {
    return args.state.currentUser != null;
  }

  static shouldRender(args) {
    return args.post.can_reply_via_email;
  }

  @service siteSettings;

  get folded() {
    return this.args.post.post_folding_status;
  }

  get title() {
    return this.folded
      ? "discourse_post_folding.expand.title"
      : "discourse_post_folding.fold.title";
  }

  get icon() {
    return this.folded ? "expand" : "compress";
  }

  @action
  replyViaEmail() {
    if (!this.siteSettings.email_extension_reply_by_email_address) {
      return;
    }

    const topic = this.args.post.topic;

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
        this.args.post.id
      );
    DiscourseURL.routeTo(`mailto:${address}?subject=${encodeURI(subject)}`);
  }

  <template>
    <DButton
      class="reply-via-email"
      ...attributes
      @action={{this.replyViaEmail}}
      @icon="square-envelope"
      @title="email_extension.reply_via_email"
    />
  </template>
}
