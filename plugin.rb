# frozen_string_literal: true

# name: email-extension
# about: TODO
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 3.0.0

enabled_site_setting :email_extension_enabled

module ::EmailExtensionModule
  PLUGIN_NAME = "email-extension"
end

require_relative "lib/email_extension_module/engine"
require_relative "lib/email_in"

after_initialize do
  # Code which should run after Rails has finished booting
end
