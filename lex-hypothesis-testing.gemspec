# frozen_string_literal: true

require_relative 'lib/legion/extensions/hypothesis_testing/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-hypothesis-testing'
  spec.version       = Legion::Extensions::HypothesisTesting::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Hypothesis Testing'
  spec.description   = 'Scientific hypothesis testing cycle for brain-modeled agentic AI — ' \
                       'Bayesian evidence accumulation, lifecycle management, competing hypotheses'
  spec.homepage      = 'https://github.com/LegionIO/lex-hypothesis-testing'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-hypothesis-testing'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-hypothesis-testing'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-hypothesis-testing'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-hypothesis-testing/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-hypothesis-testing.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
