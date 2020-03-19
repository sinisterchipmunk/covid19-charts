class CreateProvinces < ActiveRecord::Migration[6.0]
  def change
    create_table :provinces do |t|
      t.string :name
      t.references :country, null: false, foreign_key: true
      t.decimal :latitude,  precision: 10, scale: 5
      t.decimal :longitude, precision: 10, scale: 5

      t.timestamps
    end
  end
end
