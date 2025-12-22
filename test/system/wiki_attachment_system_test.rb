require_relative '../test_helper'

module RedmicaS3
  class WikiAttachmentSystemTest < ApplicationSystemTestCase
    setup do
      log_user 'admin', 'admin'
    end

    test 'create wiki page with attachment' do
      new_page = 'Wiki_Page'

      visit "/projects/ecookbook/wiki/#{new_page}?parent=CookBook_documentation"

      attach_file 'attachments[dummy][file]', file_fixture('pdf.pdf')
      click_button 'Save'

      assert_selector 'h1', text: 'Wiki Page'

      find('legend', text: /\AFiles \(\d+\)/).click

      within '.attachments table' do
        assert_text 'pdf.pdf'
      end
      within '.thumbnails' do
        assert_selector 'img[alt="pdf.pdf"]'
      end

      wiki_page = Project.find(1).wiki.pages.find_by!(title: new_page)

      assert_equal 1, wiki_page.attachments.size
      assert_equal 1, count_s3_attachment_objects
      assert_equal 1, count_s3_thumbnail_objects
      assert verify_attachment_stored_in_s3(wiki_page.attachments.first)
    end

    test 'remove wiki page attachments on edit view' do
      page = create_wiki_page_with_attachment('pdf.pdf')

      visit "/projects/ecookbook/wiki/#{page.title}/edit"
      assert_selector 'h2', text: 'Wiki Page'

      click_link 'Edit attached files'

      within '#existing-attachments' do
        check 'Delete'
      end
      click_button 'Save'

      assert_current_path "/projects/ecookbook/wiki/#{page.title}"
      assert_selector 'h1', text: 'Wiki Page'
      assert_selector 'legend', text: 'Files (0)'
      assert_no_selector '.attachments', visible: :all

      page.reload

      assert_empty page.attachments
      assert_equal 0, count_s3_attachment_objects
    end

    private

    def create_wiki_page_with_attachment(filename)
      page = Project.find(1).wiki.pages.create!(
        title: 'Wiki Page',
        content: WikiContent.new(
          text: '# Wiki Page',
          author_id: 1
        )
      )
      page.attachments.create!(
        file: uploaded_file_from_fixture(filename),
        author_id: 1
      )

      assert_equal 1, count_s3_attachment_objects
      page.reload
    end
  end
end
