# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module HypothesisTesting
      module Helpers
        class Hypothesis
          include Constants

          attr_reader :id, :description, :domain, :prior, :posterior,
                      :evidence_count, :status, :created_at

          def initialize(description:, domain: 'general', prior: Constants::PRIOR_DEFAULT)
            @id             = SecureRandom.uuid
            @description    = description
            @domain         = domain
            @prior          = prior.clamp(0.0, 1.0)
            @posterior      = @prior
            @evidence_count = 0
            @status         = :proposed
            @created_at     = Time.now.utc
          end

          def update_posterior!(evidence_strength:, supporting: true)
            return self if @status == :confirmed || @status == :disconfirmed

            @status = :testing
            weight  = Constants::EVIDENCE_WEIGHT * evidence_strength.clamp(0.0, 1.0)

            @posterior = if supporting
                           @posterior + (weight * (1.0 - @posterior))
                         else
                           @posterior - (weight * @posterior)
                         end

            @posterior = @posterior.clamp(0.0, 1.0).round(10)
            @evidence_count += 1
            self
          end

          def confirm!
            @status    = :confirmed
            @posterior = [@posterior, Constants::CONFIRMATION_THRESHOLD].max.round(10)
            self
          end

          def disconfirm!
            @status    = :disconfirmed
            @posterior = [@posterior, Constants::DISCONFIRMATION_THRESHOLD].min.round(10)
            self
          end

          def confidence_label
            Constants::CONFIDENCE_LABELS.each do |range, label|
              return label if range.cover?(@posterior)
            end
            'agnostic'
          end

          def to_h
            {
              id:               @id,
              description:      @description,
              domain:           @domain,
              prior:            @prior,
              posterior:        @posterior,
              evidence_count:   @evidence_count,
              status:           @status,
              confidence_label: confidence_label,
              created_at:       @created_at
            }
          end
        end
      end
    end
  end
end
