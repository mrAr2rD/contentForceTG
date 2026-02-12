# frozen_string_literal: true

module ChannelPostsHelper
  # Возвращает URL изображения для отображения
  # Поддерживает как Active Storage attachments, так и прямые URLs из media
  def channel_post_image_url(channel_post)
    first_image = channel_post.first_image
    return nil if first_image.blank?

    # Проверяем, является ли это Active Storage attachment
    if first_image.respond_to?(:url)
      # Это Active Storage attachment - генерируем URL
      url_for(first_image)
    else
      # Это URL строка из media
      first_image
    end
  end
end
