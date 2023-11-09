# frozen_string_literal: true

module ::Jobs::EmailExtensionModule
  class NotifyMailingListSubscribersForEditedPosts < ::Jobs::NotifyMailingListSubscribers
    def execute(args)
      ::EmailExtensionModule::MailEditedPosts::NotificationPatch.define_method :patch_edited_post_mail do |mail, user, post|
        ::EmailExtensionModule::MailEditedPosts.patch_edited_post_mail mail, user, post
      end
      super args
      ::EmailExtensionModule::MailEditedPosts::NotificationPatch.define_method :patch_edited_post_mail do |mail, user, post|
        mail
      end
    end
  end
end
