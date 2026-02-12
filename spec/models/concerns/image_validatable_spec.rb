# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageValidatable, type: :model do
  # Создаём временную модель для тестирования concern
  let(:test_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "posts"
      include ImageValidatable
      has_one_attached :image

      validate :validate_test_image, if: -> { image.attached? }

      private

      def validate_test_image
        validate_image_attachment(image)
      end
    end
  end

  let(:model) { test_class.new }

  describe "#validate_image_attachment" do
    context "with valid JPEG image" do
      it "passes validation" do
        # Создаём реальный JPEG файл
        file = Tempfile.new([ "test", ".jpg" ])
        # JPEG magic bytes: FF D8 FF
        file.write("\xFF\xD8\xFF\xE0\x00\x10JFIF")
        file.rewind

        model.image.attach(
          io: file,
          filename: "test.jpg",
          content_type: "image/jpeg"
        )

        expect(model).to be_valid
        expect(model.errors[:image]).to be_empty

        file.close
        file.unlink
      end
    end

    context "with valid PNG image" do
      it "passes validation" do
        file = Tempfile.new([ "test", ".png" ])
        # PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A
        file.write("\x89PNG\r\n\x1A\n")
        file.rewind

        model.image.attach(
          io: file,
          filename: "test.png",
          content_type: "image/png"
        )

        expect(model).to be_valid
        expect(model.errors[:image]).to be_empty

        file.close
        file.unlink
      end
    end

    context "with spoofed content_type (security attack)" do
      it "fails validation when PHP file disguised as image" do
        file = Tempfile.new([ "malicious", ".jpg" ])
        # PHP код вместо изображения
        file.write("<?php system($_GET['cmd']); ?>")
        file.rewind

        model.image.attach(
          io: file,
          filename: "shell.php.jpg",
          content_type: "image/jpeg"  # Подделанный content_type
        )

        expect(model).not_to be_valid
        expect(model.errors[:image]).to include(match(/реальный тип/))

        file.close
        file.unlink
      end
    end

    context "with spoofed extension" do
      it "fails validation when executable disguised as image" do
        file = Tempfile.new([ "malware", ".jpg" ])
        # Исполняемый файл (ELF header)
        file.write("\x7FELF")
        file.rewind

        model.image.attach(
          io: file,
          filename: "virus.exe.jpg",
          content_type: "image/jpeg"
        )

        expect(model).not_to be_valid
        expect(model.errors[:image]).to be_present

        file.close
        file.unlink
      end
    end

    context "with oversized image" do
      it "fails validation when file exceeds max size" do
        file = Tempfile.new([ "large", ".jpg" ])
        # Создаём файл > 10MB
        file.write("\xFF\xD8\xFF\xE0")
        file.write("X" * 11.megabytes)
        file.rewind

        model.image.attach(
          io: file,
          filename: "large.jpg",
          content_type: "image/jpeg"
        )

        expect(model).not_to be_valid
        expect(model.errors[:image]).to include(match(/не больше 10MB/))

        file.close
        file.unlink
      end
    end

    context "with unsupported file type" do
      it "fails validation for PDF file" do
        file = Tempfile.new([ "document", ".pdf" ])
        # PDF magic bytes: %PDF
        file.write("%PDF-1.4")
        file.rewind

        model.image.attach(
          io: file,
          filename: "document.pdf",
          content_type: "application/pdf"
        )

        expect(model).not_to be_valid
        expect(model.errors[:image]).to include(match(/недопустимый тип/))

        file.close
        file.unlink
      end
    end

    context "with custom parameters" do
      it "allows custom field_name" do
        # Используем кастомный метод с другим полем
        allow(model).to receive(:validate_test_image) do
          model.validate_image_attachment(model.image, field_name: :custom_field)
        end

        file = Tempfile.new([ "test", ".txt" ])
        file.write("not an image")
        file.rewind

        model.image.attach(
          io: file,
          filename: "test.txt",
          content_type: "text/plain"
        )

        model.valid?

        expect(model.errors[:custom_field]).to be_present

        file.close
        file.unlink
      end

      it "allows custom allowed_types" do
        # Переопределяем метод для теста
        test_class.class_eval do
          def validate_test_image
            validate_image_attachment(
              image,
              allowed_types: %w[image/jpeg]  # Только JPEG
            )
          end
        end

        file = Tempfile.new([ "test", ".png" ])
        file.write("\x89PNG\r\n\x1A\n")
        file.rewind

        model.image.attach(
          io: file,
          filename: "test.png",
          content_type: "image/png"
        )

        expect(model).not_to be_valid
        expect(model.errors[:image]).to include(match(/недопустимый тип/))

        file.close
        file.unlink
      end
    end
  end

  describe "security logging" do
    it "logs warning when content_type mismatch detected" do
      file = Tempfile.new([ "test", ".jpg" ])
      file.write("\x89PNG\r\n\x1A\n")  # PNG magic bytes
      file.rewind

      model.image.attach(
        io: file,
        filename: "fake.jpg",
        content_type: "image/jpeg"  # Заявлен JPEG, но реально PNG
      )

      expect(Rails.logger).to receive(:warn).with(match(/MIME type mismatch/))

      model.valid?

      file.close
      file.unlink
    end
  end
end
