# frozen_string_literal: true

module ::EmailExtensionModule::IncludeDetails
  def self.init
    # Should be later than that after_initialize: it's already executed in the initializer (
    @add_details_link =
      DiscourseEvent.events[:reduce_cooked].entries.find do |f|
        f.__binding__.local_variable_get(:block).source_location[
          0
        ].end_with? "discourse-details/plugin.rb"
      end
    DiscourseEvent.off :reduce_cooked, &@add_details_link
    DiscourseEvent.on :reduce_cooked do |fragment, post|
      if !SiteSetting.email_extension_enabled || !SiteSetting.email_include_details
        @add_details_link.call(fragment, post)
      end
    end
    email_style_cb = ::Email::Styles.class_variable_get(:@@plugin_callbacks)
    @strip_details =
      email_style_cb.find do |f|
        f.__binding__.source_location[0].end_with? "discourse-details/plugin.rb"
      end
    email_style_cb.delete @strip_details
    ::Email::Styles.register_plugin_style do |fragment, opts|
      if !SiteSetting.email_extension_enabled || !SiteSetting.email_include_details
        @strip_details.call(fragment, opts)
      end
    end
  end
end
