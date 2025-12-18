namespace :telephone do
  desc "Migrate required: true to include validates: { presence: true } for v2.0 compatibility"
  task :migrate, [:path] do |_t, args|
    path = args[:path] || "app/services"

    unless Dir.exist?(path)
      puts "Directory not found: #{path}"
      puts "Usage: rake telephone:migrate[path/to/services]"
      exit 1
    end

    files_updated = 0

    Dir.glob("#{path}/**/*.rb").each do |file|
      content = File.read(file)
      original = content.dup

      content.gsub!(/^(\s*argument\s+:\w+.*)required:\s*true(.*)$/) do |line|
        if line.include?("validates:")
          line
        else
          line.sub(/required:\s*true/, "required: true, validates: { presence: true }")
        end
      end

      if content != original
        File.write(file, content)
        puts "Updated: #{file}"
        files_updated += 1
      end
    end

    if files_updated == 0
      puts "No files needed updating."
    else
      puts "\nUpdated #{files_updated} file(s)."
      puts "Review the changes and run your tests to verify."
    end
  end
end
