class SitemapJob < ApplicationJob
  queue_as :default

  def perform(*args)
    ::Spree::Store.all.each do |store|
      if store.respond_to?(:formatted_host)
        host = store.formatted_host
      else
        host = nil
        if store.url.present?
          begin
            uri = URI(store.formatted_url)
            host = "#{uri.scheme}://#{uri.host}"
            unless uri.port.in?([80, 443])
              host += ":#{uri.port}"
            end
          rescue
          end
        end
      end
      if host.blank?
        next
      end

      SitemapGenerator::Sitemap.default_host = host
      SitemapGenerator::Sitemap.compress = false
      SitemapGenerator::Sitemap.sitemaps_path = store.sitemaps_path

      SitemapGenerator::Sitemap.create do
        add_login
        add_signup
        add_account
        add_password_reset
        add_taxons
        add_products
      end

      index_url = SitemapGenerator::Sitemap.sitemap_index_url
      if index_url.blank?
        next
      end

      service = ActiveStorage::Blob.service

      sitemaps_path = SitemapGenerator::Sitemap.sitemaps_path
      SitemapGenerator::Sitemap.public_path.glob(File.join(sitemaps_path, 'sitemap*.xml*')).each do |pn|
        sitemap_path = pn.to_s
        sitemap_key = "#{sitemaps_path}#{pn.basename.to_s}".gsub('/', '-')
        service.upload(sitemap_key, File.open(sitemap_path))
      end

      # sitemap_name = begin
      #   uri = URI(index_url)
      #   uri.path.sub('/', '')
      # rescue
      #   nil
      # end

      # if sitemap_name.blank?
      #   next
      # end

      # sitemap_path = SitemapGenerator::Sitemap.public_path + sitemap_name
      # unless File.exist?(sitemap_path)
      #   next
      # end

      # service = ActiveStorage::Blob.service
      # file = File.open(sitemap_path)
      # key = File.basename(sitemap_name.gsub('/', '-'))
      # service.upload(key, file)

      SitemapGenerator::Sitemap.ping_search_engines
    end
  end
end
