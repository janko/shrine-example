require "dotenv"
Dotenv.load!

##########
# Shrine #
##########

require "shrine"
require "shrine/storage/file_system"
require "shrine/storage/s3"
require "image_processing/mini_magick"

s3_options = {
  access_key_id:     ENV.fetch("S3_ACCESS_KEY_ID"),
  secret_access_key: ENV.fetch("S3_SECRET_ACCESS_KEY"),
  region:            ENV.fetch("S3_REGION"),
  bucket:            ENV.fetch("S3_BUCKET"),
}

Shrine.storages = {
  cache: Shrine::Storage::S3.new(prefix: "cache", **s3_options),
  store: Shrine::Storage::S3.new(prefix: "store", **s3_options),
}

Shrine.plugin :sequel
Shrine.plugin :backgrounding

Shrine::Attacher.promote { |data| UploadJob.perform_async(data) }
Shrine::Attacher.delete { |data| DeleteJob.perform_async(data) }

class ImageUploader < Shrine
  include ImageProcessing::MiniMagick

  plugin :determine_mime_type
  plugin :store_dimensions
  plugin :direct_upload, presign: true, max_size: 20*1024*1024
  plugin :versions, names: [:original, :thumb]
  plugin :remove_attachment
  plugin :logging

  def process(io, context)
    case context[:phase]
    when :store
      thumb = resize_to_limit!(io.download, 300, 300)
      {original: io, thumb: thumb}
    end
  end
end

############
# Database #
############

require "sequel"

DB = Sequel.connect("sqlite://database.sqlite3")
Sequel::Model.plugin :nested_attributes

class Album < Sequel::Model
  one_to_many :photos
  nested_attributes :photos, destroy: true
end

class Photo < Sequel::Model
  include ImageUploader[:image]
end

Album.first || Album.create(name: "My Album")

###################
# Background jobs #
###################

require "sucker_punch"

class UploadJob
  include SuckerPunch::Job

  def perform(data)
    Shrine::Attacher.promote(data)
  end
end

class DeleteJob
  include SuckerPunch::Job

  def perform(data)
    Shrine::Attacher.delete(data)
  end
end

###############
# Application #
###############

require "roda"
require "tilt/erb"

class App < Roda
  plugin :indifferent_params
  plugin :render
  plugin :partials
  plugin :static, ["/assets"]

  route do |r|
    r.on "attachments/images" do
      r.run ImageUploader::UploadEndpoint
    end

    @album = Album.first!

    r.root do
      view(:index)
    end

    r.post "album" do
      @album.update(params[:album])
      r.redirect r.referer
    end

    r.post "album/photos" do
      photo = @album.add_photo(params[:photo])
      partial("photo", locals: {photo: photo, idx: @album.photos.count})
    end
  end
end
