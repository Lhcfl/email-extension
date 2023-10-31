# frozen_string_literal: true

module ::EmailExtensionModule
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace EmailExtensionModule
    config.autoload_paths << File.join(config.root, "lib")
  end
end
