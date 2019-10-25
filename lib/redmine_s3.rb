require 'redmine_s3/attachment_patch'
require 'redmine_s3/attachments_controller_patch'
require 'redmine_s3/thumbnail_patch'
require 'redmine_s3/connection'

Redmine::Thumbnail.__send__(:include, RedmineS3::ThumbnailPatch)
Attachment.__send__(:include, RedmineS3::AttachmentPatch)
AttachmentsController.__send__(:include, RedmineS3::AttachmentsControllerPatch)
RedmineS3::Connection.create_bucket
