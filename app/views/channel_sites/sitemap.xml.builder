xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
xml.urlset xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9' do
  # Главная страница
  xml.url do
    xml.loc @channel_site.full_url
    xml.lastmod @channel_site.updated_at.iso8601
    xml.changefreq 'daily'
    xml.priority '1.0'
  end

  # Страница со всеми постами
  xml.url do
    xml.loc "#{@channel_site.full_url}/posts"
    xml.lastmod @channel_site.updated_at.iso8601
    xml.changefreq 'daily'
    xml.priority '0.8'
  end

  # Посты
  @posts.each do |post|
    xml.url do
      xml.loc "#{@channel_site.full_url}/post/#{post.to_param}"
      xml.lastmod post.updated_at.iso8601
      xml.changefreq 'weekly'
      xml.priority '0.6'
    end
  end
end
