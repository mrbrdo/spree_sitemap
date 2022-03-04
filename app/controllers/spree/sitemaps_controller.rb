module Spree
  class SitemapsController < Spree::StoreController
    def show
      filename = params[:sitemap]
      sitemap_key = current_store.sitemap_prefix + filename
      if ActiveStorage::Blob.service.exist?(sitemap_key)
        if ::SpreeSitemap.serve_directly
          if File.extname(sitemap_key).include?('.gz')
            send_data ActiveStorage::Blob.service.download(sitemap_key), filename: filename, content_type: 'application/gzip'
          else
            respond_to do |format|
              format.xml { render body: ActiveStorage::Blob.service.download(sitemap_key) }
            end
          end
        else
          return redirect_to ActiveStorage::Blob.service.url(sitemap_key)
        end
      else
        render plain: '404 Not Found', status: 404
      end
    end
  end
end
