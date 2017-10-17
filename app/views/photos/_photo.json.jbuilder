json.extract! photo, :id, :document_id, :image_data, :created_at, :updated_at
json.url photo_url(photo, format: :json)
