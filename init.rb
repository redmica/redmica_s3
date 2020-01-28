require 'redmine_s3'

Redmine::Plugin.register :redmica_s3 do
  requires_redmine version_or_higher: '4.1.0'
  name 'RedMica S3 plugin'
  author 'Far End Technologies, Inc.'
  description 'Use Amazon S3 as a storage engine for attachments'
  version '0.0.3'
end
