require_relative '../test_helper'

module RedmicaS3
  class IssueImportSystemTest < ApplicationSystemTestCase
    setup do
      log_user 'admin', 'admin'

      visit '/issues/imports/new?project_id=ecookbook'
      assert_text 'Import issues'
    end

    test 'issue import from csv creates issues with multibyte subjects' do
      attach_file 'file', file_fixture('issue_import.csv')
      click_button 'Next »'

      # Import options page
      find('#import-form legend', text: 'Options') do
        assert_equal 1, count_s3_objects
      end

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

    test 'issue import from csv with crlf and newline in quoted header' do
      attach_file 'file', file_fixture('issue_import_crlf_with_newline_in_quoted_header.csv')
      click_button 'Next »'

      # Import options page
      find('#import-form legend', text: 'Options') do
        assert_equal 1, count_s3_objects
      end

      within '#import-form' do
        select 'Comma', from: 'Field separator'
        select 'Double quote', from: 'Field wrapper'
        select 'UTF-8', from: 'Encoding'
      end
      click_button 'Next »'

      # Import fields mapping page
      assert_selector '#import-form legend', text: 'Fields mapping'
      within '.sample-data' do
        assert_text 'Bug'
        assert_text 'CSV with CRLF and newline in quoted header'
      end

      click_button 'Import'

      # Import result page
      within '#saved-items' do
        assert_text 'Bug #'
        assert_text 'CSV with CRLF and newline in quoted header'
      end

      # verify imported issue attributes
      imported_issue = Issue.order(:id).last
      assert_equal 'CSV with CRLF and newline in quoted header', imported_issue.subject
      assert_equal 'Bug', imported_issue.tracker.name
      assert_equal 0, count_s3_objects
    end
  end
end
