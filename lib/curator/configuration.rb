require 'english'

class Curator::Configuration
  def initialize
    @options = {}
  end

  def method_missing(name, *args, &block)
    name_symbol = name.to_sym
    if name.to_s =~ /=$/
      @options[$PREMATCH.to_sym] = args.first
    elsif @options.has_key?(name_symbol)
      @options[name_symbol]
    else
      super
    end
  end

  def respond_to?(name)
    super || @options.has_key?(name.to_sym)
  end
end
