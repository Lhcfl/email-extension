class AddLatestRevisionToEmailLogs < ActiveRecord::Migration[7.0]
  def change
    add_column :email_logs, :latest_revision, :integer, null: false, default: 0
  end
end
