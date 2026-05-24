Gem::Specification.new do |s|
  s.name        = "dashboard"
  s.version     = "0.1.0"
  s.summary     = "Dashboard analytics engine for Square"
  s.authors     = ["Square Team"]
  s.files       = Dir["{app,config,lib}/**/*", "Rakefile"]
  s.add_dependency "rails", ">= 7.0"
end
