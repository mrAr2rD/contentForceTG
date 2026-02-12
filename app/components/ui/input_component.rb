# frozen_string_literal: true

module Ui
  class InputComponent < ViewComponent::Base
    def initialize(name:, type: "text", **options)
      @name = name
      @type = type
      @options = options
    end

    def call
      tag :input, **html_options
    end

    private

    def html_options
      {
        type: @type,
        name: @name,
        id: @options[:id] || @name,
        class: classes,
        placeholder: @options[:placeholder],
        value: @options[:value],
        disabled: @options[:disabled],
        required: @options[:required],
        data: @options[:data] || {}
      }.merge(@options.except(:type, :name, :id, :class, :placeholder, :value, :disabled, :required, :data))
    end

    def classes
      base_classes = "flex h-10 w-full rounded-md border border-zinc-200 bg-white px-3 py-2 text-base ring-offset-white file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-zinc-950 placeholder:text-zinc-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-zinc-950 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm dark:border-zinc-800 dark:bg-zinc-950 dark:ring-offset-zinc-950 dark:file:text-zinc-50 dark:placeholder:text-zinc-400 dark:focus-visible:ring-zinc-300"
      custom_classes = @options[:class]

      [ base_classes, custom_classes ].compact.join(" ")
    end
  end
end
