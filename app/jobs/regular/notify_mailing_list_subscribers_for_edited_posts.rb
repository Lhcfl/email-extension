# frozen_string_literal: true

module ::Jobs
  class NotifyMailingListSubscribersForEditedPosts < NotifyMailingListSubscribers
    def execute(args)
      ::EmailExtensionModule::NotificationPatch.define_method :patch_edited_post_mail do |mail, user, post|
        ::EmailExtensionModule.patch_edited_post_mail mail, user, post
      end
      super args
      ::EmailExtensionModule::NotificationPatch.define_method :patch_edited_post_mail do |mail, user, post|
        mail
      end
    end
  end
end
