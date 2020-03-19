class Province < ApplicationRecord
  belongs_to :country
  has_many :reports, dependent: :destroy
end
