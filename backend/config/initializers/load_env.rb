# Optionally load ENV from repo-root ../.env or backend/.env without requiring dotenv gem.
# Existing ENV values always win (do not override).

env_paths = [
  Rails.root.join(".env"),
  Rails.root.join("..", ".env")
]

env_paths.each do |path|
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
