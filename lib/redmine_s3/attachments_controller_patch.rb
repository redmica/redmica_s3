module RedmineS3
  module AttachmentsControllerPatch
    extend ActiveSupport::Concern

    included do
      prepend PrependMethods
    end

    class_methods do
    end

    module PrependMethods

      def show
        respond_to do |format|
          format.html {
            if @attachment.container.respond_to?(:attachments)
              @attachments = @attachment.container.attachments.to_a
              if index = @attachments.index(@attachment)
                @paginator = Redmine::Pagination::Paginator.new(
                  @attachments.size, 1, index+1
                )
              end
            end
            if @attachment.is_diff?
              @diff = s3_raw_data(RedmineS3::Connection.object_url(@attachment.diskfile))
              @diff_type = params[:type] || User.current.pref[:diff_type] || 'inline'
              @diff_type = 'inline' unless %w(inline sbs).include?(@diff_type)
              # Save diff type as user preference
              if User.current.logged? && @diff_type != User.current.pref[:diff_type]
                User.current.pref[:diff_type] = @diff_type
                User.current.preference.save
              end
              render action: 'diff'
            elsif @attachment.is_text? && @attachment.filesize <= Setting.file_max_size_displayed.to_i.kilobyte
              @content = s3_raw_data(RedmineS3::Connection.object_url(@attachment.diskfile))
              render action: 'file'
            elsif @attachment.is_image?
              render action: 'image'
            else
              render action: 'other'
            end
          }
          format.api
        end
      end

      def download
        if @attachment.container.is_a?(Version) || @attachment.container.is_a?(Project)
          @attachment.increment_download
        end

        if stale?(etag: @attachment.digest)
          download_url = RedmineS3::Connection.object_url(@attachment.diskfile)
          send_data s3_raw_data(download_url),
            filename: filename_for_content_disposition(@attachment.filename),
            type: detect_content_type(@attachment),
            disposition: disposition(@attachment)
        end
      end

      def thumbnail
        if @attachment.thumbnailable? && tbnail = @attachment.thumbnail(:size => params[:size])
          if stale?(etag: tbnail)
            send_data s3_raw_data(tbnail),
              filename: filename_for_content_disposition(@attachment.filename),
              type: detect_content_type(@attachment),
              disposition: 'inline'
          end
        else
          # No thumbnail for the attachment or thumbnail could not be created
          head 404
        end
      end

    end

  private

    def s3_raw_data(url)
      require 'open-uri'
      raw_data = nil
      open(url, 'rb') do |f| raw_data = f.read end
      raw_data
    end

  end
end
