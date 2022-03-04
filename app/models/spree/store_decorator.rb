module Spree
  module StoreDecorator
    def self.prepended(base)
      def sitemaps_path
        "sitemaps/#{code}/"
      end

      def sitemap_prefix
        sitemaps_path.gsub('/', '-')
      end
    end
  end
end

::Spree::Store.prepend ::Spree::StoreDecorator
