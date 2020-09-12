require_relative "errors"
require_relative "utils"

module Bhm
  # The meat of the library
  module Validation
    def self.included(receiver)
      # NOTE: Methods **MUST** be in the included block -- otherwise we pollute the module constants with
      # any "initializer" module we include/extend
      receiver.singleton_class.class_eval do
        def config(**cfg)
          pending_case, pending_keys = cfg.values_at(:default_key_case, :default_key_type)

          case_options = [:lower_snake, :lowerCamel, :UpperCamel, :SCREAMING_SNAKE, nil]
          fail ArgumentError, "casing must be one of #{case_options.inspect}" unless case_options.include? pending_case
          @___default_key_case = pending_case

          key_options = [:symbols, :strings, nil]
          fail ArgumentError, "keys must be one of #{key_options.inspect}" unless key_options.include? pending_keys
          @___default_key_type = pending_keys
        end

        # Concise API for setting both case assertion & key conformity simultaneously
        def keys(arg)
          key_option = arg.is_a?(String) ? :strings : :symbols
          config(
            default_key_type: key_option,
            default_key_case: arg.to_sym
          )
        end

        def default_key_case
          # @___default_key_case ||= TODO_GLOBAL_CONFIG
          @___default_key_case
        end

        def default_key_type
          # @___default_key_type ||= TODO_GLOBAL_CONFIG
          @___default_key_type
        end

        # TODO: `nullable` method

        def guard(handler)
          guards << handler
        end

        def guards
          @___guards ||= []
        end

        #### 4 ways to define a validator:
        ## Explicit key+proc:
        # validator "KEY", ->(){}
        # @KEY = "KEY", ->(){}
        #
        ## Explicit key+typecheck
        # validator "KEY", String
        # @KEY = "KEY", String
        #
        ## Implicit proc
        # @___default_key_type = :strings
        # @KEY = ->(){}
        #
        ## Implicit typecheck
        # @___default_key_type = :strings
        # @KEY = String
        def validators
          instance_variables.each_with_object({}) do |ivar, out|
            # Skip our internals
            next if ivar.to_s.start_with? "@___"

            arg = instance_variable_get(ivar)
            final_key, ambiguous_arg = case arg
            when Array
              # Assume the array idx0 is the key, idx1 is the handler or a Ruby class
              arg.slice(0, 2)
            else
              # Assume some implicit flow. Use ivar name as key value
              subbed = ivar.to_s.gsub(/^@/, "")
              formatted_key = case default_key_type
              when :strings then subbed
              when :symbols then subbed.to_sym
              else
                # In the event no default settings are provided, default to sym assertion
                subbed.to_sym
              end

              # Re-send the original arg
              [formatted_key, arg]
            end

            # Lastly, check the ambiguous arg & set the finalized handler
            out[final_key] = case ambiguous_arg
            when Proc then ambiguous_arg # It is a dedicated proc handler
            when Class then ->(fetched_value) { fetched_value.is_a?(ambiguous_arg) } # They want us to typecheck
            else
              # Assume bad user input
              fail ArgumentError, "could not implement validator (supplied arg: #{ambiguous_arg.inspect}"
            end
          end
        end

        # Explicit API to set a key & handler, ignoring case/key-type config
        def validator(key, handler)
          # Use our array handling, to specifically bypass key checks
          instance_variable_set("@#{key}", [key, handler])
        end
      end

      # Define getters for each of these methods
      %i[validators guards default_key_case default_key_type].each do |method_name|
        define_method(method_name) do
          singleton_class.included_modules.find { |mod|
            mod.include? Validation
          }.public_send(method_name)
        end
      end
    end

    # TODO: Assert the keys hash conform to a casing stantard
    def validate_keys!
      if default_key_type
        klass = case default_key_type
        when :symbols then Symbol
        when :strings then String
        end

        keys.each do |string_or_sym|
          Errors::InvalidKeyType.raise!(receiver: self, key: string_or_sym, type: default_key_type) unless string_or_sym.is_a? klass
        end
      end

      case default_key_case
      when :lower_snake
        # TODO
      when :lowerCamel
        # TODO
      when :UpperCamel
        # TODO
      when :SCREAMING_SNAKE
        # TODO
      end
    end

    def validate!
      validate_keys!

      run_guards!

      # Run validation
      run_validators!

      # If we reach this line, the schema is valid.
      self
    end

    def errors
      @errors ||= []
    end

    def valid?
      @errors = []
      return true if validate!

      # Only rescue lib-defined classes here. Let all other errors surface
    rescue Errors::InvalidHash, Errors::WontValidate => e
      @errors = e.error_chain
      false
    end

    private

    def run_validators!
      validators.each do |key, handler|
        hash = fetch(key)

        result = handler.call(hash)
        Errors::InvalidValue.raise!(key: key, receiver: self) unless result
      rescue KeyError
        mod = (singleton_class.included_modules.select { |mod| mod.include? Validation }).first
        Errors::InvalidHash.raise!("could not validate: #{mod}", key: key, receiver: self)
      end
    end

    def run_guards!
      guards.each do |handler|
        result = handler.call(self)

        Errors::WontValidate.raise!(receiver: self) unless result
      end
    end
  end
end
