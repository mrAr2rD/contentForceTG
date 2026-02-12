# frozen_string_literal: true

# Concern для валидации изображений с проверкой magic bytes
# Защита от загрузки вредоносных файлов с подмененным content_type
module ImageValidatable
  extend ActiveSupport::Concern

  # Разрешённые MIME типы для изображений
  ALLOWED_IMAGE_TYPES = %w[
    image/jpeg
    image/png
    image/webp
    image/gif
  ].freeze

  # Максимальный размер изображения (10MB по умолчанию)
  MAX_IMAGE_SIZE = 10.megabytes

  included do
    # Валидация вызывается через validate_image_attachment в конкретной модели
  end

  # Валидирует attachment с проверкой magic bytes
  # @param attachment [ActiveStorage::Attached] - attachment для проверки
  # @param field_name [Symbol] - имя поля для errors (по умолчанию :image)
  # @param allowed_types [Array<String>] - разрешённые MIME типы
  # @param max_size [Integer] - максимальный размер в байтах
  def validate_image_attachment(attachment, field_name: :image, allowed_types: ALLOWED_IMAGE_TYPES, max_size: MAX_IMAGE_SIZE)
    return unless attachment.attached?

    blob = attachment.blob

    # 1. Проверка размера
    validate_attachment_size(blob, field_name, max_size)

    # 2. Проверка content_type (первая линия защиты)
    validate_content_type(blob, field_name, allowed_types)

    # 3. КРИТИЧНО: Проверка magic bytes (реальный тип файла)
    validate_magic_bytes(attachment, blob, field_name, allowed_types)
  end

  private

  # Проверка размера файла
  def validate_attachment_size(blob, field_name, max_size)
    return unless blob.byte_size > max_size

    size_mb = (blob.byte_size / 1024.0 / 1024).round(2)
    max_mb = (max_size / 1024.0 / 1024).round(0)
    errors.add(field_name, "должно быть не больше #{max_mb}MB (текущий размер: #{size_mb}MB)")
  end

  # Проверка заявленного content_type
  def validate_content_type(blob, field_name, allowed_types)
    return if allowed_types.include?(blob.content_type)

    errors.add(field_name, "недопустимый тип файла: #{blob.content_type}. Разрешены: #{allowed_types.join(', ')}")
  end

  # КРИТИЧНО: Проверка magic bytes для определения реального типа файла
  # Защита от атак с подменой расширения (example.php.jpg) или content_type
  def validate_magic_bytes(attachment, blob, field_name, allowed_types)
    # Открываем файл и читаем его через Marcel для определения реального MIME типа
    attachment.open do |file|
      # Marcel::MimeType.for читает magic bytes файла
      detected_type = Marcel::MimeType.for(file, name: blob.filename.to_s, declared_type: blob.content_type)

      unless allowed_types.include?(detected_type)
        errors.add(
          field_name,
          "содержит недопустимый формат. " \
          "Заявленный тип: #{blob.content_type}, " \
          "реальный тип (magic bytes): #{detected_type}. " \
          "Разрешены: #{allowed_types.join(', ')}"
        )
      end

      # Дополнительная проверка: соответствие заявленного и реального типа
      if blob.content_type != detected_type
        Rails.logger.warn(
          "[Security] MIME type mismatch detected! " \
          "File: #{blob.filename}, " \
          "Declared: #{blob.content_type}, " \
          "Detected: #{detected_type}"
        )
      end
    end
  rescue StandardError => e
    Rails.logger.error("[Security] Failed to validate magic bytes for #{blob.filename}: #{e.message}")
    errors.add(field_name, "не удалось проверить формат файла. Попробуйте другой файл.")
  end
end
