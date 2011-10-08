class Redeye::Grammar
# STANDALONE START
    def setup_parser(str, debug=false)
      @string = str
      @pos = 0
      @memoizations = Hash.new { |h,k| h[k] = {} }
      @result = nil
      @failed_rule = nil
      @failing_rule_offset = -1

      setup_foreign_grammar
    end

    # This is distinct from setup_parser so that a standalone parser
    # can redefine #initialize and still have access to the proper
    # parser setup code.
    #
    def initialize(str, debug=false)
      setup_parser(str, debug)
    end

    attr_reader :string
    attr_reader :failing_rule_offset
    attr_accessor :result, :pos

    # STANDALONE START
    def current_column(target=pos)
      if c = string.rindex("\n", target-1)
        return target - c - 1
      end

      target + 1
    end

    def current_line(target=pos)
      cur_offset = 0
      cur_line = 0

      string.each_line do |line|
        cur_line += 1
        cur_offset += line.size
        return cur_line if cur_offset >= target
      end

      -1
    end

    def lines
      lines = []
      string.each_line { |l| lines << l }
      lines
    end

    #

    def get_text(start)
      @string[start..@pos-1]
    end

    def show_pos
      width = 10
      if @pos < width
        "#{@pos} (\"#{@string[0,@pos]}\" @ \"#{@string[@pos,width]}\")"
      else
        "#{@pos} (\"... #{@string[@pos - width, width]}\" @ \"#{@string[@pos,width]}\")"
      end
    end

    def failure_info
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        "line #{l}, column #{c}: failed rule '#{info.name}' = '#{info.rendered}'"
      else
        "line #{l}, column #{c}: failed rule '#{@failed_rule}'"
      end
    end

    def failure_caret
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      line = lines[l-1]
      "#{line}\n#{' ' * (c - 1)}^"
    end

    def failure_character
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset
      lines[l-1][c-1, 1]
    end

    def failure_oneline
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      char = lines[l-1][c-1, 1]

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        "@#{l}:#{c} failed rule '#{info.name}', got '#{char}'"
      else
        "@#{l}:#{c} failed rule '#{@failed_rule}', got '#{char}'"
      end
    end

    class ParseError < RuntimeError
    end

    def raise_error
      raise ParseError, failure_oneline
    end

    def show_error(io=STDOUT)
      error_pos = @failing_rule_offset
      line_no = current_line(error_pos)
      col_no = current_column(error_pos)

      io.puts "On line #{line_no}, column #{col_no}:"

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        io.puts "Failed to match '#{info.rendered}' (rule '#{info.name}')"
      else
        io.puts "Failed to match rule '#{@failed_rule}'"
      end

      io.puts "Got: #{string[error_pos,1].inspect}"
      line = lines[line_no-1]
      io.puts "=> #{line}"
      io.print(" " * (col_no + 3))
      io.puts "^"
    end

    def set_failed_rule(name)
      if @pos > @failing_rule_offset
        @failed_rule = name
        @failing_rule_offset = @pos
      end
    end

    attr_reader :failed_rule

    def match_string(str)
      len = str.size
      if @string[pos,len] == str
        @pos += len
        return str
      end

      return nil
    end

    def scan(reg)
      if m = reg.match(@string[@pos..-1])
        width = m.end(0)
        @pos += width
        return true
      end

      return nil
    end

    if "".respond_to? :getbyte
      def get_byte
        if @pos >= @string.size
          return nil
        end

        s = @string.getbyte @pos
        @pos += 1
        s
      end
    else
      def get_byte
        if @pos >= @string.size
          return nil
        end

        s = @string[@pos]
        @pos += 1
        s
      end
    end

    def parse(rule=nil)
      if !rule
        _root ? true : false
      else
        # This is not shared with code_generator.rb so this can be standalone
        method = rule.gsub("-","_hyphen_")
        __send__("_#{method}") ? true : false
      end
    end

    class LeftRecursive
      def initialize(detected=false)
        @detected = detected
      end

      attr_accessor :detected
    end

    class MemoEntry
      def initialize(ans, pos)
        @ans = ans
        @pos = pos
        @uses = 1
        @result = nil
      end

      attr_reader :ans, :pos, :uses, :result

      def inc!
        @uses += 1
      end

      def move!(ans, pos, result)
        @ans = ans
        @pos = pos
        @result = result
      end
    end

    def external_invoke(other, rule, *args)
      old_pos = @pos
      old_string = @string

      @pos = other.pos
      @string = other.string

      begin
        if val = __send__(rule, *args)
          other.pos = @pos
          other.result = @result
        else
          other.set_failed_rule "#{self.class}##{rule}"
        end
        val
      ensure
        @pos = old_pos
        @string = old_string
      end
    end

    def apply_with_args(rule, *args)
      memo_key = [rule, args]
      if m = @memoizations[memo_key][@pos]
        m.inc!

        prev = @pos
        @pos = m.pos
        if m.ans.kind_of? LeftRecursive
          m.ans.detected = true
          return nil
        end

        @result = m.result

        return m.ans
      else
        lr = LeftRecursive.new(false)
        m = MemoEntry.new(lr, @pos)
        @memoizations[memo_key][@pos] = m
        start_pos = @pos

        ans = __send__ rule, *args

        m.move! ans, @pos, @result

        # Don't bother trying to grow the left recursion
        # if it's failing straight away (thus there is no seed)
        if ans and lr.detected
          return grow_lr(rule, args, start_pos, m)
        else
          return ans
        end

        return ans
      end
    end

    def apply(rule)
      if m = @memoizations[rule][@pos]
        m.inc!

        prev = @pos
        @pos = m.pos
        if m.ans.kind_of? LeftRecursive
          m.ans.detected = true
          return nil
        end

        @result = m.result

        return m.ans
      else
        lr = LeftRecursive.new(false)
        m = MemoEntry.new(lr, @pos)
        @memoizations[rule][@pos] = m
        start_pos = @pos

        ans = __send__ rule

        m.move! ans, @pos, @result

        # Don't bother trying to grow the left recursion
        # if it's failing straight away (thus there is no seed)
        if ans and lr.detected
          return grow_lr(rule, nil, start_pos, m)
        else
          return ans
        end

        return ans
      end
    end

    def grow_lr(rule, args, start_pos, m)
      while true
        @pos = start_pos
        @result = m.result

        if args
          ans = __send__ rule, *args
        else
          ans = __send__ rule
        end
        return nil unless ans

        break if @pos <= m.pos

        m.move! ans, @pos, @result
      end

      @result = m.result
      @pos = m.pos
      return m.ans
    end

    class RuleInfo
      def initialize(name, rendered)
        @name = name
        @rendered = rendered
      end

      attr_reader :name, :rendered
    end

    def self.rule_info(name, rendered)
      RuleInfo.new(name, rendered)
    end

    #


  def block_node(nodes)
    Redeye::Nodes::Block.new(nodes)
  end

  def literal_node(value)
    Redeye::Nodes::Literal.new(value)
  end

  def value_node(value)
    Redeye::Nodes::Value.new(value)
  end

  def assign_node(variable, value)
    Redeye::Nodes::Assign.new(variable, value)
  end


  def setup_foreign_grammar; end

  # root = - expression:exp? - !. {block_node(exp)}
  def _root

    _save = self.pos
    while true # sequence
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = apply(:_expression)
      exp = @result
      unless _tmp
        _tmp = true
        self.pos = _save1
      end
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _save2 = self.pos
      _tmp = get_byte
      _tmp = _tmp ? nil : true
      self.pos = _save2
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; block_node(exp); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_root unless _tmp
    return _tmp
  end

  # expression = (assignment | value)
  def _expression

    _save = self.pos
    while true # choice
      _tmp = apply(:_assignment)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_value)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_expression unless _tmp
    return _tmp
  end

  # assignment = assignable:var - "=" - value:val {assign_node(var, val)}
  def _assignment

    _save = self.pos
    while true # sequence
      _tmp = apply(:_assignable)
      var = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("=")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_value)
      val = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; assign_node(var, val); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_assignment unless _tmp
    return _tmp
  end

  # value = (assignable | literal:val {value_node(val)})
  def _value

    _save = self.pos
    while true # choice
      _tmp = apply(:_assignable)
      break if _tmp
      self.pos = _save

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_literal)
        val = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; value_node(val); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_value unless _tmp
    return _tmp
  end

  # assignable = identifier:val {value_node(val)}
  def _assignable

    _save = self.pos
    while true # sequence
      _tmp = apply(:_identifier)
      val = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; value_node(val); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_assignable unless _tmp
    return _tmp
  end

  # literal = (number | string)
  def _literal

    _save = self.pos
    while true # choice
      _tmp = apply(:_number)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_string)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_literal unless _tmp
    return _tmp
  end

  # identifier = < IDENTIFIER > {literal_node(text)}
  def _identifier

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = apply(:_IDENTIFIER)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; literal_node(text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_identifier unless _tmp
    return _tmp
  end

  # string = (< SIMPLSTRING > {literal_node(text)} | < "\"" STRING "\"" > {literal_node(text)})
  def _string

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _text_start = self.pos
        _tmp = apply(:_SIMPLSTRING)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; literal_node(text); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _text_start = self.pos

        _save3 = self.pos
        while true # sequence
          _tmp = match_string("\"")
          unless _tmp
            self.pos = _save3
            break
          end
          _tmp = apply(:_STRING)
          unless _tmp
            self.pos = _save3
            break
          end
          _tmp = match_string("\"")
          unless _tmp
            self.pos = _save3
          end
          break
        end # end sequence

        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; literal_node(text); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_string unless _tmp
    return _tmp
  end

  # number = < NUMBER > {literal_node(text)}
  def _number

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = apply(:_NUMBER)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; literal_node(text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_number unless _tmp
    return _tmp
  end

  # - = WHITESPACE*
  def __hyphen_
    while true
      _tmp = apply(:_WHITESPACE)
      break unless _tmp
    end
    _tmp = true
    set_failed_rule :__hyphen_ unless _tmp
    return _tmp
  end

  # STRING = /[^\\"]*(?:\\.[^\\"]*)*/
  def _STRING
    _tmp = scan(/\A(?-mix:[^\\"]*(?:\\.[^\\"]*)*)/)
    set_failed_rule :_STRING unless _tmp
    return _tmp
  end

  # SIMPLSTRING = /'[^\\']*(?:\\.[^\\']*)*'/
  def _SIMPLSTRING
    _tmp = scan(/\A(?-mix:'[^\\']*(?:\\.[^\\']*)*')/)
    set_failed_rule :_SIMPLSTRING unless _tmp
    return _tmp
  end

  # NUMBER = /\d*\.?\d+(?:e[+-]?\d+)?/
  def _NUMBER
    _tmp = scan(/\A(?-mix:\d*\.?\d+(?:e[+-]?\d+)?)/)
    set_failed_rule :_NUMBER unless _tmp
    return _tmp
  end

  # IDENTIFIER = /([a-zA-Z_][a-zA-Z0-9_]*)([^\n\S]*:(?!:))?/
  def _IDENTIFIER
    _tmp = scan(/\A(?-mix:([a-zA-Z_][a-zA-Z0-9_]*)([^\n\S]*:(?!:))?)/)
    set_failed_rule :_IDENTIFIER unless _tmp
    return _tmp
  end

  # WHITESPACE = /[^\n\S]/
  def _WHITESPACE
    _tmp = scan(/\A(?-mix:[^\n\S])/)
    set_failed_rule :_WHITESPACE unless _tmp
    return _tmp
  end

  Rules = {}
  Rules[:_root] = rule_info("root", "- expression:exp? - !. {block_node(exp)}")
  Rules[:_expression] = rule_info("expression", "(assignment | value)")
  Rules[:_assignment] = rule_info("assignment", "assignable:var - \"=\" - value:val {assign_node(var, val)}")
  Rules[:_value] = rule_info("value", "(assignable | literal:val {value_node(val)})")
  Rules[:_assignable] = rule_info("assignable", "identifier:val {value_node(val)}")
  Rules[:_literal] = rule_info("literal", "(number | string)")
  Rules[:_identifier] = rule_info("identifier", "< IDENTIFIER > {literal_node(text)}")
  Rules[:_string] = rule_info("string", "(< SIMPLSTRING > {literal_node(text)} | < \"\\\"\" STRING \"\\\"\" > {literal_node(text)})")
  Rules[:_number] = rule_info("number", "< NUMBER > {literal_node(text)}")
  Rules[:__hyphen_] = rule_info("-", "WHITESPACE*")
  Rules[:_STRING] = rule_info("STRING", "/[^\\\\\"]*(?:\\\\.[^\\\\\"]*)*/")
  Rules[:_SIMPLSTRING] = rule_info("SIMPLSTRING", "/'[^\\\\']*(?:\\\\.[^\\\\']*)*'/")
  Rules[:_NUMBER] = rule_info("NUMBER", "/\\d*\\.?\\d+(?:e[+-]?\\d+)?/")
  Rules[:_IDENTIFIER] = rule_info("IDENTIFIER", "/([a-zA-Z_][a-zA-Z0-9_]*)([^\\n\\S]*:(?!:))?/")
  Rules[:_WHITESPACE] = rule_info("WHITESPACE", "/[^\\n\\S]/")
end
