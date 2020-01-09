require 'redmine_s3'

Redmine::Plugin.register :redmine_s3 do
  requires_redmine version: '4.0'
  name 'S3'
  author 'Chris Dell'
  description 'Use Amazon S3 as a storage engine for attachments'
  version '0.0.3'
end
