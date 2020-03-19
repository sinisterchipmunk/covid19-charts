class Country < ApplicationRecord
  has_many :reports, dependent: :destroy
  has_many :provinces, dependent: :destroy
  scope :reports, -> { unscoped { Report.all }.where(country: all) }
end
