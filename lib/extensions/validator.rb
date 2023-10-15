# frozen_string_literal: false

class Validator
  PARAMS_TYPES = %i[req opt keyreq key block].freeze

  def initialize(arguments)
    @arguments = arguments
  end

  def validate!
    validate(arguments_table).join(", ")
  end

  private

  def arguments_table
    counts = Hash.new(0)
    @arguments.each do |arg|
      type = arg.first
      raise ArgumentError, "@arguments has illegal type: #{type.inspect}." unless PARAMS_TYPES.include?(type)

      counts[type] += 1
    end
    counts
  end

  def validate(counts)
    arr = []
    arr << validate_req if counts[:req].positive?
    arr << validate_opt if counts[:opt].positive?
    arr << validate_keyreq if counts[:keyreq].positive?
    arr << validate_key if counts[:key].positive?
    arr << validate_block if counts[:block].positive?
    arr
  end

  def validate_req
    if (reqs = @arguments.select { _1.first == :req }).any? { _1.size > 2 }
      raise ArgumentError, messages[:req]
    end

    reqs.map(&:last).join(", ")
  end

  def validate_opt
    if (opts = @arguments.select { _1.first == :opt }).any? { _1.size != 3 }
      raise ArgumentError, messages[:opt]
    end

    str = opts.each_with_object("") do |opt, obj|
      obj << "#{opt[1]}=#{opt.last}#{"," if @o_size ||= opts.size == 1}"
    end
    @o_size ? str.chop : str
  end

  def validate_keyreq
    if (keyreqs = @arguments.select { _1.first == :keyreq }).any? { _1.size > 2 }
      raise ArgumentError, messages[:keyreq]
    end

    keyreqs.map(&:last).map { "#{_1}:" }.join(", ")
  end

  def validate_key
    if (keys = @arguments.select { _1.first == :key }).any? { _1.size != 3 }
      raise ArgumentError, messages[:key]
    end

    str = keys.each_with_object("") do |key, obj|
      obj << "#{key[1]}: #{key.last}#{"," if @k_size ||= keys.size == 1}"
    end
    @k_size ? str.chop : str
  end

  def validate_block
    if (block = @arguments.select { _1.first == :block }).any? { _1.size > 2 }
      raise ArgumentError, messages[:block]
    end

    "&#{block[0].last}"
  end

  def messages
    {
      req: "Required params should have no params.",
      opt: "Optional params should have only one value.",
      keyreq: "Required keyword params should be empty.",
      key: "Keyword params should have only one value.",
      block: "Block param should have no values."
    }
  end
end
