# frozen_string_literal: true

module Legion
  module Extensions
    module HypothesisTesting
      module Helpers
        class HypothesisEngine
          include Constants

          attr_reader :hypotheses

          def initialize
            @hypotheses = {}
          end

          def propose(description:, domain: 'general', prior: Constants::PRIOR_DEFAULT)
            evict_oldest! if @hypotheses.size >= Constants::MAX_HYPOTHESES

            h = Hypothesis.new(description: description, domain: domain, prior: prior)
            @hypotheses[h.id] = h
            h
          end

          def test_hypothesis(hypothesis_id:, evidence_strength:, supporting: true)
            h = @hypotheses[hypothesis_id]
            return nil unless h

            h.update_posterior!(evidence_strength: evidence_strength, supporting: supporting)
            evaluate(hypothesis_id)
            h
          end

          def evaluate(hypothesis_id)
            h = @hypotheses[hypothesis_id]
            return nil unless h
            return h if %i[confirmed disconfirmed].include?(h.status)

            if h.posterior >= Constants::CONFIRMATION_THRESHOLD
              h.confirm!
            elsif h.posterior <= Constants::DISCONFIRMATION_THRESHOLD
              h.disconfirm!
            else
              h
            end
          end

          def competing_hypotheses(domain:)
            @hypotheses.values.select { |h| h.domain == domain }
          end

          def most_confident(limit: 5)
            @hypotheses.values
                       .sort_by { |h| -h.posterior }
                       .first(limit)
          end

          def confirmation_rate
            total = @hypotheses.values.count { |h| %i[confirmed disconfirmed].include?(h.status) }
            return 0.0 if total.zero?

            confirmed = @hypotheses.values.count { |h| h.status == :confirmed }
            (confirmed.to_f / total).round(10)
          end

          def hypothesis_report
            by_status = @hypotheses.values.group_by(&:status).transform_values(&:count)
            {
              total:             @hypotheses.size,
              by_status:         by_status,
              confirmation_rate: confirmation_rate,
              most_confident:    most_confident(limit: 3).map(&:to_h)
            }
          end

          def to_h
            {
              hypotheses:        @hypotheses.values.map(&:to_h),
              confirmation_rate: confirmation_rate,
              total:             @hypotheses.size
            }
          end

          private

          def evict_oldest!
            oldest_key = @hypotheses.min_by { |_, h| h.created_at }&.first
            @hypotheses.delete(oldest_key) if oldest_key
          end
        end
      end
    end
  end
end
