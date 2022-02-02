class SitemapJob < ApplicationJob
  queue_as :default

  def perform(*args)
    SitemapGenerator::Interpreter.run(config_file: Rails.root.join('config/sitemap.rb'))
    Dir.glob(Rails.root.join('public', 'sitemap*')).each do |filepath| # upload sitemap to cloud storage
      service = ActiveStorage::Blob.service
      file = File.open(filepath)
      key = File.basename(filepath)
      service.upload(key, file)
    end

    SitemapGenerator::Sitemap.ping_search_engines
  end
end
