require 'librarian'
require 'timecop'

def test_model(&block)
  Class.new do
    include Librarian::Model

    instance_eval(&block)
  end
end
