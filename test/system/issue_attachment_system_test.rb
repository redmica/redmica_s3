require_relative '../test_helper'

module RedmicaS3
  class IssueAttachmentSystemTest < ApplicationSystemTestCase
    test 'create issue with text file attachment' do
      log_user 'admin', 'admin'

      visit '/projects/ecookbook/issues/new'

      # Create new issue with an attachment
      assert_text 'New issue'

      fill_in 'Subject', with: 'Issue with text file attachment'
      fill_in 'Description', with: 'Test issue with text file'

      attach_file 'attachments[dummy][file]', file_fixture('text.txt')
      fill_in 'attachments[1][description]', with: 'Test text file'

      click_on 'Create'

      assert_text /Issue #\d+ created/
      assert_text 'Issue with text file attachment'
      assert_text 'Test issue with text file'

      # Show attachment details
      within '.attachments' do
        click_link 'text.txt', match: :first
      end

      assert_selector 'h2', text: /text.txt/
      assert_text file_fixture('text.txt').read

      # Verify that the attachment is stored in S3
      issue = Issue.order(:id).last
      assert_equal 1, count_s3_objects
      assert verify_attachment_stored_in_s3(issue.attachments.first)
    end
  end
end
