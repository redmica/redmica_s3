require 'aws-sdk-s3'

module RedmicaS3
  module UtilsPatch
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
        def save_upload(upload, path)
          default_external, default_internal = Encoding.default_external, Encoding.default_internal
          Encoding.default_external = Encoding::ASCII_8BIT
          Encoding.default_internal = Encoding::ASCII_8BIT
          object = RedmicaS3::Connection.object(path, nil)
          if upload.respond_to?(:read)
            # Use upload_stream for large files
            block = Proc.new do |write_stream|
              buffer = ""
              while (buffer = upload.read(8192))
                write_stream << buffer.b
                yield buffer if block_given?
              end
            end
            # Use different upload methods based on aws-sdk-s3 version
            if Gem::Specification.find_by_name('aws-sdk-s3').version >= Gem::Version.new('1.197.0')
              tm = Aws::S3::TransferManager.new(client: object.client)
              tm.upload_stream(bucket: object.bucket_name, key: object.key, &block)
            else
              object.upload_stream(&block)
            end
          else
            object.write(upload)
            yield upload if block_given?
          end
        ensure
          Encoding.default_external = default_external
          Encoding.default_internal = default_internal
        end
      end
    end
  end
end
