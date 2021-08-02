require 'redmica_s3/attachment_patch'
require 'redmica_s3/attachments_controller_patch'
require 'redmica_s3/import_patch'
require 'redmica_s3/pdf_patch'
require 'redmica_s3/thumbnail_patch'
require 'redmica_s3/utils_patch'
require 'redmica_s3/connection'

Redmine::Plugin.register :redmica_s3 do
  name 'RedMica S3 plugin'
  description 'Use Amazon S3 as a storage engine for attachments'
  url 'https://github.com/redmica/redmica_s3'
  author 'Far End Technologies Corporation'
  author_url 'https://www.farend.co.jp'

  version '1.0.9'
  requires_redmine version_or_higher: '4.1.0'

  Rails.configuration.to_prepare do
    Redmine::Thumbnail.__send__(:include, RedmicaS3::ThumbnailPatch)
    Redmine::Utils.__send__(:include, RedmicaS3::UtilsPatch)
    Attachment.__send__(:include, RedmicaS3::AttachmentPatch)
    Redmine::Export::PDF::ITCPDF.__send__(:include, RedmicaS3::PdfPatch)
    Import.__send__(:include, RedmicaS3::ImportPatch)
    AttachmentsController.__send__(:include, RedmicaS3::AttachmentsControllerPatch)
  end
  RedmicaS3::Connection.create_bucket
end
