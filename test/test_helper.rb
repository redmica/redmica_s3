require_relative '../../../test/test_helper'
require_relative '../../../test/application_system_test_case'
require 'rack/test'

class ApplicationSystemTestCase
  self.file_fixture_path = File.join(Redmine::Plugin.find('redmica_s3').directory, 'test', 'fixtures', 'files')

  setup do
    cleanup_s3_bucket
  end

  private

  def cleanup_s3_bucket
    bucket = RedmicaS3::Connection.send(:own_bucket)
    bucket.objects.each(&:delete) if bucket.exists?
  rescue => e
    Rails.logger.error "Error cleaning up S3 bucket: #{e.message}"
  end

  def verify_attachment_stored_in_s3(attachment)
    verify_file_stored_in_s3(attachment.diskfile, 'attachments')
  end

  def verify_file_stored_in_s3(filename, folder)
    key = File.join(folder, filename)
    s3_client.head_object(bucket: 'redmine-bucket', key: key)
  rescue Aws::S3::Errors::NotFound
    false
  end

  def count_s3_attachment_objects
    count_s3_objects - count_s3_thumbnail_objects
  end

  def count_s3_thumbnail_objects
    count_s3_objects(prefix: 'attachments/thumbnails')
  end

  def count_s3_objects(prefix: nil)
    resp = s3_client.list_objects_v2(bucket: 'redmine-bucket', prefix: prefix)
    resp.key_count
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(
      endpoint: ENV['AWS_ENDPOINT_URL'],
      region: ENV['AWS_REGION'],
      force_path_style: true,
      access_key_id: 'test',
      secret_access_key: 'test'
    )
  end

  def uploaded_file_from_fixture(name)
    path = file_fixture(name)
    mime_type =
      case File.extname(name)
      when '.txt' then 'text/plain'
      when '.png' then 'image/png'
      when '.pdf' then 'application/pdf'
      else 'application/octet-stream'
      end

    Rack::Test::UploadedFile.new(path, mime_type)
  end
end
