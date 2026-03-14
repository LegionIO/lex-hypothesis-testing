# frozen_string_literal: true

require 'legion/extensions/hypothesis_testing/version'
require 'legion/extensions/hypothesis_testing/helpers/constants'
require 'legion/extensions/hypothesis_testing/helpers/hypothesis'
require 'legion/extensions/hypothesis_testing/helpers/hypothesis_engine'
require 'legion/extensions/hypothesis_testing/runners/hypothesis_testing'

module Legion
  module Extensions
    module HypothesisTesting
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
