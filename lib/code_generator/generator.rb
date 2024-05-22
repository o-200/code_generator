# frozen_string_literal: true

module CodeGenerator # :nodoc:
  class Generator # :nodoc:
    PARAMS_TYPES = %i[req opt keyreq key block].freeze

    # +CodeGenerator::Generator#new+                 -> CodeGenerator::Generator
    #
    # This object constructor helps to easily create class with stubbed methods (with support of public, public
    # singleton, private and private singleton methods and their params). For e.g., we want to create a class which
    # has several public methods:
    # @example
    #   # By passing array of Symbols or Strings
    #   code = CodeGenerator.new(public_methods: %i[method1 method2])
    #   code.methods(false) #=> [:method1, :method2]
    #   # By passing number of methods
    #   code = CodeGenerator.new(public_methods: 3)
    #   code.methods(false) #=> [:method1, :method2, :method3]
    # If you want to pass arguments, you can pass it according the following signature. Note that only +:opt+ and +:key+
    # variables can be predefined (by default they would be nil), also +:block+ variable could be presented only once for
    # each method:
    # @example
    #   code = CodeGenerator.new(public_methods: [:method1, [:method2, { args: [[:req, :foo],
    #                                                                           [:req, :bar],
    #                                                                           [:opt, :opts, {}],
    #                                                                           [:keyreq, :some_keyword],
    #                                                                           [:key, :some_key, 123],
    #                                                                           [:block, :some_block]],
    #                                                                    should_return: 123 }], :method3])
    # If you want to specify returnable object, you can pass it inside +:should_return+ key. Also you can pass class
    # names, but method would return class itself. Note that +shout+return+ and +generate+ args passed as options for
    # specific method would override global values of this two args:
    # @example
    #   # By passing object
    #   code = CodeGenerator.new(public_methods: [[:method1, { should_return: 123 }])
    #   code.method1 #=> 123
    #   # By passing class (not all classes are supported)
    #   code = CodeGenerator.new(public_methods: [[:method1, { should_return: Integer, generate: true }])
    #   code.method1 #=> some random Integer
    #
    # @param [Integer|String|Symbol|Array<String|Symbol|Hash<Symbol, Class|Boolean>>] public_methods
    def initialize(public_methods: nil, public_class_methods: nil, private_methods: nil, private_class_methods: nil,
                   should_return: nil, generate: false)
      @public_methods = public_methods
      @public_class_methods = public_class_methods
      @private_methods = private_methods
      @private_class_methods = private_class_methods
      @should_return = should_return
      @generate = generate
    end

    # +CodeGenerator::Generator#generate_code+                 -> value
    #
    #
    def generate_code
      generate_public_methods
      generate_public_class_methods
      generate_private_methods
    end

    private

    def generate_public_methods
      case @public_methods
      when String, Symbol
        # code = CodeGenerator.new(public_methods: :method1, should_return: 123, generate: true)
        return define_singleton_method(@public_methods) {} unless any_generation_rules

        object_to_return = operate_on_value(@should_return, @generate)
        define_singleton_method(@public_methods) { object_to_return }
      when Integer
        # code = CodeGenerator.new(public_methods: 1, should_return: 123, generate: true)
        return if @public_methods.negative? || @public_methods.zero?

        object_to_return = operate_on_value(@should_return, @generate)

        1.upto(@public_methods) do |time|
          define_singleton_method("method#{time}") do
            object_to_return
          end
        end
      when Array
        return if @public_methods.empty?

        @public_methods.each do |m|
          if m.instance_of?(Symbol) || m.instance_of?(String)
            if !both_generation_rules
              define_singleton_method(m) {}
            elsif any_generation_rules
              object_to_return = operate_on_value(@should_return, @generate)
              define_singleton_method(m) do
                object_to_return
              end
            end
          elsif m.instance_of?(Array)
            unless (m_name = m.first).instance_of?(Symbol) || m_name.instance_of?(String)
              raise ArgumentError, "Method name should be Symbol or String, but #{m_name.class} was passed."
            end
            unless (opts = m.last).is_a?(Hash) # && (arguments = opts[:args]).is_a?(Array)
              raise ArgumentError, "Method arguments should behave as Hash, but #{m_name.class} was passed."
            end

            arguments = opts[:args] ? arguments_parser(opts[:args]) : nil
            object_to_return = operate_on_value(opts[:should_return], opts[:generate]).inspect
            instance_eval <<-METHOD, __FILE__, __LINE__ + 1
              def #{m_name}(#{arguments})
                #{object_to_return}
              end
            METHOD
          end
        end
      when NilClass
        nil
      else
        raise ArgumentError, "public_methods is #{@public_methods.class} but expected Array[Symbol|String] or Integer."
      end
    end

    def generate_public_class_methods
      case @public_class_methods
      when String, Symbol
        return self.class.define_singleton_method(@public_class_methods) {} unless any_generation_rules

        object_to_return = operate_on_value(@should_return, @generate)
        self.class.define_singleton_method(@public_class_methods) { object_to_return }
      when Integer
        # code = CodeGenerator.new(public_class_methods: 1, should_return: 123, generate: true)
        return if @public_class_methods.negative? || @public_class_methods.zero?

        object_to_return = operate_on_value(@should_return, @generate)

        1.upto(@public_class_methods) do |time|
          self.class.define_singleton_method("method#{time}") do
            object_to_return
          end
        end
      when Array
        return if @public_class_methods.empty?

        @public_class_methods.each do |m|
          if m.instance_of?(Symbol) || m.instance_of?(String)
            if !both_generation_rules
              self.class.define_singleton_method(m) {}
            elsif any_generation_rules
              object_to_return = operate_on_value(@should_return, @generate)
              self.class.define_singleton_method(m) do
                object_to_return
              end
            end
          elsif m.instance_of?(Array)
            unless (m_name = m.first).instance_of?(Symbol) || m_name.instance_of?(String)
              raise ArgumentError, "Method name should be Symbol or String, but #{m_name.class} was passed."
            end
            unless (opts = m.last).is_a?(Hash) # && (arguments = opts[:args]).is_a?(Array)
              raise ArgumentError, "Method arguments should behave as Hash, but #{m_name.class} was passed."
            end

            arguments = opts[:args] ? arguments_parser(opts[:args]) : nil
            object_to_return = operate_on_value(opts[:should_return], opts[:generate]).inspect
            class_eval <<-METHOD, __FILE__, __LINE__ + 1
              def #{m_name}(#{arguments})
                #{object_to_return}
              end
            METHOD
          end
        end
      when NilClass
        nil
      else
        raise ArgumentError, "public_methods is #{@public_class_methods.class} but expected Array[Symbol|String] or Integer."
      end
    end

    def generate_private_methods
      case @private_methods
      when String, Symbol
        # code = CodeGenerator::Generator.new(private_methods: :method1, should_return: 123, generate: true)
        return define_singleton_method(@private_methods) {} unless any_generation_rules

        object_to_return = operate_on_value(@should_return, @generate)
        define_singleton_method(@private_methods) { object_to_return }
      when Integer
        # code = CodeGenerator::Generator.new (private_methods: 1, should_return: 123, generate: true)
        return if @private_methods.negative? || @private_methods.zero?

        object_to_return = operate_on_value(@should_return, @generate)

        1.upto(@private_methods) do |time|
          define_singleton_method("method#{time}") do
            object_to_return
          end
        end
      when Array
        return if @private_methods.empty?

        @private_methods.each do |m|
          if m.instance_of?(Symbol) || m.instance_of?(String)
            if !both_generation_rules
              define_singleton_method(m) {}
            elsif any_generation_rules
              object_to_return = operate_on_value(@should_return, @generate)
              define_singleton_method(m) do
                object_to_return
              end
            end
          elsif m.instance_of?(Array)
            unless (m_name = m.first).instance_of?(Symbol) || m_name.instance_of?(String)
              raise ArgumentError, "Method name should be Symbol or String, but #{m_name.class} was passed."
            end
            unless (opts = m.last).is_a?(Hash) # && (arguments = opts[:args]).is_a?(Array)
              raise ArgumentError, "Method arguments should behave as Hash, but #{m_name.class} was passed."
            end

            arguments = opts[:args] ? arguments_parser(opts[:args]) : nil
            object_to_return = operate_on_value(opts[:should_return], opts[:generate]).inspect
            instance_eval <<-METHOD, __FILE__, __LINE__ + 1
              def #{m_name}(#{arguments})
                #{object_to_return}
              end
            METHOD
          end
        end
      when NilClass
        nil
      else
        raise ArgumentError, "public_methods is #{@private_methods.class} but expected Array[Symbol|String] or Integer."
      end
    end

    def any_generation_rules
      @should_return || @generate
    end

    def both_generation_rules
      @should_return && @generate
    end

    def operate_on_value(should_return, generate)
      random_object = if generate && should_return.instance_of?(Class)
                        generate_random_object(should_return)
                      elsif should_return
                        should_return
                      end

      return random_object if random_object && should_return

      random_object || should_return
    end

    def generate_random_object(klass)
      case klass.name
      when "Integer"
        rand.to_s.sub(/.*?\./, "").to_i
      when "String"
        SecureRandom.alphanumeric(10)
      when "Symbol"
        SecureRandom.alphanumeric(10).to_sym
      end
    end

    def arguments_parser(arguments)
      validator = Validator.new(arguments)
      validator.validate!
    end
  end
end
