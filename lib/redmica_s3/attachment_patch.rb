module RedmicaS3
  module AttachmentPatch
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
        # Returns an ASCII or hashed filename that do not
        # exists yet in the given subdirectory
        def disk_filename(filename, directory=nil)
          timestamp = DateTime.now.strftime("%y%m%d%H%M%S")
          ascii = ''
          if %r{^[a-zA-Z0-9_\.\-]*$}.match?(filename) && filename.length <= 50
            ascii = filename
          else
            ascii = Digest::MD5.hexdigest(filename)
            # keep the extension if any
            ascii << $1 if filename =~ %r{(\.[a-zA-Z0-9]+)$}
          end
          while RedmicaS3::Connection.object(File.join(directory.to_s, "#{timestamp}_#{ascii}")).exists?
            timestamp.succ!
          end
          "#{timestamp}_#{ascii}"
        end

        # Deletes all thumbnails
        def clear_thumbnails
          Redmine::Thumbnail.batch_delete!
        end

      end

      # Copies the temporary file to its final location
      # and computes its MD5 hash
      def files_to_final_location
        if @temp_file
          self.disk_directory = target_directory
          self.disk_filename = Attachment.disk_filename(filename, disk_directory)
          logger.info("Saving attachment '#{self.diskfile}' (#{@temp_file.size} bytes)") if logger
          sha = Digest::SHA256.new
          if @temp_file.respond_to?(:read)
            buffer = ""
            while (buffer = @temp_file.read(8192))
              sha.update(buffer)
            end
          else
            sha.update(@temp_file)
          end

          self.digest = sha.hexdigest
        end
        if content_type.blank? && filename.present?
          self.content_type = Redmine::MimeType.of(filename)
        end
        # Don't save the content type if it's longer than the authorized length
        if self.content_type && self.content_type.length > 255
          self.content_type = nil
        end

        if @temp_file
          raw_data =
            if @temp_file.respond_to?(:read)
              @temp_file.rewind
              @temp_file.read
            else
              @temp_file
            end
          RedmicaS3::Connection.put(self.diskfile, self.filename, raw_data,
             (self.content_type || 'application/octet-stream'),
             {digest: self.digest}
          )
        end
      ensure
        @temp_file = nil
      end

      def diskfile
        Pathname.new(super).relative_path_from(Pathname.new(self.class.storage_path)).to_s
      end

      # Returns the full path the attachment thumbnail, or nil
      # if the thumbnail cannot be generated.
      def thumbnail(options = {})
        return if !readable? || !thumbnailable?

        size = options[:size].to_i
        if size > 0
          # Limit the number of thumbnails per image
          size = (size / 50.0).ceil * 50
          # Maximum thumbnail size
          size = 800 if size > 800
        else
          size = Setting.thumbnails_size.to_i
        end
        size = 100 unless size > 0
        target = thumbnail_path(size)

        diskfile_s3  = diskfile
        begin
          Redmine::Thumbnail.generate(diskfile_s3, target, size, is_pdf?)
        rescue => e
          Rails.logger.error "An error occured while generating thumbnail for #{diskfile_s3} to #{target}\nException was: #{e.message}"
          return
        end
      end

      # Returns true if the file is readable
      def readable?
        disk_filename.present? && self.s3_object(false).exists?
      end

      # Moves an existing attachment to its target directory
      def move_to_target_directory!
        return if new_record? || !readable?

        src = diskfile
        self.disk_directory = target_directory
        dest = diskfile

        return if src == dest

        if !RedmicaS3::Connection.move_object(src, dest)
          Rails.logger.error "Could not move attachment from #{src} to #{dest}"
          return
        end

        update_column :disk_directory, disk_directory
      end

      # Updates attachment digest to SHA256
      def update_digest_to_sha256!
        return unless readable?

        object = self.s3_object
        sha = Digest::SHA256.new
        sha.update(object.get.body.read)
        new_digest = sha.hexdigest

        unless new_digest == object.metadata['digest']
          object.copy_from(object,
            content_disposition:  object.content_disposition,
            content_type:         object.content_type,
            metadata:             object.metadata.merge({'digest' => new_digest}),
            metadata_directive:   'REPLACE'
          )
        end

        unless new_digest == self.digest
          update_column :digest, new_digest
        end
      end

      private

      def reuse_existing_file_if_possible
        object = self.s3_object
        reused = with_lock do
          if existing = Attachment
                          .where(digest: self.digest, filesize: self.filesize)
                          .where('id <> ? and disk_filename <> ?',
                                self.id, self.disk_filename)
                          .first
            existing.with_lock do
              if self.readable? && existing.readable? &&
                object.metadata['digest'] == existing.s3_object.metadata['digest']

                self.update_columns disk_directory: existing.disk_directory,
                                    disk_filename: existing.disk_filename
              end
            end
          end
        end
        if reused
          object.delete
        end
      rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotFound
        # Catch and ignore lock errors. It is not critical if deduplication does
        # not happen, therefore we do not retry.
        # with_lock throws ActiveRecord::RecordNotFound if the record isnt there
        # anymore, thats why this is caught and ignored as well.
      end

      # Physically deletes the file from the file system
      def delete_from_disk!
        if disk_filename.present?
          diskfile_s3 = diskfile
          Rails.logger.debug("Deleting #{diskfile_s3}")
          RedmicaS3::Connection.delete(diskfile_s3)
        end

        Redmine::Thumbnail.batch_delete!(
          thumbnail_path('*').sub(/\*\.thumb$/, '')
        )
      end

      def thumbnail_path(size)
        Pathname.new(super).relative_path_from(Pathname.new(self.class.thumbnails_storage_path)).to_s
      end
    end

    def raw_data
      self.s3_object.get.body.read
    end

  protected

    def s3_object(reload = true)
      object = RedmicaS3::Connection.object(diskfile)
      object.reload if reload && !object.data_loaded?
      object
    end

  end
end
