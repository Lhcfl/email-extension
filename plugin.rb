# frozen_string_literal: true

# name: email-extension
# about: Some extension of email.
# version: 0.0.1
# authors: Lhc_fl
# url: https://github.com/Lhcfl/email-extension
# required_version: 3.0.0

enabled_site_setting :email_extension_enabled

module ::EmailExtensionModule
  PLUGIN_NAME = "email-extension"
end

require_relative "lib/email_extension_module/engine"

DiscourseEvent.on :after_plugin_activation do
  Discourse
    .plugins
    .find { |p| p.path.end_with? "discourse-details/plugin.rb" }
    .after_initialize { ::EmailExtensionModule::IncludeDetails.init }
end

after_initialize do
  # Code which should run after Rails has finished booting
  require_relative "lib/email_in"

  add_to_serializer(:post, :can_reply_via_email) do
    next false unless SiteSetting.email_in
    if scope.user&.id
      next scope.can_create_post?(@topic)
    else
      # for private messages they do not have category
      next false unless @topic&.category&.email_in_allow_strangers
      next false if @topic.closed || @topic.archived
      true
    end
  end

  ::UserNotifications.prepend ::EmailExtensionModule::MailEditedPosts::NotificationPatch
  ::Email::Sender.prepend ::EmailExtensionModule::MailEditedPosts::EmailSenderPatch
  on(:before_edit_post) do |post, args|
    next if post.topic.private_message?
    DiscourseRedis::EvalHelper.new("redis.call('set', KEYS[1], 1)").eval(
      Discourse.redis,
      ["unmailed_edited_post_#{post.id}"],
    )
    Jobs.enqueue_in(
      SiteSetting.email_time_window_mins.minutes,
      :notify_mailing_list_subscribers,
      post_id: post.id,
    )
  end
end
