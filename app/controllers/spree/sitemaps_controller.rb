module Spree
  class SitemapsController < Spree::StoreController
    def show
      filename = params[:sitemap]
      if ActiveStorage::Blob.service.exist?(filename)
        if ::SpreeSitemap.serve_directly
          if File.extname(filename).include?('.gz')
            send_data ActiveStorage::Blob.service.download(filename), filename: filename, content_type: 'application/gzip'
          else
            respond_to do |format|
              format.xml { render body: ActiveStorage::Blob.service.download(filename) }
            end
          end
        else
          return redirect_to ActiveStorage::Blob.service.url(params[:sitemap])
        end
      else
        render plain: '404 Not Found', status: 404
      end
    end
  end
end
