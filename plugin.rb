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

  module NotificationPatch
    def mailing_list_notify(user, post)
      msg = super user, post
      patch_edited_post_mail msg, user, post
    end
    private
    def patch_edited_post_mail(mail, user, post)
      mail
    end
  end

  def self.patch_edited_post_mail(mail, user, post)
    # Patch the subject
    subject = String.new(SiteSetting.edit_email_subject)
    subject.gsub!("%{site_name}", SiteSetting.title)
    subject.gsub!("%{edit_post_id}", post.id.to_s)
    subject.gsub!("%{topic_title}", post.topic.title) unless post.topic.nil?
    mail.subject = subject
    mail
  end

  module EmailSenderPatch
    def send
      email_log = super
      post_id = header_value("X-Discourse-Post-Id")
      topic_id = header_value("X-Discourse-Topic-Id")
      return email_log unless post_id.present? and topic_id.present?
      post = Post.find_by(id: post_id, topic_id: topic_id)
      email_log.latest_revision = post.revisions.length
      email_log.save!
      email_log
    end
  end
end

require_relative "lib/email_extension_module/engine"

after_initialize do
  # Code which should run after Rails has finished booting
  require_relative "lib/email_in"

  add_to_serializer(:post, :can_reply_via_email) do
    return false unless SiteSetting.email_in
    if scope.user&.id
      return scope.can_create_post?(@topic)
    else
      # for private messages they do not have category
      return false unless @topic&.category&.email_in_allow_strangers
      return false if @topic.closed || @topic.archived
      true
    end
  end

  ::UserNotifications.prepend ::EmailExtensionModule::NotificationPatch
  ::Email::Sender.prepend ::EmailExtensionModule::EmailSenderPatch
  class ::EmailLog
    def self.unique_email_per_post(post, user)
      return yield unless post && user
      DistributedMutex.synchronize("email_log_#{post.id}_#{user.id}_#{post.revisions.length}") do
        log = self.where(post_id: post.id, user_id: user.id)
        if log.exists? and log[0].latest_revision >= post.revisions.length
          nil
        else
          yield
        end
      end
    end
  end
  class ::Jobs::NotifyMailingListSubscribersForEditedPosts < ::Jobs::NotifyMailingListSubscribers
    def execute(args)
      ::EmailExtensionModule::NotificationPatch.define_method :patch_edited_post_mail do |mail, user, post|
        ::EmailExtensionModule::patch_edited_post_mail mail, user, post
      end
      super args
      ::EmailExtensionModule::NotificationPatch.define_method :patch_edited_post_mail do |mail, user, post|
        mail
      end
    end
  end
  DiscourseEvent.on(:before_edit_post) do |post, args|
    return if post.topic.private_message?
    Jobs.enqueue_in(
      SiteSetting.email_time_window_mins.minutes,
      :notify_mailing_list_subscribers_for_edited_posts,
      post_id: post.id,
    )
  end
end
