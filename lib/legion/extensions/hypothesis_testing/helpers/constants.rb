# frozen_string_literal: true

module Legion
  module Extensions
    module HypothesisTesting
      module Helpers
        module Constants
          MAX_HYPOTHESES             = 300
          CONFIRMATION_THRESHOLD     = 0.8
          DISCONFIRMATION_THRESHOLD  = 0.2
          EVIDENCE_WEIGHT            = 0.1
          PRIOR_DEFAULT              = 0.5

          STATUS_LABELS = {
            proposed:     'Proposed',
            testing:      'Testing',
            confirmed:    'Confirmed',
            disconfirmed: 'Disconfirmed',
            inconclusive: 'Inconclusive'
          }.freeze

          CONFIDENCE_LABELS = [
            [0.9..1.0,  'certain'],
            [0.7...0.9, 'confident'],
            [0.5...0.7, 'leaning'],
            [0.3...0.5, 'uncertain'],
            [0.0...0.3, 'agnostic']
          ].freeze
        end
      end
    end
  end
end
