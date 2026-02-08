ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# Bootsnap ускоряет загрузку, но может вызвать проблемы при сборке Docker образа
# Используйте DISABLE_BOOTSNAP=1 для отключения (например, при assets:precompile)
require "bootsnap/setup" unless ENV["DISABLE_BOOTSNAP"]
