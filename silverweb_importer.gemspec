$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "silverweb_importer/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "silverweb_importer"
  s.version     = SilverwebImporter::VERSION
  s.authors     = ["Robert Lee Little III"]
  s.email       = ["rob@silverwebsystems.com"]
  s.homepage    = "http://www.silverwebsystems.com/"
  s.summary     = "plugin to silverweb cms to allow users to easliy import csv/excel/openoffice sheets into any database table."
  s.description = "Silverweb Importer."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_development_dependency "mysql2"

  s.add_dependency "rails", "~>  5.1.4"
  s.add_dependency 'silverweb_cms'
  s.add_dependency 'rubyzip'
  s.add_dependency 'spreadsheet'
  s.add_dependency 'roo', '~> 2.1.0'
  s.add_dependency 'roo-xls'
  
  s.add_dependency 'carrierwave'
  s.add_dependency 'rmagick'
  s.add_dependency 'rat'
end


