task default: %i[lint spec]

task :lint do
  puts 'Running rubocop'
  puts `bundle exec rubocop -a`
end

task :spec do
  puts 'Running rspec'
  puts `bundle exec rspec`
end
