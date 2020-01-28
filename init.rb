require 'redmine_s3/attachment_patch'
require 'redmine_s3/attachments_controller_patch'
require 'redmine_s3/thumbnail_patch'
require 'redmine_s3/connection'

Redmine::Plugin.register :redmica_s3 do
  requires_redmine version_or_higher: '4.1.0'
  name 'RedMica S3 plugin'
  author 'Far End Technologies, Inc.'
  description 'Use Amazon S3 as a storage engine for attachments'
  version '0.0.3'

  Rails.configuration.to_prepare do
    Redmine::Thumbnail.__send__(:include, RedmineS3::ThumbnailPatch)
    Attachment.__send__(:include, RedmineS3::AttachmentPatch)
    AttachmentsController.__send__(:include, RedmineS3::AttachmentsControllerPatch)
  end
  RedmineS3::Connection.create_bucket
end
