require 'aws-sdk-s3'

Aws.config[:ssl_verify_peer] = false

module RedmicaS3
  module Connection
    @@conn = nil
    @@s3_options = {}

    class << self
      def folder
        load_options
        str = @@s3_options[:folder]
        (
          if str.present?
            /\S+\/\z/.match?(str) ? str : "#{str}/"
          else
            ''
          end
        ).presence
      end

      def thumb_folder
        load_options
        str = @@s3_options[:thumb_folder]
        (
          if str.present?
            /\S+\/\z/.match?(str) ? str : "#{str}/"
          else
            'tmp/'
          end
        ).presence
      end

      def import_folder
        load_options
        str = @@s3_options[:import_folder]
        (
          if str.present?
            /\S+\/\z/.match?(str) ? str : "#{str}/"
          else
            'tmp/'
          end
        ).presence
      end

      def put(disk_filename, original_filename, data, content_type = 'application/octet-stream', opt = {})
        target_folder = opt[:target_folder] || self.folder
        digest = opt[:digest].presence
        options = {
          body:                 data,
          content_disposition:  "inline; filename=#{ERB::Util.url_encode(original_filename)}",
        }
        options[:content_type] = content_type if content_type
        if digest
          options[:metadata] = {
            'digest' => digest,
          }
        end

        object = object(disk_filename, target_folder)
        object.put(options)
      end

      def delete(filename, target_folder = self.folder)
        object = object(filename, target_folder)
        object.delete
      end

      def object(filename, target_folder = self.folder)
        object_nm = File.join([target_folder.presence, filename.presence].compact)
        own_bucket.object(object_nm)
      end

      def move_object(src_filename, dest_filename, target_folder = self.folder)
        src_object = object(src_filename, target_folder)
        return false  unless src_object.exists?
        dest_object = object(dest_filename, target_folder)
        return false  if dest_object.exists?

        src_object.move_to(dest_object)
        true
      end

# private

      def establish_connection
        load_options
        options = {
          access_key_id:      @@s3_options[:access_key_id],
          secret_access_key:  @@s3_options[:secret_access_key]
        }
        if endpoint.present?
          options[:endpoint] = endpoint
        elsif region.present?
          options[:region] = region
        end
        @@conn = Aws::S3::Resource.new(options)
      end

      def load_options
        return if @@s3_options.present?
        file = ERB.new( File.read(File.join(Rails.root, 'config', 's3.yml')) ).result
        # YAML.load works as YAML.safe_load if Psych >= 4.0 is installed
        (
          YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(file) : YAML.load(file)
        )[Rails.env].each do |key, value|
          @@s3_options[key.to_sym] = value
        end
      end

      def conn
        @@conn || establish_connection
      end

      def own_bucket
        conn.bucket(bucket)
      end

      def bucket
        load_options
        @@s3_options[:bucket]
      end

      def endpoint
        load_options
        @@s3_options[:endpoint]
      end

      def region
        load_options
        @@s3_options[:region]
      end
    end

    private_class_method  :establish_connection, :load_options, :conn, :own_bucket, :bucket, :endpoint, :region
  end
end
