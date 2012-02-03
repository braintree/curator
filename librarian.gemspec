Gem::Specification.new do |s|
  s.name        = 'librarian'
  s.version     = '0.1.0'
  s.summary     = "Model and repository framework"
  s.description = "Model and repository framework"
  s.authors     = ["Braintree"]
  s.email       = 'code@getbraintree.com'
  s.files       = ["lib/hola.rb"]
  s.files       = Dir.glob("lib/**/*.rb")

  s.add_dependency('activesupport', '>= 3.0.0')
end
