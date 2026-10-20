module RedmicaS3
  module AvatarsControllerPatch
    extend ActiveSupport::Concern

    included do
      prepend PrependMethods
    end

    class_methods do
    end

    module PrependMethods

      def show
        # The original image is never served since it may contain metadata
        # such as the location where it was taken
        digest, raw_data = @avatar.thumbnail(:size => params[:size], :crop => true)
        unless raw_data
          render_404
          return
        end

        expires_in 1.day, :public => !Setting.login_required?
        if stale?(etag: digest, template: false)
          send_data raw_data,
            filename: filename_for_content_disposition(@avatar.filename),
            type: @avatar.content_type,
            disposition: 'inline'
        end
      end
    end

  end
end
