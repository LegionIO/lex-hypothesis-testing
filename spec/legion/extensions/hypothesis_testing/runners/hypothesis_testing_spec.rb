# frozen_string_literal: true

require 'legion/extensions/hypothesis_testing/client'

RSpec.describe Legion::Extensions::HypothesisTesting::Runners::HypothesisTesting do
  let(:client) { Legion::Extensions::HypothesisTesting::Client.new }

  describe '#propose_hypothesis' do
    it 'returns a hypothesis_id uuid' do
      result = client.propose_hypothesis(description: 'water boils at 100C')
      expect(result[:hypothesis_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns the description' do
      result = client.propose_hypothesis(description: 'gravity exists')
      expect(result[:description]).to eq('gravity exists')
    end

    it 'returns the domain' do
      result = client.propose_hypothesis(description: 'test', domain: 'physics')
      expect(result[:domain]).to eq('physics')
    end

    it 'defaults domain to general' do
      result = client.propose_hypothesis(description: 'test')
      expect(result[:domain]).to eq('general')
    end

    it 'returns status :proposed' do
      result = client.propose_hypothesis(description: 'test')
      expect(result[:status]).to eq(:proposed)
    end

    it 'returns a confidence_label' do
      result = client.propose_hypothesis(description: 'test', prior: 0.9)
      expect(result[:confidence_label]).to eq('certain')
    end

    it 'sets prior and posterior to the given prior' do
      result = client.propose_hypothesis(description: 'test', prior: 0.7)
      expect(result[:prior]).to eq(0.7)
      expect(result[:posterior]).to eq(0.7)
    end
  end

  describe '#test_hypothesis' do
    let(:proposed) { client.propose_hypothesis(description: 'testable') }

    it 'returns tested: true for a known hypothesis' do
      result = client.test_hypothesis(hypothesis_id: proposed[:hypothesis_id], evidence_strength: 0.5, supporting: true)
      expect(result[:tested]).to be true
    end

    it 'returns tested: false for an unknown id' do
      result = client.test_hypothesis(hypothesis_id: 'missing', evidence_strength: 0.5, supporting: true)
      expect(result[:tested]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'includes updated posterior' do
      result = client.test_hypothesis(hypothesis_id: proposed[:hypothesis_id], evidence_strength: 1.0, supporting: true)
      expect(result[:posterior]).to be > proposed[:posterior]
    end

    it 'includes updated evidence_count' do
      result = client.test_hypothesis(hypothesis_id: proposed[:hypothesis_id], evidence_strength: 0.5, supporting: true)
      expect(result[:evidence_count]).to eq(1)
    end

    it 'includes status' do
      result = client.test_hypothesis(hypothesis_id: proposed[:hypothesis_id], evidence_strength: 0.5, supporting: true)
      expect(result.key?(:status)).to be true
    end

    it 'returns :confirmed status when posterior crosses threshold' do
      h = client.propose_hypothesis(description: 'high prior', prior: 0.79)
      result = client.test_hypothesis(hypothesis_id: h[:hypothesis_id], evidence_strength: 1.0, supporting: true)
      expect(result[:status]).to eq(:confirmed)
    end
  end

  describe '#evaluate_hypothesis' do
    it 'returns found: false for unknown id' do
      result = client.evaluate_hypothesis(hypothesis_id: 'ghost')
      expect(result[:found]).to be false
    end

    it 'returns found: true for known hypothesis' do
      h      = client.propose_hypothesis(description: 'evaluatable')
      result = client.evaluate_hypothesis(hypothesis_id: h[:hypothesis_id])
      expect(result[:found]).to be true
    end

    it 'confirms hypothesis when posterior is above threshold' do
      h = client.propose_hypothesis(description: 'high', prior: 0.9)
      result = client.evaluate_hypothesis(hypothesis_id: h[:hypothesis_id])
      expect(result[:status]).to eq(:confirmed)
    end
  end

  describe '#competing_hypotheses' do
    it 'returns hypotheses in the given domain' do
      client.propose_hypothesis(description: 'h1', domain: 'biology')
      client.propose_hypothesis(description: 'h2', domain: 'biology')
      client.propose_hypothesis(description: 'h3', domain: 'chemistry')
      result = client.competing_hypotheses(domain: 'biology')
      expect(result[:count]).to eq(2)
      expect(result[:domain]).to eq('biology')
    end

    it 'returns empty list for unrepresented domain' do
      result = client.competing_hypotheses(domain: 'astrology')
      expect(result[:count]).to eq(0)
      expect(result[:hypotheses]).to be_empty
    end
  end

  describe '#most_confident_hypotheses' do
    it 'returns hypotheses sorted by descending posterior' do
      client.propose_hypothesis(description: 'low',  prior: 0.2)
      client.propose_hypothesis(description: 'high', prior: 0.9)
      result = client.most_confident_hypotheses(limit: 2)
      expect(result[:hypotheses].first[:posterior]).to be >= result[:hypotheses].last[:posterior]
    end

    it 'respects the limit' do
      5.times { |i| client.propose_hypothesis(description: "h#{i}") }
      result = client.most_confident_hypotheses(limit: 3)
      expect(result[:count]).to be <= 3
    end
  end

  describe '#hypothesis_report' do
    it 'includes total, by_status, confirmation_rate, most_confident' do
      client.propose_hypothesis(description: 'reported')
      result = client.hypothesis_report
      expect(result.keys).to include(:total, :by_status, :confirmation_rate, :most_confident)
    end

    it 'counts total correctly' do
      3.times { |i| client.propose_hypothesis(description: "h#{i}") }
      expect(client.hypothesis_report[:total]).to eq(3)
    end
  end

  describe '#get_hypothesis' do
    it 'returns found: false for unknown id' do
      result = client.get_hypothesis(hypothesis_id: 'nope')
      expect(result[:found]).to be false
    end

    it 'returns found: true and hypothesis hash for known id' do
      h      = client.propose_hypothesis(description: 'gettable')
      result = client.get_hypothesis(hypothesis_id: h[:hypothesis_id])
      expect(result[:found]).to be true
      expect(result[:hypothesis][:id]).to eq(h[:hypothesis_id])
    end
  end
end
