require_relative '../test_helper'

module RedmicaS3
  class ForumAttachmentSystemTest < ApplicationSystemTestCase
    setup do
      log_user 'admin', 'admin'
    end

    test 'create board topic with attachment' do
      visit '/projects/ecookbook/boards/1'

      click_link 'New message'

      within '#message-form' do
        fill_in 'message_subject', with: 'Message subject'
        fill_in 'message_content', with: 'Message body with attachment'
        attach_file 'attachments[dummy][file]', file_fixture('png.png')
        click_button 'Create'
      end

      assert_text 'Successful creation.'

      within 'div.message', match: :first do
        within '.attachments table' do
          assert_text 'png.png'
        end
        within '.thumbnails' do
          assert_selector 'img[alt="png.png"]'
        end
      end

      topic_message = Message.order(:id).last

      assert_equal 1, topic_message.attachments.size
      assert_equal 1, count_s3_attachment_objects
      assert_equal 1, count_s3_thumbnail_objects
      assert verify_attachment_stored_in_s3(topic_message.attachments.first)
    end

    test 'remove board topic attachments' do
      topic = create_board_topic_with_attachments('png.png', board_id: 1)

      visit "/boards/1/topics/#{topic.id}"
      assert_text topic.subject

      accept_confirm { find('.attachments a.delete', match: :first).click }
      assert_no_selector '.attachments'

      topic.reload

      assert_empty topic.attachments
      assert_equal 0, count_s3_attachment_objects
    end

    test 'create board reply with attachment' do
      visit '/boards/1/topics/1'
      assert_text 'First post'

      click_link 'Reply'

      within '#reply' do
        fill_in 'message_subject', with: 'Re: S3 forum message'
        fill_in 'message_content', with: 'Reply body attachment'
        attach_file 'attachments[dummy][file]', file_fixture('text_update.txt')
        click_button 'Submit'
      end

      assert_text 'Successful update.'

      reply_message = Message.order(:id).last

      within "#message-#{reply_message.id} .attachments" do
        assert_text 'text_update.txt'
      end

      assert_equal 1, reply_message.attachments.size
      assert_equal 1, count_s3_attachment_objects
      assert verify_attachment_stored_in_s3(reply_message.attachments.first)
    end

    test 'remove board reply attachments' do
      reply = create_board_reply_with_attachments('text_update.txt', board_id: 1, topic_id: 1)

      visit "/boards/1/topics/1"
      assert_text 'First post'

      accept_confirm { find("#message-#{reply.id} .attachments a.delete", match: :first).click }
      assert_no_selector "#message-#{reply.id} .attachments"

      reply.reload

      assert_empty reply.attachments
      assert_equal 0, count_s3_attachment_objects
    end

    private

    def create_board_topic_with_attachments(filename, board_id:)
      message = Message.create!(
        board_id: board_id,
        author_id: 1,
        subject: 'Topic subject',
        content: 'Topic body'
      )
      message.attachments.create!(
        file: uploaded_file_from_fixture(filename),
        author_id: 1
      )

      assert_equal 1, count_s3_attachment_objects
      message.reload
    end

    def create_board_reply_with_attachments(filename, board_id:, topic_id:)
      reply = Message.create!(
        parent_id: topic_id,
        board_id: board_id,
        author_id: 1,
        subject: 'Reply subject',
        content: 'Reply body'
      )
      reply.attachments.create!(
        file: uploaded_file_from_fixture(filename),
        author_id: 1
      )

      assert_equal 1, count_s3_attachment_objects
      reply.reload
    end
  end
end
