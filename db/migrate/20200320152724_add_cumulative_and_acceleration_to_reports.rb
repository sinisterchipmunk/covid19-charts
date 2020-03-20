class AddCumulativeAndAccelerationToReports < ActiveRecord::Migration[6.0]
  def change
    add_column :reports, :cum_cases, :integer
    add_column :reports, :cum_deaths, :integer
    add_column :reports, :cum_recovered, :integer
    add_column :reports, :accel_cases, :integer
    add_column :reports, :accel_deaths, :integer
    add_column :reports, :accel_recovered, :integer
  end
end
