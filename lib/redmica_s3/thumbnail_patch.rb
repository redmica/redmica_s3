require 'timeout'

module RedmicaS3
  module ThumbnailPatch
    extend ActiveSupport::Concern

    included do
      prepend PrependMethods
    end

    class_methods do
      def batch_delete!(target_prefix = nil)
        prefix = File.join(RedmicaS3::Connection.thumb_folder, "#{target_prefix}")

        bucket = RedmicaS3::Connection.__send__(:own_bucket)
        bucket.objects({prefix: prefix}).batch_delete!
        return
      end
    end

    module PrependMethods
      def self.prepended(base)
        class << base
          self.prepend(ClassMethods)
        end
      end

      module ClassMethods
        # Generates a thumbnail for the source image to target
        def generate(source, target, size, is_pdf = false)
          return nil unless convert_available?
          return nil if is_pdf && !gs_available?

          target_folder = RedmicaS3::Connection.thumb_folder
          object = RedmicaS3::Connection.object(target, target_folder)
          unless object.exists?
            return nil unless Object.const_defined?(:MiniMagick)

            raw_data = RedmicaS3::Connection.object(source).reload.get.body.read rescue nil
            mime_type = Marcel::MimeType.for(raw_data)
            return nil if !Redmine::Thumbnail::ALLOWED_TYPES.include? mime_type
            return nil if is_pdf && mime_type != "application/pdf"

            size_option = "#{size}x#{size}>"
            begin
              tempfile = MiniMagick::Utilities.tempfile(File.extname(source)) do |f| f.write(raw_data) end
              # Generate command
              convert = MiniMagick::Tool::Convert.new
              if is_pdf
                convert << "#{tempfile.to_path}[0]"
                convert.thumbnail size_option
                convert << 'png:-'
              else
                convert << tempfile.to_path
                convert.auto_orient
                convert.thumbnail size_option
                convert << '-'
              end
              # Execute command
              convert_output = nil
              Timeout.timeout(Redmine::Configuration['thumbnails_generation_timeout'].to_i) do
                convert_output = convert.call
              end
              img = MiniMagick::Image.read(convert_output)

              img_blob = img.to_blob
              sha = Digest::SHA256.new
              sha.update(img_blob)
              new_digest = sha.hexdigest
              RedmicaS3::Connection.put(target, File.basename(target), img_blob, img.mime_type,
                {target_folder: target_folder, digest: new_digest}
              )
            rescue Timeout::Error
              Rails.logger.error("Creating thumbnail timed out:\nCommand: #{convert.command.join(' ')}")
              return nil
            rescue => e
              Rails.logger.error("Creating thumbnail failed (#{e.message}):")
              return nil
            ensure
              tempfile.unlink if tempfile
            end
          end

          object.reload
          [object.metadata['digest'], object.get.body.read]
        end
      end
    end
  end
end
