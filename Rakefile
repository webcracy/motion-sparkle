desc "Build the gem"
task :gem do
  sh "bundle exec gem build motion-sparkle.gemspec"
  sh "mkdir -p pkg"
  sh "mv *.gem pkg/"
end
task :build => :gem

desc "Clear gem builds"
task :clean do
  FileUtils.rm_rf 'pkg'
  FileUtils.rm_rf 'tmp'
end
task :clear => :clean

desc "Run all the specs"
task :spec do
  sh "bundle exec bacon -q #{FileList['spec/*_spec.rb'].join(' ')}"
end
task :default => :spec
