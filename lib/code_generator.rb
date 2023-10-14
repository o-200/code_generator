# frozen_string_literal: true

module CodeGenerator
  class Error < StandardError; end
  # Your code goes here...
end

require_relative 'extensions/extensions'
require_relative "code_generator/version"
require_relative 'code_generator/generator'
