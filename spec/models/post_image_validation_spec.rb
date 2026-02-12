# frozen_string_literal: true

require "rails_helper"

RSpec.describe Post, "image validation with magic bytes", type: :model do
  let(:user) { create(:user) }
  let(:post) { build(:post, user: user) }

  describe "valid images" do
    it "accepts valid JPEG image" do
      file = Tempfile.new([ "post", ".jpg" ])
      file.write("\xFF\xD8\xFF\xE0\x00\x10JFIF")
      file.rewind

      post.image.attach(
        io: file,
        filename: "photo.jpg",
        content_type: "image/jpeg"
      )

      expect(post).to be_valid

      file.close
      file.unlink
    end

    it "accepts valid PNG image" do
      file = Tempfile.new([ "post", ".png" ])
      file.write("\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR")
      file.rewind

      post.image.attach(
        io: file,
        filename: "graphic.png",
        content_type: "image/png"
      )

      expect(post).to be_valid

      file.close
      file.unlink
    end

    it "accepts valid WebP image" do
      file = Tempfile.new([ "post", ".webp" ])
      # WebP magic bytes: RIFF....WEBP
      file.write("RIFF\x00\x00\x00\x00WEBPVP8 ")
      file.rewind

      post.image.attach(
        io: file,
        filename: "modern.webp",
        content_type: "image/webp"
      )

      expect(post).to be_valid

      file.close
      file.unlink
    end

    it "accepts valid GIF image" do
      file = Tempfile.new([ "post", ".gif" ])
      # GIF89a magic bytes
      file.write("GIF89a")
      file.rewind

      post.image.attach(
        io: file,
        filename: "animation.gif",
        content_type: "image/gif"
      )

      expect(post).to be_valid

      file.close
      file.unlink
    end
  end

  describe "security: magic bytes validation" do
    it "rejects PHP shell disguised as JPEG" do
      file = Tempfile.new([ "shell", ".jpg" ])
      file.write("<?php system($_GET['c']); ?>")
      file.rewind

      post.image.attach(
        io: file,
        filename: "backdoor.php.jpg",
        content_type: "image/jpeg"
      )

      expect(post).not_to be_valid
      expect(post.errors[:image]).to include(match(/реальный тип/))

      file.close
      file.unlink
    end

    it "rejects HTML file disguised as image" do
      file = Tempfile.new([ "xss", ".jpg" ])
      file.write("<!DOCTYPE html><script>alert('XSS')</script>")
      file.rewind

      post.image.attach(
        io: file,
        filename: "xss.html.jpg",
        content_type: "image/jpeg"
      )

      expect(post).not_to be_valid
      expect(post.errors[:image]).to be_present

      file.close
      file.unlink
    end

    it "rejects executable disguised as PNG" do
      file = Tempfile.new([ "malware", ".png" ])
      # Windows PE header
      file.write("MZ\x90\x00")
      file.rewind

      post.image.attach(
        io: file,
        filename: "virus.exe.png",
        content_type: "image/png"
      )

      expect(post).not_to be_valid
      expect(post.errors[:image]).to be_present

      file.close
      file.unlink
    end

    it "rejects SVG file (potential XSS vector)" do
      file = Tempfile.new([ "xss", ".svg" ])
      file.write('<svg><script>alert("XSS")</script></svg>')
      file.rewind

      post.image.attach(
        io: file,
        filename: "xss.svg",
        content_type: "image/svg+xml"
      )

      expect(post).not_to be_valid
      expect(post.errors[:image]).to include(match(/недопустимый тип/))

      file.close
      file.unlink
    end
  end

  describe "size validation" do
    it "rejects images larger than 10MB" do
      file = Tempfile.new([ "huge", ".jpg" ])
      file.write("\xFF\xD8\xFF\xE0")
      file.write("X" * 11.megabytes)
      file.rewind

      post.image.attach(
        io: file,
        filename: "huge.jpg",
        content_type: "image/jpeg"
      )

      expect(post).not_to be_valid
      expect(post.errors[:image]).to include(match(/не больше 10MB/))

      file.close
      file.unlink
    end

    it "accepts images under 10MB" do
      file = Tempfile.new([ "normal", ".jpg" ])
      file.write("\xFF\xD8\xFF\xE0\x00\x10JFIF")
      file.write("X" * 1.megabyte)
      file.rewind

      post.image.attach(
        io: file,
        filename: "normal.jpg",
        content_type: "image/jpeg"
      )

      expect(post).to be_valid

      file.close
      file.unlink
    end
  end

  describe "integration with post types" do
    context "when post_type is image" do
      it "requires image attachment" do
        post = build(:post, user: user, post_type: :image, status: :published)
        expect(post).not_to be_valid
        expect(post.errors[:image]).to include("обязательно для постов с изображением")
      end

      it "validates attached image" do
        post = build(:post, user: user, post_type: :image)

        file = Tempfile.new([ "post", ".jpg" ])
        file.write("\xFF\xD8\xFF\xE0")
        file.rewind

        post.image.attach(
          io: file,
          filename: "valid.jpg",
          content_type: "image/jpeg"
        )

        expect(post).to be_valid

        file.close
        file.unlink
      end
    end
  end
end
