module Spree
  class SitemapsController < Spree::StoreController
    def show
      return redirect_to ActiveStorage::Blob.service.url(params[:sitemap])
    end
  end
end
