require_relative '../test_helper'

module RedmicaS3
  class NewsAttachmentSystemTest < ApplicationSystemTestCase
    setup do
      log_user 'admin', 'admin'
    end

    test 'create news with attachment' do
      visit '/projects/ecookbook/news/new'

      fill_in 'Title', with: 'News title'
      fill_in 'Summary', with: 'News summary'
      fill_in 'Description', with: 'News description'

      attach_file 'attachments[dummy][file]', file_fixture('text.txt')
      click_button 'Create'
      assert_text 'Successful creation.'

      # Show news
      click_link 'News title'
      assert_text 'News title'

      within '.attachments table' do
        assert_text 'text.txt'
      end

      news = News.order(:id).last

      assert_equal 1, news.attachments.size
      assert_equal 1, count_s3_attachment_objects
      assert verify_attachment_stored_in_s3(news.attachments.first)
    end

    test 'remove news attachments' do
      news = create_news_with_attachments('text.txt')

      visit "/news/#{news.id}"
      assert_text news.title

      within '.attachments' do
        accept_confirm { find('a.delete').click }
      end
      assert_no_selector '.attachments'

      news.reload

      assert_empty news.attachments
      assert_equal 0, count_s3_objects
    end

    private

    def create_news_with_attachments(filename)
      news = News.create!(
        project_id: 1,
        author_id: 1,
        title: 'News title',
        summary: 'News summary',
        description: 'News description'
      )
      news.attachments.create!(
        file: uploaded_file_from_fixture(filename),
        author_id: 1
      )

      assert_equal 1, count_s3_attachment_objects
      news.reload
    end
  end
end
