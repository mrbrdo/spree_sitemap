require 'spree_core'
require 'sitemap_generator'
require 'spree_sitemap/engine'
require 'spree_sitemap/version'
require 'spree_extension'

module SpreeSitemap
  @serve_directly = true
  @robots = <<-ROBOT
# See http://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file
User-agent: *
Disallow: /checkout
Disallow: /cart
Disallow: /orders
Disallow: /user
Disallow: /account
Disallow: /api
Disallow: /password
  ROBOT

  class << self
    attr_accessor :serve_directly, :robots
  end
end
