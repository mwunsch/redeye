require 'kpeg/compiled_parser'

class Redeye::Grammar < KPeg::CompiledParser

  # root = - expression:exp? - !. { exp }
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
      @result = begin;  exp ; end
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

  # assignment = < identifier:left - "=" - value:right > { "[ASSIGNMENT <#{left} = #{right}>]" }
  def _assignment

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_identifier)
        left = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string("=")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_value)
        right = @result
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  "[ASSIGNMENT <#{left} = #{right}>]" ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_assignment unless _tmp
    return _tmp
  end

  # value = (identifier | literal)
  def _value

    _save = self.pos
    while true # choice
      _tmp = apply(:_identifier)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_literal)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_value unless _tmp
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

  # identifier = < IDENTIFIER > { "[IDENTIFIER #{text}]" }
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
      @result = begin;  "[IDENTIFIER #{text}]" ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_identifier unless _tmp
    return _tmp
  end

  # string = < STRING > { "[STRING '#{text}']" }
  def _string

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = apply(:_STRING)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  "[STRING '#{text}']" ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_string unless _tmp
    return _tmp
  end

  # number = < NUMBER > { "[NUMBER #{text}]" }
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
      @result = begin;  "[NUMBER #{text}]" ; end
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

  # STRING = /'[^\\']*(?:\\.[^\\']*)*'/
  def _STRING
    _tmp = scan(/\A(?-mix:'[^\\']*(?:\\.[^\\']*)*')/)
    set_failed_rule :_STRING unless _tmp
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
  Rules[:_root] = rule_info("root", "- expression:exp? - !. { exp }")
  Rules[:_expression] = rule_info("expression", "(assignment | value)")
  Rules[:_assignment] = rule_info("assignment", "< identifier:left - \"=\" - value:right > { \"[ASSIGNMENT <\#{left} = \#{right}>]\" }")
  Rules[:_value] = rule_info("value", "(identifier | literal)")
  Rules[:_literal] = rule_info("literal", "(number | string)")
  Rules[:_identifier] = rule_info("identifier", "< IDENTIFIER > { \"[IDENTIFIER \#{text}]\" }")
  Rules[:_string] = rule_info("string", "< STRING > { \"[STRING '\#{text}']\" }")
  Rules[:_number] = rule_info("number", "< NUMBER > { \"[NUMBER \#{text}]\" }")
  Rules[:__hyphen_] = rule_info("-", "WHITESPACE*")
  Rules[:_STRING] = rule_info("STRING", "/'[^\\\\']*(?:\\\\.[^\\\\']*)*'/")
  Rules[:_NUMBER] = rule_info("NUMBER", "/\\d*\\.?\\d+(?:e[+-]?\\d+)?/")
  Rules[:_IDENTIFIER] = rule_info("IDENTIFIER", "/([a-zA-Z_][a-zA-Z0-9_]*)([^\\n\\S]*:(?!:))?/")
  Rules[:_WHITESPACE] = rule_info("WHITESPACE", "/[^\\n\\S]/")
end
