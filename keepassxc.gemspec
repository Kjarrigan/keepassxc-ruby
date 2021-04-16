require_relative 'lib/keepassxc/version'

Gem::Specification.new do |spec|
  spec.name          = 'keepassxc'
  spec.version       = KeepassXC::VERSION
  spec.authors       = ['Holger Arndt']
  spec.email         = ['keepassxc-ruby@kjarrigan.de']

  spec.summary       = %q{Ruby bindings for the KeepassXC Browser API}
  spec.description   = %q{Ruby bindings for the KeepassXC Browser API}
  spec.homepage      = 'https://github.com/Kjarrigan/keepassxc-ruby'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  spec.files         = Dir.chdir(__dir__) do
    `git ls-files`.split("\n").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = %w{keepassxc-rb}
  spec.require_paths = ['lib']
end
