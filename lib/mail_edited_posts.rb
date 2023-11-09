# frozen_string_literal: true

module ::EmailExtensionModule
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
      return email_log if email_log.instance_of? SkippedEmailLog
      post_id = header_value("X-Discourse-Post-Id")
      topic_id = header_value("X-Discourse-Topic-Id")
      return email_log unless post_id.present? && topic_id.present?
      post = Post.find_by(id: post_id, topic_id: topic_id)
      email_log.latest_revision =
        post.revisions.last && post.revisions.last.updated_at || DateTime.new
      email_log.save!
      email_log
    end
  end
end

class ::EmailLog
  def self.unique_email_per_post(post, user)
    return yield unless post && user
    postrev = post.revisions.last && post.revisions.last.updated_at || DateTime.new
    DistributedMutex.synchronize("email_log_#{post.id}_#{user.id}_#{postrev}") do
      log = self.where(post_id: post.id, user_id: user.id)
      return yield unless log.exists?
      return unless SiteSetting.mail_edited_posts
      yield if log[0].latest_revision < postrev
    end
  end
end
