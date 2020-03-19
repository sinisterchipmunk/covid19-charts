class AddProvinceIdToReports < ActiveRecord::Migration[6.0]
  def change
    add_reference :reports, :province, foreign_key: true
  end
end
