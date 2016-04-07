Gem::Specification.new do |s|
  s.name        = 'curator'
  s.version     = '0.12.0'
  s.summary     = "Model and repository framework"
  s.description = "Model and repository framework"
  s.authors     = ["Braintree"]
  s.email       = 'code@getbraintree.com'
  s.homepage    = "http://github.com/braintree/curator"
  s.licenses    = ["MIT"]
  s.files       = Dir.glob("lib/**/*.rb")

  s.add_dependency('activesupport', '>= 3.0.0')
  s.add_dependency('activemodel', '>= 3.0.0')
  s.add_dependency('json')
  s.add_dependency('riak-client', '~> 2.3.2')
end
