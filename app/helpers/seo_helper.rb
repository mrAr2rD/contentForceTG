# frozen_string_literal: true

module SeoHelper
  # Получить SEO данные для текущей страницы
  def page_seo(slug = nil)
    slug ||= controller_name == "pages" ? action_name : controller_name
    @_page_seo ||= PageSeo.for_page(slug)
  end

  # Title страницы
  def seo_title(default = nil)
    seo = page_seo
    title = seo&.title.presence || default || "ContentForce"
    site_name = SiteConfiguration.current.effective_site_name

    if title.include?(site_name)
      title
    else
      "#{title} — #{site_name}"
    end
  end

  # Meta description
  def seo_description(default = nil)
    seo = page_seo
    seo&.description.presence || default
  end

  # OpenGraph title
  def seo_og_title(default = nil)
    seo = page_seo
    seo&.effective_og_title.presence || default || seo_title
  end

  # OpenGraph description
  def seo_og_description(default = nil)
    seo = page_seo
    seo&.effective_og_description.presence || default || seo_description
  end

  # Canonical URL
  def seo_canonical_url
    seo = page_seo
    seo&.canonical_url.presence || request.original_url.split("?").first
  end

  # OG Image
  def seo_og_image
    SiteConfiguration.current.default_og_image.presence
  end

  # Рендер всех SEO мета-тегов
  def render_seo_tags(options = {})
    seo = page_seo(options[:slug])
    config = SiteConfiguration.current

    tags = []

    # Title
    title = options[:title] || seo&.title
    if title.present?
      full_title = title.include?(config.effective_site_name) ? title : "#{title} — #{config.effective_site_name}"
      tags << tag.title(full_title)
    end

    # Description
    description = options[:description] || seo&.description
    tags << tag.meta(name: "description", content: description) if description.present?

    # Canonical
    canonical = seo&.canonical_url.presence || request.original_url.split("?").first
    tags << tag.link(rel: "canonical", href: canonical)

    # OpenGraph
    og_title = seo&.effective_og_title.presence || title
    og_description = seo&.effective_og_description.presence || description

    tags << tag.meta(property: "og:type", content: "website")
    tags << tag.meta(property: "og:title", content: og_title) if og_title.present?
    tags << tag.meta(property: "og:description", content: og_description) if og_description.present?
    tags << tag.meta(property: "og:url", content: canonical)
    tags << tag.meta(property: "og:site_name", content: config.effective_site_name)

    if config.default_og_image.present?
      tags << tag.meta(property: "og:image", content: config.default_og_image)
    end

    # Twitter Card
    tags << tag.meta(name: "twitter:card", content: "summary_large_image")
    tags << tag.meta(name: "twitter:title", content: og_title) if og_title.present?
    tags << tag.meta(name: "twitter:description", content: og_description) if og_description.present?

    if config.default_og_image.present?
      tags << tag.meta(name: "twitter:image", content: config.default_og_image)
    end

    safe_join(tags, "\n    ")
  end

  # Рендер скриптов аналитики
  def render_analytics_scripts
    config = SiteConfiguration.current
    scripts = []

    # Яндекс.Метрика
    if config.yandex_metrika_id.present?
      scripts << render_yandex_metrika(config.yandex_metrika_id)
    end

    # Google Analytics
    if config.google_analytics_id.present?
      scripts << render_google_analytics(config.google_analytics_id)
    end

    safe_join(scripts, "\n")
  end

  private

  def render_yandex_metrika(counter_id)
    <<~HTML.html_safe
      <!-- Yandex.Metrika counter -->
      <script type="text/javascript">
          (function(m,e,t,r,i,k,a){
              m[i]=m[i]||function(){(m[i].a=m[i].a||[]).push(arguments)};
              m[i].l=1*new Date();
              for (var j = 0; j < document.scripts.length; j++) {if (document.scripts[j].src === r) { return; }}
              k=e.createElement(t),a=e.getElementsByTagName(t)[0],k.async=1,k.src=r,a.parentNode.insertBefore(k,a)
          })(window, document,'script','https://mc.yandex.ru/metrika/tag.js?id=#{counter_id}', 'ym');

          ym(#{counter_id}, 'init', {ssr:true, webvisor:true, clickmap:true, ecommerce:"dataLayer", accurateTrackBounce:true, trackLinks:true});
      </script>
      <noscript><div><img src="https://mc.yandex.ru/watch/#{counter_id}" style="position:absolute; left:-9999px;" alt="" /></div></noscript>
      <!-- /Yandex.Metrika counter -->
    HTML
  end

  def render_google_analytics(measurement_id)
    <<~HTML.html_safe
      <!-- Google Analytics -->
      <script async src="https://www.googletagmanager.com/gtag/js?id=#{measurement_id}"></script>
      <script>
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', '#{measurement_id}');
      </script>
      <!-- /Google Analytics -->
    HTML
  end
end
