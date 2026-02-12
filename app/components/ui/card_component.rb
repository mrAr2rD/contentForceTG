# frozen_string_literal: true

module Ui
  class CardComponent < ViewComponent::Base
    renders_one :header
    renders_one :footer

    def initialize(**options)
      @options = options
    end

    def call
      content_tag :div, class: card_classes do
        safe_join([
          (content_tag(:div, header, class: header_classes) if header?),
          content_tag(:div, content, class: content_classes),
          (content_tag(:div, footer, class: footer_classes) if footer?)
        ].compact)
      end
    end

    private

    def card_classes
      base = "rounded-lg border border-zinc-200 bg-white text-zinc-950 shadow-sm dark:border-zinc-800 dark:bg-zinc-950 dark:text-zinc-50"
      custom = @options[:class]
      [ base, custom ].compact.join(" ")
    end

    def header_classes
      "flex flex-col space-y-1.5 p-6"
    end

    def content_classes
      "p-6 pt-0"
    end

    def footer_classes
      "flex items-center p-6 pt-0"
    end
  end
end
