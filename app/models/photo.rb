# == Schema Information
#
# Table name: photos
#
#  id          :integer          not null, primary key
#  document_id :integer
#  image_data  :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Photo < ApplicationRecord
  include ImageUploader[:image]

  belongs_to :document
end
