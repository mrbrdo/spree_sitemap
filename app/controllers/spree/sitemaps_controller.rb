module Spree
  class SitemapsController < Spree::StoreController
    def show
      filename = params[:sitemap]
      if ::SpreeSitemap.serve_directly
        # send_data ActiveStorage::Blob.service.download(filename), filename: filename, content_type: 'application/xml'
        respond_to do |format|
          format.xml { render body: ActiveStorage::Blob.service.download(filename) }
        end
      else
        return redirect_to ActiveStorage::Blob.service.url(params[:sitemap])
      end
    end
  end
end
