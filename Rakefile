# frozen_string_literal: true

require 'rake/testtask'
require 'dotenv/load'

task default: %i[test]

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.test_files = FileList['./test/**/*_test.rb']
                 .exclude(
                     './test/**/skipped_tests/**/*'
                   )
  t.verbose = false
end