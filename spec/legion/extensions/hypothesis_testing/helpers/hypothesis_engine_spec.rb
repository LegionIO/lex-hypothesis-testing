# frozen_string_literal: true

require 'legion/extensions/hypothesis_testing/helpers/constants'
require 'legion/extensions/hypothesis_testing/helpers/hypothesis'
require 'legion/extensions/hypothesis_testing/helpers/hypothesis_engine'

RSpec.describe Legion::Extensions::HypothesisTesting::Helpers::HypothesisEngine do
  subject(:engine) { described_class.new }

  describe '#propose' do
    it 'returns a Hypothesis object' do
      h = engine.propose(description: 'test', domain: 'logic')
      expect(h).to be_a(Legion::Extensions::HypothesisTesting::Helpers::Hypothesis)
    end

    it 'stores the hypothesis' do
      h = engine.propose(description: 'stored')
      expect(engine.hypotheses[h.id]).to eq(h)
    end

    it 'assigns the given domain' do
      h = engine.propose(description: 'domain test', domain: 'physics')
      expect(h.domain).to eq('physics')
    end

    it 'uses default domain general when not specified' do
      h = engine.propose(description: 'default domain')
      expect(h.domain).to eq('general')
    end

    it 'assigns the given prior' do
      h = engine.propose(description: 'prior test', prior: 0.3)
      expect(h.prior).to eq(0.3)
    end

    it 'evicts oldest when MAX_HYPOTHESES is reached' do
      max = Legion::Extensions::HypothesisTesting::Helpers::Constants::MAX_HYPOTHESES
      max.times { |i| engine.propose(description: "h#{i}") }
      expect(engine.hypotheses.size).to eq(max)
      oldest_id = engine.hypotheses.values.min_by(&:created_at).id
      engine.propose(description: 'overflow')
      expect(engine.hypotheses.key?(oldest_id)).to be false
    end
  end

  describe '#test_hypothesis' do
    it 'updates posterior when hypothesis exists' do
      h     = engine.propose(description: 'testable', prior: 0.5)
      prior = h.posterior
      engine.test_hypothesis(hypothesis_id: h.id, evidence_strength: 1.0, supporting: true)
      expect(h.posterior).to be > prior
    end

    it 'returns nil for unknown hypothesis_id' do
      result = engine.test_hypothesis(hypothesis_id: 'nonexistent', evidence_strength: 0.5, supporting: true)
      expect(result).to be_nil
    end

    it 'auto-confirms when posterior crosses CONFIRMATION_THRESHOLD' do
      h = engine.propose(description: 'high prior', prior: 0.79)
      engine.test_hypothesis(hypothesis_id: h.id, evidence_strength: 1.0, supporting: true)
      expect(h.status).to eq(:confirmed)
    end

    it 'auto-disconfirms when posterior falls below DISCONFIRMATION_THRESHOLD' do
      h = engine.propose(description: 'low prior', prior: 0.21)
      engine.test_hypothesis(hypothesis_id: h.id, evidence_strength: 1.0, supporting: false)
      expect(h.status).to eq(:disconfirmed)
    end
  end

  describe '#evaluate' do
    it 'returns nil for unknown hypothesis_id' do
      expect(engine.evaluate('nonexistent')).to be_nil
    end

    it 'confirms when posterior >= CONFIRMATION_THRESHOLD' do
      h = engine.propose(description: 'evaluate confirm', prior: 0.9)
      engine.evaluate(h.id)
      expect(h.status).to eq(:confirmed)
    end

    it 'disconfirms when posterior <= DISCONFIRMATION_THRESHOLD' do
      h = engine.propose(description: 'evaluate disconfirm', prior: 0.1)
      engine.evaluate(h.id)
      expect(h.status).to eq(:disconfirmed)
    end

    it 'does not re-evaluate an already confirmed hypothesis' do
      h = engine.propose(description: 'already confirmed', prior: 0.5)
      h.confirm!
      engine.evaluate(h.id)
      expect(h.status).to eq(:confirmed)
    end
  end

  describe '#competing_hypotheses' do
    it 'returns all hypotheses in the given domain' do
      engine.propose(description: 'h1', domain: 'physics')
      engine.propose(description: 'h2', domain: 'physics')
      engine.propose(description: 'h3', domain: 'chemistry')
      result = engine.competing_hypotheses(domain: 'physics')
      expect(result.size).to eq(2)
    end

    it 'returns an empty array when no hypotheses match the domain' do
      engine.propose(description: 'other', domain: 'biology')
      expect(engine.competing_hypotheses(domain: 'astronomy')).to be_empty
    end
  end

  describe '#most_confident' do
    it 'returns hypotheses sorted by descending posterior' do
      h1 = engine.propose(description: 'low',  prior: 0.2)
      h2 = engine.propose(description: 'high', prior: 0.9)
      h3 = engine.propose(description: 'mid',  prior: 0.5)
      result = engine.most_confident(limit: 3)
      expect(result.map(&:id)).to eq([h2.id, h3.id, h1.id])
    end

    it 'respects the limit parameter' do
      5.times { |i| engine.propose(description: "h#{i}", prior: i * 0.1) }
      expect(engine.most_confident(limit: 3).size).to eq(3)
    end
  end

  describe '#confirmation_rate' do
    it 'returns 0.0 when no hypotheses have been resolved' do
      engine.propose(description: 'unresolved')
      expect(engine.confirmation_rate).to eq(0.0)
    end

    it 'computes rate correctly with mixed outcomes' do
      h1 = engine.propose(description: 'h1', prior: 0.9)
      h1.confirm!
      h2 = engine.propose(description: 'h2', prior: 0.1)
      h2.disconfirm!
      expect(engine.confirmation_rate).to eq(0.5)
    end

    it 'returns 1.0 when all resolved hypotheses are confirmed' do
      h = engine.propose(description: 'confirmed', prior: 0.9)
      h.confirm!
      expect(engine.confirmation_rate).to eq(1.0)
    end
  end

  describe '#hypothesis_report' do
    it 'includes total, by_status, confirmation_rate, most_confident' do
      engine.propose(description: 'a')
      engine.propose(description: 'b')
      report = engine.hypothesis_report
      expect(report.keys).to include(:total, :by_status, :confirmation_rate, :most_confident)
    end

    it 'reports correct total count' do
      3.times { |i| engine.propose(description: "h#{i}") }
      expect(engine.hypothesis_report[:total]).to eq(3)
    end

    it 'limits most_confident to 3 entries' do
      5.times { |i| engine.propose(description: "h#{i}") }
      expect(engine.hypothesis_report[:most_confident].size).to be <= 3
    end
  end

  describe '#to_h' do
    it 'includes hypotheses array, confirmation_rate, and total' do
      engine.propose(description: 'serialized')
      result = engine.to_h
      expect(result.keys).to include(:hypotheses, :confirmation_rate, :total)
    end

    it 'returns each hypothesis as a hash' do
      engine.propose(description: 'one')
      engine.to_h[:hypotheses].each do |h|
        expect(h).to be_a(Hash)
        expect(h.keys).to include(:id, :description, :status)
      end
    end
  end
end
