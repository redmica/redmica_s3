require_relative '../test_helper'

module RedmicaS3
  class AttachmentsControllerTest < Redmine::ControllerTest
    tests ::AttachmentsController

    setup do
      User.current = nil
      @request.session[:user_id] = 2
    end

    test 'show pdf compatible illustrator file should be previewed' do
      attachment = Attachment.create!(
        file: mock_file_with_options(
          original_filename: 'test.ai',
          content: file_fixture('pdf.pdf').binread
        ),
        author_id: 2,
        container: Issue.find(1)
      )
      assert_equal 'application/illustrator', attachment.content_type

      get(:show, params: {id: attachment.id})
      assert_response :success
      assert_select 'div.filecontent.pdf object[type=?]', 'application/pdf'
    end
  end
end
