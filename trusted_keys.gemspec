# -*- encoding: utf-8 -*-
require File.expand_path('../lib/trusted_keys/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Anders Törnqvist"]
  gem.email         = ["anders.tornqvist@gmail.com"]
  gem.description   = %q{Mass assignment security in your controller}
  gem.summary       = %q{Mass assignment security in your controller}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "trusted_keys"
  gem.require_paths = ["lib"]
  gem.version       = TrustedKeys::VERSION

  gem.add_runtime_dependency "rails", ["~> 3.0"]
end
