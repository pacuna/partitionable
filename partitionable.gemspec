$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "partitionable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "partitionable"
  s.version     = Partitionable::VERSION
  s.authors     = ["Pablo Acuña"]
  s.email       = ["pablo@archdaily.com"]
  s.homepage    = "http://www.archdaily.com"
  s.summary     = "Summary of Partitionable."
  s.description = "Description of Partitionable."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0.0", ">= 5.0.0.1"

  s.add_development_dependency "pg"
  s.add_development_dependency "codecov"
end
