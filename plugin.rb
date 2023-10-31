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

after_initialize do
  # Code which should run after Rails has finished booting
  require_relative "lib/email_in"

  add_to_serializer(:post, :can_reply_via_email) do
    return false unless SiteSetting.email_in
    if scope.user
      return scope.can_create_post?(@topic)
    else
      # for private messages they do not have category
      return false unless @topic&.category&.email_in_allow_strangers
      return false if @topic.closed || @topic.archived
      true
    end
  end
end