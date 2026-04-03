require 'timeout'

module RedmicaS3
  module MarkdownizerPatch
    extend ActiveSupport::Concern

    included do
      prepend PrependMethods
    end

    class_methods do
      def batch_delete!(target_prefix = nil)
        prefix = File.join(RedmicaS3::Connection.markdownized_previews_folder, "#{target_prefix}")

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
        def convert(source, target)
          return nil unless available?

          target_folder = RedmicaS3::Connection.markdownized_previews_folder
          target_obj = RedmicaS3::Connection.object(target, target_folder)

          unless target_obj.exists?
            source_obj = RedmicaS3::Connection.object(source)
            return nil unless source_obj.exists?

            source_size = source_obj.size
            if source_size > MAX_SOURCE_SIZE
              Rails.logger.warn("Markdownized preview generation skipped because source file is too large (#{source_size} bytes): #{source}")
              return nil
            end

            in_temp = Tempfile.new('source-object')
            in_temp.write(source_obj.get.body.read)
            in_temp.flush
            out_temp = Tempfile.new('markdownized-preview')

            args = [COMMAND, in_temp.path, "-t", "gfm"]
            pid = nil
            begin
              Timeout.timeout(PREVIEW_GENERATION_TIMEOUT) do
                pid = Process.spawn(*args, out: out_temp.path)
                _, status = Process.wait2(pid)
                unless status.success?
                  Rails.logger.error("Markdownized preview generation failed (#{status.exitstatus}):\nCommand: #{args.shelljoin}")
                  return nil
                end
              end

              preview = File.binread(out_temp.path, MAX_OUTPUT_SIZE + 1) || +""
              preview_blob = preview.byteslice(0, MAX_OUTPUT_SIZE)
              mime_type = Marcel::MimeType.for(preview_blob)

              RedmicaS3::Connection.put(target, File.basename(target), preview_blob, mime_type,
                {target_folder: target_folder}
              )
            rescue Timeout::Error
              if pid
                Process.kill('KILL', pid)
                Process.detach(pid)
              end
              Rails.logger.error("Markdownized preview generation timed out:\nCommand: #{args.shelljoin}")
              return nil
            rescue => e
              Rails.logger.error("Markdownized preview generation failed:\nCommand: #{args.shelljoin}\nException was: #{e.message}")
              return nil
            ensure
              in_temp&.unlink
              out_temp&.unlink
            end
          end

          target_obj.reload
          target_obj.get.body.read
        end
      end
    end
  end
end
