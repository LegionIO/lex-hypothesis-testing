# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module HypothesisTesting
      module Runners
        module HypothesisTesting
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def propose_hypothesis(description:, domain: 'general', prior: Helpers::Constants::PRIOR_DEFAULT, **)
            h = hypothesis_engine.propose(description: description, domain: domain, prior: prior)
            Legion::Logging.debug "[hypothesis_testing] proposed id=#{h.id[0..7]} domain=#{domain} prior=#{prior}"
            {
              hypothesis_id:    h.id,
              description:      h.description,
              domain:           h.domain,
              prior:            h.prior,
              posterior:        h.posterior,
              status:           h.status,
              confidence_label: h.confidence_label
            }
          end

          def test_hypothesis(hypothesis_id:, evidence_strength:, supporting: true, **)
            h = hypothesis_engine.test_hypothesis(
              hypothesis_id:     hypothesis_id,
              evidence_strength: evidence_strength,
              supporting:        supporting
            )
            unless h
              Legion::Logging.debug "[hypothesis_testing] test failed: #{hypothesis_id[0..7]} not found"
              return { tested: false, reason: :not_found }
            end

            Legion::Logging.info "[hypothesis_testing] tested #{hypothesis_id[0..7]} " \
                                 "supporting=#{supporting} strength=#{evidence_strength} " \
                                 "posterior=#{h.posterior.round(4)} status=#{h.status}"
            {
              tested:           true,
              hypothesis_id:    h.id,
              posterior:        h.posterior,
              evidence_count:   h.evidence_count,
              status:           h.status,
              confidence_label: h.confidence_label
            }
          end

          def evaluate_hypothesis(hypothesis_id:, **)
            h = hypothesis_engine.evaluate(hypothesis_id)
            unless h
              Legion::Logging.debug "[hypothesis_testing] evaluate failed: #{hypothesis_id[0..7]} not found"
              return { found: false }
            end

            Legion::Logging.debug "[hypothesis_testing] evaluated #{hypothesis_id[0..7]} status=#{h.status}"
            {
              found:            true,
              hypothesis_id:    h.id,
              status:           h.status,
              posterior:        h.posterior,
              confidence_label: h.confidence_label,
              evidence_count:   h.evidence_count
            }
          end

          def competing_hypotheses(domain:, **)
            hypotheses = hypothesis_engine.competing_hypotheses(domain: domain)
            Legion::Logging.debug "[hypothesis_testing] competing count=#{hypotheses.size} domain=#{domain}"
            {
              domain:     domain,
              count:      hypotheses.size,
              hypotheses: hypotheses.map(&:to_h)
            }
          end

          def most_confident_hypotheses(limit: 5, **)
            hypotheses = hypothesis_engine.most_confident(limit: limit)
            Legion::Logging.debug "[hypothesis_testing] most_confident count=#{hypotheses.size}"
            {
              count:      hypotheses.size,
              hypotheses: hypotheses.map(&:to_h)
            }
          end

          def hypothesis_report(**)
            report = hypothesis_engine.hypothesis_report
            Legion::Logging.debug "[hypothesis_testing] report total=#{report[:total]} " \
                                  "confirmation_rate=#{report[:confirmation_rate].round(4)}"
            report
          end

          def get_hypothesis(hypothesis_id:, **)
            h = hypothesis_engine.hypotheses[hypothesis_id]
            return { found: false } unless h

            { found: true, hypothesis: h.to_h }
          end

          private

          def hypothesis_engine
            @hypothesis_engine ||= Helpers::HypothesisEngine.new
          end
        end
      end
    end
  end
end
