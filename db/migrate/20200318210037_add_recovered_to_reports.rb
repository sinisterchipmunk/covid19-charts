class AddRecoveredToReports < ActiveRecord::Migration[6.0]
  def change
    add_column :reports, :recovered, :integer
  end
end
