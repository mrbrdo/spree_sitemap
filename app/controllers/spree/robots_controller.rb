module Spree
  class RobotsController < Spree::StoreController
    def robots
      content = ::SpreeSitemap.robots
      unless content.downcase.include?("sitemap")
        sitemap = "Sitemap: #{current_store.formatted_url}/sitemap.xml"
        content += "\n" + sitemap
      end

      render plain: content
    end
  end
end
