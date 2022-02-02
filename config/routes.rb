Spree::Core::Engine.add_routes do
  # Add your extension routes here
  get '/:sitemap', to: 'sitemaps#show', constraints: {sitemap: /sitemap\d*\.xml(\.gz)?/}
end
