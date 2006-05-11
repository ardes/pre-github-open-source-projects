namespace :test do
  namespace :plugins do
    desc 'Test plugins individually'
    task :individually do
      plugins = FileList['vendor/plugins/**'].collect { |plugin| File.basename(plugin) }
      plugins.each do |plugin|
        puts "\nRunning tests for #{plugin}:\n"
        puts `rake test:plugins PLUGIN=#{plugin}`
      end
    end
  end
end
