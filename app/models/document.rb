class Document < ApplicationRecord
    has_many :photos
    accepts_nested_attributes_for :photos

    # def photos
    #     Photo.where()
    # end
end