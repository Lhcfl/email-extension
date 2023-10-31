# frozen_string_literal: true

EmailExtensionModule::Engine.routes.draw do
  # get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw { mount ::EmailExtensionModule::Engine, at: "email-extension" }
