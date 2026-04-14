module RedmicaS3
  module MarkdownizerPatch
    extend ActiveSupport::Concern

    class_methods do
      def batch_delete!(target_prefix = nil)
        prefix = File.join(RedmicaS3::Connection.markdownized_previews_folder, "#{target_prefix}")

        bucket = RedmicaS3::Connection.__send__(:own_bucket)
        bucket.objects({prefix: prefix}).batch_delete!
        return
      end
    end
  end
end
