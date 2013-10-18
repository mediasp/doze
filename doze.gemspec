# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'doze/version'

Gem::Specification.new do |s|
  s.name   = 'doze'
  s.summary = 'RESTful resource-oriented API framework'
  s.description = <<END
Library for building restful APIs, with hierarchical routing, content type
handling and other RESTful stuff
END
  s.version = Doze::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Matthew Willson']
  s.email = ['matthew@playlouder.com']
  s.homepage = 'https://github.com/mjwillson/doze'

  s.add_development_dependency('rake')
  s.add_development_dependency('rack-test')
  s.add_development_dependency('mocha')
  s.add_development_dependency('rdoc')

  s.add_dependency('rack', '~> 1.0')
  s.add_dependency('json')

  s.has_rdoc = true
  s.extra_rdoc_files = ['README.md']
  s.rdoc_options << '--title' << 'Doze' << '--main' << 'README.md' <<
    '--line-numbers'
  s.files = Dir['lib/**/*.rb'] + ['README.md']
  s.test_files = Dir['test/**/*']
end
