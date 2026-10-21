require_relative '../test_helper'

module RedmicaS3
  class AvatarSystemTest < ApplicationSystemTestCase
    setup do
      log_user 'admin', 'admin'
    end

    test 'upload avatar' do
      visit '/my/avatar'

      attach_file 'avatar', file_fixture('png.png')
      click_button 'Update'

      assert_text 'Successful update.'

      # The avatar is served from S3 and cropped to a square
      assert_selector '.avatar-preview img.avatar' do |img|
        img.evaluate_script('this.naturalWidth == 100 && this.naturalHeight == 100')
      end

      user = User.find_by_login('admin')
      assert verify_attachment_stored_in_s3(user.avatar)
      assert verify_file_stored_in_s3(user.avatar.send(:thumbnail_path, '100_crop'), 'attachments/thumbnails')
    end
  end
end
