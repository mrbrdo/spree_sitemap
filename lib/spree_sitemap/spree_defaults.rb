module SpreeSitemap::SpreeDefaults
  include Spree::Core::Engine.routes.url_helpers
  include Spree::BaseHelper # for meta_data

  cattr_accessor :cur_product_id
  cattr_accessor :product_idx

  def default_url_options
    { host: SitemapGenerator::Sitemap.default_host }
  end

  def store_locales
    @@store_locales ||= Spree::Store.first.supported_locales_list
  end

  def path_with_host(path)
    return default_url_options[:host] if path.blank?
    default_url_options[:host].to_s.sub(/\/$/, '') + '/' + path.gsub(/\A\//, '')
  end

  def add_login(options = {})
    add(login_path(locale: Mobility.locale), options)
  end

  def add_signup(options = {})
    add(signup_path(locale: Mobility.locale), options)
  end

  def add_account(options = {})
    add(account_path(locale: Mobility.locale), options)
  end

  def add_password_reset(options = {})
    add(new_spree_user_password_path(locale: Mobility.locale), options)
  end

  def add_products(options = {})
    begin
      active_products = Spree::Product.includes(:translations).select(:id, :slug, :updated_at).active.distinct

      @@product_idx ||= 1
      @@cur_product_id ||= 1
      if @@cur_product_id <= 1
        add(products_path(locale: Mobility.locale), options.merge(lastmod: active_products.last_updated))
      end

      active_products.find_in_batches(batch_size: 2500, start: @@cur_product_id) do |products|
        products.each do |product|
          add_product(product, options)

          @@product_idx += 1
        end

        @@cur_product_id = products.last.id
      end

      @@cur_product_id = 1
    rescue ActiveRecord::ActiveRecordError => e
      ActiveRecord::Base.connection.reconnect!
      sleep 5

      retry
    end
  end

  def add_product(product, options = {})
    opts = options.merge(lastmod: product.updated_at)

    if gem_available?('spree_videos') && product.videos.present?
      # TODO: add exclusion list configuration option
      # https://sites.google.com/site/webmasterhelpforum/en/faq-video-sitemaps#multiple-pages

      # don't include all the videos on the page to avoid duplicate title warnings
      primary_video = product.videos.first
      opts.merge!(video: [video_options(primary_video.youtube_ref, product)])
    end

    if store_locales.size > 1
      opts.merge!(
        alternates: store_locales.map do |locale|
          Mobility.with_locale(locale) do
            { href: path_with_host(product_path(product, locale: locale)), lang: locale }
          end
        end
      )
    end

    add(product_path(product, locale: Mobility.locale), opts)
  end

  def add_pages(options = {})
    # TODO: this should be refactored to add_pages & add_page

    Spree::Page.active.each do |page|
      add(page.path, options.merge(lastmod: page.updated_at))
    end if gem_available? 'spree_essential_cms'

    Spree::Page.visible.each do |page|
      add(page.slug, options.merge(lastmod: page.updated_at))
    end if gem_available? 'spree_static_content'
  end

  def add_taxons(options = {})
    Spree::Taxon.includes(:translations).roots.each { |taxon| add_taxon(taxon, options) }
  end

  def add_taxon(taxon, options = {})
    taxon.self_and_descendants.each do |t|
      next unless t.permalink.present?
      opts = { lastmod: t.updated_at }

      if store_locales.size > 1
        opts.merge!(
          alternates: store_locales.map do |locale|
            Mobility.with_locale(locale) do
              { href: path_with_host(nested_taxons_path(t, locale: locale)), lang: locale }
            end
          end
        )
      end

      add(nested_taxons_path(t, locale: Mobility.locale), opts)
    end
  end

  def gem_available?(name)
    Gem::Specification.find_by_name(name)
  rescue Gem::LoadError
    false
  rescue
    Gem.available?(name)
  end

  def main_app
    Rails.application.routes.url_helpers
  end

  private

  ##
  # Multiple videos of the same ID can exist, but all videos linked in the sitemap should be inique
  #
  # Required video fields:
  # http://www.seomoz.org/blog/video-sitemap-guide-for-vimeo-and-youtube
  #
  # YouTube thumbnail images:
  # http://www.reelseo.com/youtube-thumbnail-image/
  #
  # NOTE title should match the page title, however the title generation isn't self-contained
  # although not a future proof solution, the best (+ easiest) solution is to mimic the title for product pages
  #   https://github.com/spree/spree/blob/1-3-stable/core/lib/spree/core/controller_helpers/common.rb#L39
  #   https://github.com/spree/spree/blob/1-3-stable/core/app/controllers/spree/products_controller.rb#L41
  #
  def video_options(youtube_id, object = false)
    ({ description: meta_data(object)[:description] } rescue {}).merge(
      ({ title: [Spree::Config[:site_name], object.name].join(' - ') } rescue {})
    ).merge(
      thumbnail_loc: "http://img.youtube.com/vi/#{youtube_id}/0.jpg",
      player_loc: "http://www.youtube.com/v/#{youtube_id}",
      autoplay: 'ap=1'
    )
  end
end
