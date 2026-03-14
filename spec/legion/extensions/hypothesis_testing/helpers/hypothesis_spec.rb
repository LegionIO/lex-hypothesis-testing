# frozen_string_literal: true

require 'legion/extensions/hypothesis_testing/helpers/constants'
require 'legion/extensions/hypothesis_testing/helpers/hypothesis'

RSpec.describe Legion::Extensions::HypothesisTesting::Helpers::Hypothesis do
  subject(:hypothesis) { described_class.new(description: 'test hypothesis', domain: 'logic') }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(hypothesis.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets description' do
      expect(hypothesis.description).to eq('test hypothesis')
    end

    it 'sets domain' do
      expect(hypothesis.domain).to eq('logic')
    end

    it 'defaults prior to PRIOR_DEFAULT' do
      h = described_class.new(description: 'default prior')
      expect(h.prior).to eq(Legion::Extensions::HypothesisTesting::Helpers::Constants::PRIOR_DEFAULT)
    end

    it 'sets posterior to prior at creation' do
      h = described_class.new(description: 'check posterior', prior: 0.3)
      expect(h.posterior).to eq(0.3)
    end

    it 'starts with evidence_count of 0' do
      expect(hypothesis.evidence_count).to eq(0)
    end

    it 'starts with status :proposed' do
      expect(hypothesis.status).to eq(:proposed)
    end

    it 'clamps prior above 1.0 to 1.0' do
      h = described_class.new(description: 'high', prior: 1.5)
      expect(h.prior).to eq(1.0)
    end

    it 'clamps prior below 0.0 to 0.0' do
      h = described_class.new(description: 'low', prior: -0.1)
      expect(h.prior).to eq(0.0)
    end
  end

  describe '#update_posterior!' do
    it 'increases posterior with supporting evidence' do
      before = hypothesis.posterior
      hypothesis.update_posterior!(evidence_strength: 1.0, supporting: true)
      expect(hypothesis.posterior).to be > before
    end

    it 'decreases posterior with contradicting evidence' do
      h = described_class.new(description: 'contra', prior: 0.8)
      h.update_posterior!(evidence_strength: 1.0, supporting: false)
      expect(h.posterior).to be < 0.8
    end

    it 'transitions status to :testing' do
      hypothesis.update_posterior!(evidence_strength: 0.5, supporting: true)
      expect(hypothesis.status).to eq(:testing)
    end

    it 'increments evidence_count' do
      hypothesis.update_posterior!(evidence_strength: 0.5, supporting: true)
      expect(hypothesis.evidence_count).to eq(1)
    end

    it 'keeps posterior within [0.0, 1.0]' do
      10.times { hypothesis.update_posterior!(evidence_strength: 1.0, supporting: true) }
      expect(hypothesis.posterior).to be <= 1.0
    end

    it 'does not update a confirmed hypothesis' do
      hypothesis.confirm!
      prior_posterior = hypothesis.posterior
      hypothesis.update_posterior!(evidence_strength: 1.0, supporting: false)
      expect(hypothesis.posterior).to eq(prior_posterior)
    end

    it 'does not update a disconfirmed hypothesis' do
      hypothesis.disconfirm!
      prior_posterior = hypothesis.posterior
      hypothesis.update_posterior!(evidence_strength: 1.0, supporting: true)
      expect(hypothesis.posterior).to eq(prior_posterior)
    end

    it 'clamps evidence_strength above 1.0' do
      hypothesis.update_posterior!(evidence_strength: 5.0, supporting: true)
      expect(hypothesis.posterior).to be <= 1.0
    end

    it 'rounds posterior to 10 decimal places' do
      hypothesis.update_posterior!(evidence_strength: 0.7, supporting: true)
      expect(hypothesis.posterior.to_s.split('.').last.length).to be <= 10
    end
  end

  describe '#confirm!' do
    it 'sets status to :confirmed' do
      hypothesis.confirm!
      expect(hypothesis.status).to eq(:confirmed)
    end

    it 'raises posterior to at least CONFIRMATION_THRESHOLD' do
      h = described_class.new(description: 'near confirm', prior: 0.75)
      h.confirm!
      expect(h.posterior).to be >= Legion::Extensions::HypothesisTesting::Helpers::Constants::CONFIRMATION_THRESHOLD
    end
  end

  describe '#disconfirm!' do
    it 'sets status to :disconfirmed' do
      hypothesis.disconfirm!
      expect(hypothesis.status).to eq(:disconfirmed)
    end

    it 'lowers posterior to at most DISCONFIRMATION_THRESHOLD' do
      h = described_class.new(description: 'near disconfirm', prior: 0.25)
      h.disconfirm!
      expect(h.posterior).to be <= Legion::Extensions::HypothesisTesting::Helpers::Constants::DISCONFIRMATION_THRESHOLD
    end
  end

  describe '#confidence_label' do
    it 'returns certain for posterior >= 0.9' do
      h = described_class.new(description: 'certain', prior: 0.95)
      expect(h.confidence_label).to eq('certain')
    end

    it 'returns confident for posterior in [0.7, 0.9)' do
      h = described_class.new(description: 'confident', prior: 0.8)
      expect(h.confidence_label).to eq('confident')
    end

    it 'returns leaning for posterior in [0.5, 0.7)' do
      h = described_class.new(description: 'leaning', prior: 0.6)
      expect(h.confidence_label).to eq('leaning')
    end

    it 'returns uncertain for posterior in [0.3, 0.5)' do
      h = described_class.new(description: 'uncertain', prior: 0.4)
      expect(h.confidence_label).to eq('uncertain')
    end

    it 'returns agnostic for posterior in [0.0, 0.3)' do
      h = described_class.new(description: 'agnostic', prior: 0.1)
      expect(h.confidence_label).to eq('agnostic')
    end
  end

  describe '#to_h' do
    it 'returns a hash with all required keys' do
      result = hypothesis.to_h
      expect(result.keys).to include(:id, :description, :domain, :prior, :posterior,
                                     :evidence_count, :status, :confidence_label, :created_at)
    end

    it 'returns correct id' do
      expect(hypothesis.to_h[:id]).to eq(hypothesis.id)
    end

    it 'returns correct status' do
      expect(hypothesis.to_h[:status]).to eq(:proposed)
    end
  end
end
