require_relative '../test_helper'

module RedmicaS3
  class IssueAttachmentSystemTest < ApplicationSystemTestCase
    setup do
      log_user 'admin', 'admin'
    end

    test 'create issue with attachments' do
      visit '/projects/ecookbook/issues/new'

      assert_text 'New issue'

      fill_in 'Subject', with: 'Issue subject'
      fill_in 'Description', with: 'Issue description'

      attach_file 'attachments[dummy][file]', [
        file_fixture('text.txt'),
        file_fixture('png.png'),
        file_fixture('pdf.pdf'),
        file_fixture('with_pdf_magic.ps.pdf')
      ]

      click_button 'commit'

      assert_text /Issue #\d+ created/

      within '.attachments' do
        assert_text 'text.txt'
        assert_text 'png.png'
        assert_text 'pdf.pdf'
        assert_text 'with_pdf_magic.ps.pdf'
      end

      within '.thumbnails' do
        png_thumbnail = find('img[alt="png.png"]')
        pdf_thumbnail = find('img[alt="pdf.pdf"]')

        assert_not_empty png_thumbnail[:src]
        assert_not_empty pdf_thumbnail[:src]
      end

      within '.attachments' do
        click_link 'text.txt', match: :first
      end

      assert_selector 'h2', text: /text.txt/
      assert_text file_fixture('text.txt').read

      issue = Issue.order(:id).last

      assert_equal 4, issue.attachments.size
      assert_equal 4, count_s3_attachment_objects
      assert_equal 2, count_s3_thumbnail_objects

      issue.attachments.each do |attachment|
        assert verify_attachment_stored_in_s3(attachment)
      end
    end

    test 'add attachments when editing issue' do
      issue = create_issue_with_attachments('text.txt')

      visit "/issues/#{issue.id}"

      click_link 'Edit', match: :first

      within '#issue-form' do
        attach_file 'attachments[dummy][file]', file_fixture('text_update.txt')
        click_button 'Submit'
      end

      assert_text 'Successful update.'

      within '.attachments' do
        assert_text 'text.txt'
        assert_text 'text_update.txt'
      end

      issue.reload

      assert_equal 2, issue.attachments.size
      assert_equal 2, count_s3_attachment_objects

      added_attachment = issue.attachments.detect { _1.filename == 'text_update.txt' }
      assert verify_attachment_stored_in_s3(added_attachment)
    end

    test 'remove attachments' do
      issue = create_issue_with_attachments('text.txt')

      visit "/issues/#{issue.id}"

      assert_selector 'h3', text: issue.subject

      within '.attachments' do
        accept_confirm { first('a.delete').click }
      end
      assert_no_selector '.attachments'

      issue.reload

      assert_empty issue.attachments
      assert_equal 0, count_s3_attachment_objects
    end

    private

    def create_issue_with_attachments(*filenames)
      issue = Issue.generate!(
        project_id: 1,
        author_id: 1,
        subject: 'Issue with attachments'
      )

      filenames.each do |name|
        issue.attachments.create!(
          file: uploaded_file_from_fixture(name),
          author_id: 1
        )
      end

      assert_equal filenames.size, count_s3_attachment_objects
      issue.reload
    end
  end
end
