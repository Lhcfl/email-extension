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
end
