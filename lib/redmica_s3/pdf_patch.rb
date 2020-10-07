module RedmicaS3
  module PdfPatch
    extend ActiveSupport::Concern

    included do
      prepend PrependMethods
    end

    class_methods do
    end

    module PrependMethods
      def self.prepended(base)
        class << base
          self.prepend(ClassMethods)
        end
      end

      module ClassMethods
      end

      def get_image_filename(attrname)
      end

      protected

      def openHTMLTagHandler(dom, key, cell)
      end

    end

    def get_image_file(image_uri)
    end
  end
end
