# frozen_string_literal: true

require 'bundler/gem_tasks'

desc 'Run all the specs'
task :spec do
  sh "bundle exec bacon -q #{FileList['spec/*_spec.rb'].join(' ')}"
end
task default: :spec
task test: :spec
