require 'kpeg/compiled_parser'

class Redeye::Grammar < KPeg::CompiledParser

  # number = < /^\d*\.?\d+(?:e[+-]?\d+)?/ > { text }
  def _number

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = scan(/\A(?-mix:^\d*\.?\d+(?:e[+-]?\d+)?)/)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  text ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_number unless _tmp
    return _tmp
  end

  # root = number:num !. { num }
  def _root

    _save = self.pos
    while true # sequence
      _tmp = apply(:_number)
      num = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = get_byte
      _tmp = _tmp ? nil : true
      self.pos = _save1
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  num ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_root unless _tmp
    return _tmp
  end

  Rules = {}
  Rules[:_number] = rule_info("number", "< /^\\d*\\.?\\d+(?:e[+-]?\\d+)?/ > { text }")
  Rules[:_root] = rule_info("root", "number:num !. { num }")
end
