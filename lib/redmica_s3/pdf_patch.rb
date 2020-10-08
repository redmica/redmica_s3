require 'open-uri'

module RedmicaS3
  module PdfPatch
    extend ActiveSupport::Concern

    included do
      prepend PrependMethods
    end

    class_methods do
    end

    module PrependMethods
      def self.prepended(base)
        class << base
          self.prepend(ClassMethods)
        end
      end

      module ClassMethods
      end

      def get_image_filename(attrname)
        atta = Redmine::Export::PDF::RDMPdfEncoding.attach(@attachments, attrname, 'UTF-8')
        if atta
          def atta.presigned_url
            self.s3_object.presigned_url(:get, expires_in: 60)
          end
          atta.presigned_url
        else
          nil
        end
      end
    end

    def get_image_file(image_uri)
      #use a temporary file....
      tmpFile = Tempfile.new(['tmp_', '.img'], self.class.k_path_cache)
      tmpFile.binmode
      open(image_uri, 'rb') do |read_file|
        tmpFile.write(read_file.read)
      end
      tmpFile.fsync
      tmpFile
    end
  end
end
