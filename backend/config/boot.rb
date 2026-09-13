ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# Load local ENV files early (before database.yml ERB).
[File.expand_path("../.env", __dir__), File.expand_path("../../.env", __dir__)].each do |path|
  next unless File.file?(path)

  File.foreach(path) do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")

    key, value = line.split("=", 2)
    next if key.nil? || value.nil?

    key = key.strip
    value = value.strip
    value = value[1..-2] if (value.start_with?('"') && value.end_with?('"')) ||
                            (value.start_with?("'") && value.end_with?("'"))
    ENV[key] = value unless ENV.key?(key)
  end
end

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
