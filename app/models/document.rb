# == Schema Information
#
# Table name: documents
#
#  id         :integer          not null, primary key
#  title      :string
#  body       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Document < ApplicationRecord
  has_many :photos, dependent: :destroy    
  accepts_nested_attributes_for :photos
end
