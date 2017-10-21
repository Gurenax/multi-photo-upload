# Multiple Photo Upload using Shrine

This is a simple guide to upload multiple photos with Shrine without using JQuery file upload.
For simplicity, I will not be using AWS S3 with this guide.


## Create Scaffolds
```
rails g scaffold Document title body:text
```
```
rails g scaffold Photo document:references image_data
```
```
rails db:migrate
```

## Shrine Configuration

### Gem File
```ruby
gem 'fastimage'
gem 'image_processing'
gem 'mini_magick'
gem 'shrine'
```
Don't forget to:
```
bundle install
```

### Initializer
Create config\initializers\shrine.rb
```ruby
require "shrine"
require "shrine/storage/file_system"

Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"), # temporary
  store: Shrine::Storage::FileSystem.new("public", prefix: "uploads/store"), # permanent
}

Shrine.plugin :activerecord
Shrine.plugin :logging, logger: Rails.logger
Shrine.plugin :cached_attachment_data # for forms
```

### Uploader
Create uploaders\image_uploader.rb
```ruby
class ImageUploader < Shrine
  include ImageProcessing::MiniMagick

  plugin :activerecord
  plugin :determine_mime_type
  plugin :logging, logger: Rails.logger
  plugin :remove_attachment
  plugin :store_dimensions
  plugin :validation_helpers
  plugin :versions, names: [:original, :thumb]

  Attacher.validate do
    validate_max_size 2.megabytes, message: 'is too large (max is 2 MB)'
    validate_mime_type_inclusion ['image/jpg', 'image/jpeg', 'image/png', 'image/gif']
  end

  def process(io, context)
    case context[:phase]
      when :store
        thumb = resize_to_limit!(io.download, 300, 300)
        { original: io, thumb: thumb }
      end
  end
end
```

## Modify the Models

### Document
Each document will have many photos.
When a document is deleted, all its photos will also be deleted.
```ruby
class Document < ApplicationRecord
    has_many :photos, dependent: :destroy    
    accepts_nested_attributes_for :photos
end
```

### Photo
Each photo belongs to a document.
```ruby
class Photo < ApplicationRecord
  include ImageUploader[:image]

  belongs_to :document
end
```
  
## Modify the Controllers

### Document Controller
Change the create method to this
```ruby
def create
  @document = Document.new(document_params)

  respond_to do |format|
    if @document.save

      # Get photos directly from the params and save them to the database one by one
      if params[:document][:images]
        params[:document][:images].each { |image|
          Photo.create(document: @document, image: image)
        }
      end

      format.html { redirect_to @document, notice: 'Document was successfully created.' }
      format.json { render :show, status: :created, location: @document }
    else
      format.html { render :new }
      format.json { render json: @document.errors, status: :unprocessable_entity }
    end
  end
end
```
Change the update method to this
```ruby
def update
  respond_to do |format|
    if @document.update(document_params)

      # Get photos directly from the params and save them to the database one by one
      if params[:document][:images]
        params[:document][:images].each { |image|
          Photo.create(document: @document, image: image)
        }
      end

      format.html { redirect_to @document, notice: 'Document was successfully updated.' }
      format.json { render :show, status: :ok, location: @document }
    else
      format.html { render :edit }
      format.json { render json: @document.errors, status: :unprocessable_entity }
    end
  end
end
```
### Photos Controller
Change the destroy method to this
```ruby
def destroy
  @photo.destroy
  respond_to do |format|
    # format.html { redirect_to photos_url, notice: 'Photo was successfully destroyed.' }
    format.html { redirect_to document_path(@photo.document_id), notice: 'Photo was successfully destroyed.' }
    format.json { head :no_content }
  end
end
```


## Modify the view
### documents\ _form.html.erb
Add this in the form
```
<div class="field">
  <%= form.label :images %>
  <%= form.file_field :images, id: :images, multiple: true %>
</div>
```

### documents\show.html.erb
Add this in the form
```
<p>
  <strong>Photos:</strong><br>
  <% @document.photos.each do |photo| %>
    <%= image_tag photo.image_url(:thumb) %><br>
    <%= link_to 'Delete Photo', photo_path(photo), method: :delete %><br>
  <% end %>
</p>
```

## That's about it.
### For any questions/suggestions, please create an Issue