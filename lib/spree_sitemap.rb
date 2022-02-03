require 'spree_core'
require 'sitemap_generator'
require 'spree_sitemap/engine'
require 'spree_sitemap/version'
require 'spree_extension'

module SpreeSitemap
  @serve_directly = true

  class << self
    attr_accessor :serve_directly
  end
end
