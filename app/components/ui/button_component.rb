# frozen_string_literal: true

module Ui
  class ButtonComponent < ViewComponent::Base
    VARIANTS = {
      default: "bg-zinc-900 text-zinc-50 hover:bg-zinc-900/90 dark:bg-zinc-50 dark:text-zinc-900 dark:hover:bg-zinc-50/90",
      destructive: "bg-red-500 text-zinc-50 hover:bg-red-500/90 dark:bg-red-900 dark:text-zinc-50 dark:hover:bg-red-900/90",
      outline: "border border-zinc-200 bg-white hover:bg-zinc-100 hover:text-zinc-900 dark:border-zinc-800 dark:bg-zinc-950 dark:hover:bg-zinc-800 dark:hover:text-zinc-50",
      secondary: "bg-zinc-100 text-zinc-900 hover:bg-zinc-100/80 dark:bg-zinc-800 dark:text-zinc-50 dark:hover:bg-zinc-800/80",
      ghost: "hover:bg-zinc-100 hover:text-zinc-900 dark:hover:bg-zinc-800 dark:hover:text-zinc-50",
      link: "text-zinc-900 underline-offset-4 hover:underline dark:text-zinc-50"
    }.freeze

    SIZES = {
      default: "h-10 px-4 py-2",
      sm: "h-9 rounded-md px-3",
      lg: "h-11 rounded-md px-8",
      icon: "h-10 w-10"
    }.freeze

    def initialize(variant: :default, size: :default, **options)
      @variant = variant
      @size = size
      @options = options
    end

    def call
      content_tag :button, content, **html_options
    end

    private

    def html_options
      {
        class: classes,
        type: @options[:type] || "button",
        disabled: @options[:disabled],
        data: @options[:data] || {}
      }.merge(@options.except(:variant, :size, :type, :disabled, :data, :class))
    end

    def classes
      base_classes = "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium ring-offset-white transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-zinc-950 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 dark:ring-offset-zinc-950 dark:focus-visible:ring-zinc-300"
      
      variant_classes = VARIANTS[@variant] || VARIANTS[:default]
      size_classes = SIZES[@size] || SIZES[:default]
      custom_classes = @options[:class]

      [base_classes, variant_classes, size_classes, custom_classes].compact.join(" ")
    end
  end
end
