class Report < ApplicationRecord
  belongs_to :country
  belongs_to :province

  scope :starting, -> (start_date) { where("reported_at >= ?", start_date) }
end
