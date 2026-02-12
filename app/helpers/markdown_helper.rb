# frozen_string_literal: true

module MarkdownHelper
  # Рендерит Markdown в HTML с поддержкой SEO-дружественных тегов
  def render_markdown(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      link_attributes: { target: "_blank", rel: "noopener noreferrer" },
      with_toc_data: true
    )

    markdown = Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      highlight: true,
      superscript: true,
      underline: true,
      no_intra_emphasis: true
    )

    markdown.render(text).html_safe
  end

  # Извлекает первый h1 заголовок из markdown текста
  # Возвращает заголовок без символов #
  def extract_h1_from_markdown(text)
    return nil if text.blank?

    # Ищем первый заголовок h1 (# в начале строки)
    match = text.match(/^#\s+(.+)$/m)
    match ? match[1].strip : nil
  end

  # Рендерит Markdown в HTML, исключая h1 заголовок
  # h1 используется как заголовок статьи/страницы
  def render_markdown_without_h1(text)
    return "" if text.blank?

    # Удаляем первый h1 заголовок из текста
    # Ищем строку, начинающуюся с одного # (но не ##, ###, и т.д.)
    text_without_h1 = text.sub(/^#\s+.+$\n?/, "")

    # Рендерим остальной контент
    render_markdown(text_without_h1)
  end
end
