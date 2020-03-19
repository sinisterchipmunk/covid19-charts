class CreateReports < ActiveRecord::Migration[6.0]
  def change
    create_table :reports do |t|
      t.datetime :reported_at
      t.references :country, null: false, foreign_key: true
      t.integer :cases
      t.integer :deaths

      t.timestamps
    end
  end
end
