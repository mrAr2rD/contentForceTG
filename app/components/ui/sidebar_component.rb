# frozen_string_literal: true

module Ui
  class SidebarComponent < ViewComponent::Base
    renders_many :items, "SidebarItemComponent"
    renders_one :header
    renders_one :footer

    def initialize(**options)
      @options = options
    end

    def call
      content_tag :aside, class: sidebar_classes do
        safe_join([
          (content_tag(:div, header, class: "p-4 border-b border-zinc-200 dark:border-zinc-800") if header?),
          content_tag(:nav, class: "flex-1 overflow-y-auto p-4 space-y-1") do
            safe_join(items.map(&:to_s))
          end,
          (content_tag(:div, footer, class: "p-4 border-t border-zinc-200 dark:border-zinc-800") if footer?)
        ].compact)
      end
    end

    private

    def sidebar_classes
      "flex flex-col h-full w-64 bg-zinc-50 border-r border-zinc-200 dark:bg-zinc-900 dark:border-zinc-800"
    end

    class SidebarItemComponent < ViewComponent::Base
      def initialize(label:, href:, icon: nil, active: false, **options)
        @label = label
        @href = href
        @icon = icon
        @active = active
        @options = options
      end

      def call
        link_to @href, class: item_classes, data: { turbo_frame: "_top" } do
          safe_join([
            (@icon ? content_tag(:span, @icon, class: "text-lg") : nil),
            content_tag(:span, @label, class: "text-sm font-medium")
          ].compact)
        end
      end

      private

      def item_classes
        base = "flex items-center gap-3 px-3 py-2 rounded-md transition-colors"
        active_classes = "bg-zinc-200 text-zinc-900 dark:bg-zinc-800 dark:text-zinc-50"
        inactive_classes = "text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 dark:text-zinc-400 dark:hover:bg-zinc-800 dark:hover:text-zinc-50"

        [ base, @active ? active_classes : inactive_classes ].join(" ")
      end
    end
  end
end
