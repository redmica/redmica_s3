require 'redmine'
require 'redmine_s3' unless Rails.env.test?

Redmine::Plugin.register :redmine_s3 do
  name 'S3'
  author 'Chris Dell'
  description 'Use Amazon S3 as a storage engine for attachments'
  version '0.0.3'
end
