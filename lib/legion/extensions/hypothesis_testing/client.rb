# frozen_string_literal: true

require 'legion/extensions/hypothesis_testing/helpers/constants'
require 'legion/extensions/hypothesis_testing/helpers/hypothesis'
require 'legion/extensions/hypothesis_testing/helpers/hypothesis_engine'
require 'legion/extensions/hypothesis_testing/runners/hypothesis_testing'

module Legion
  module Extensions
    module HypothesisTesting
      class Client
        include Runners::HypothesisTesting

        def initialize(**)
          @hypothesis_engine = Helpers::HypothesisEngine.new
        end

        private

        attr_reader :hypothesis_engine
      end
    end
  end
end
