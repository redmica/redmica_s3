require_relative '../test_helper'

module RedmicaS3
  class ImportsControllerTest < Redmine::ControllerTest
    tests ::ImportsController

    def setup
      User.current = nil
      @request.session[:user_id] = 2
    end

    test 'issue import from csv with crlf and newline in quoted header' do
      import = new_record(Import) do
        post :create, params: {
          type: 'IssueImport',
          file: uploaded_test_file('issue_import_crlf_with_newline_in_quoted_header.csv', 'text/csv')
        }
        assert_response :found
      end
      assert_equal "\r\n", import.settings['newline']

      post :settings, params: {
        id: import.to_param,
        import_settings: {
          separator: ',',
          wrapper: '"',
          encoding: 'UTF-8'
        }
      }
      assert_response :found
      import.reload
      assert_equal 1, import.total_items

      post :mapping, params: {
        id: import.to_param,
        import_settings: {
          mapping: {
            project_id: '1',
            tracker: '2',
            subject: '3'
          }
        }
      }
      assert_response :found

      assert_difference 'Issue.count', 1 do
        post :run, params: { id: import.to_param }
        assert_response :found
      end

      import.reload
      issue = Issue.find(import.items.first.obj_id)
      assert_equal 'CSV with CRLF and newline in quoted header', issue.subject
    end
  end
end
