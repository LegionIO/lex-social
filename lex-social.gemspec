# frozen_string_literal: true

require_relative 'lib/legion/extensions/social/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-social'
  spec.version       = Legion::Extensions::Social::VERSION
  spec.authors       = ['Matthew Iverson']
  spec.email         = ['matt@legionIO.com']
  spec.summary       = 'Social identity and group dynamics for LegionIO cognitive agents'
  spec.description   = 'Models social roles, group membership, reputation, and collective behavior in multi-agent systems'
  spec.homepage      = 'https://github.com/LegionIO/lex-social'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.files = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.add_development_dependency 'legion-gaia'
end
