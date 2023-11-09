# frozen_string_literal: true

class AddLatestRevisionToEmailLogs < ActiveRecord::Migration[7.0]
  def change
    add_column :email_logs, :latest_revision, :datetime, null: false, default: DateTime.new
  end
end
