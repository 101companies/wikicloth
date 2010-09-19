module WikiCloth

class WikiBuffer::Var < WikiBuffer

  def initialize(data="",options={})
    super(data,options)
    self.buffer_type = "var"
    @in_quotes = false
  end

  def skip_html?
    true
  end

  def function_name
    @fname
  end

  def to_s
    if self.is_function?
      return @options[:link_handler].function(function_name, params.collect { |p| p.strip }).to_s
    else
      ret = @options[:link_handler].include_resource("#{params[0]}".strip,params[1..-1])
      # template params
      ret = ret.to_s.gsub(/\{\{\{\s*([A-Za-z0-9]+)\s*\}\}\}/) { |match| get_param($1) }
      # put template at beginning of buffer
      self.data = ret
      ""
    end
  end

  def get_param(name)
    ret = nil
    # numbered params
    if name =~ /^[0-9]+$/
      ret = self.params[name.to_i].instance_of?(Hash) ? self.params[name.to_i][:value] : self.params[name.to_i]
    end
    # named params
    self.params.each do |param|
      ret = param[:value] if param[:name] == name
    end
    ret
  end

  def is_function?
    self.function_name.nil? || self.function_name.blank? ? false : true
  end

  protected
  def function_name=(val)
    @fname = val
  end

  def new_char()
    case
    when current_char == '|' && @in_quotes == false
      self.current_param = self.data
      self.data = ""
      self.params << ""

    # Start of either a function or a namespace change
    when current_char == ':' && @in_quotes == false && self.params.size <= 1
      self.function_name = self.data
      self.data = ""

    # Dealing with variable names within functions
    # and variables
    when current_char == '=' && @in_quotes == false && !is_function?
      self.current_param = self.data
      self.data = ""
      self.name_current_param()

    # End of a template, variable, or function
    when current_char == '}' && previous_char == '}'
      self.data.chop!
      self.current_param = self.data
      self.data = ""
      return false

    else
      self.data += current_char
    end

    return true
  end

end

end
