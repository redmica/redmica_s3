require_relative '../test_helper'

module RedmicaS3
  class IssueImportSystemTest < ApplicationSystemTestCase
    test 'issue import from csv creates issues with multibyte subjects' do
      log_user 'admin', 'admin'

      visit '/issues/imports/new?project_id=ecookbook'
      assert_text 'Import issues'

      attach_file 'file', file_fixture('issue_import.csv')
      click_button 'Next »'
      assert_equal 1, count_s3_objects

      # Import options page
      assert_selector '#import-form legend', text: 'Options'
      click_button 'Next »'

      # Import fields mapping page
      assert_selector '#import-form legend', text: 'Fields mapping'
      within '.sample-data' do
        assert_text 'Bug'
        assert_text 'English日本語Mix'
      end

      click_button 'Import'

      # Import result page
      within '#saved-items' do
        assert_text 'Bug #'
        assert_text 'English日本語Mix'
      end

      # verify imported issue attributes
      imported_issue = Issue.order(:id).last
      assert_equal 'English日本語Mix', imported_issue.subject
      assert_equal 'Bug', imported_issue.tracker.name
      assert_equal 0, count_s3_objects
    end
  end
end
