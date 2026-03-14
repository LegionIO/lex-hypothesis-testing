# frozen_string_literal: true

require 'legion/extensions/hypothesis_testing/helpers/constants'

RSpec.describe Legion::Extensions::HypothesisTesting::Helpers::Constants do
  it 'defines MAX_HYPOTHESES as 300' do
    expect(described_class::MAX_HYPOTHESES).to eq(300)
  end

  it 'defines CONFIRMATION_THRESHOLD as 0.8' do
    expect(described_class::CONFIRMATION_THRESHOLD).to eq(0.8)
  end

  it 'defines DISCONFIRMATION_THRESHOLD as 0.2' do
    expect(described_class::DISCONFIRMATION_THRESHOLD).to eq(0.2)
  end

  it 'defines EVIDENCE_WEIGHT as 0.1' do
    expect(described_class::EVIDENCE_WEIGHT).to eq(0.1)
  end

  it 'defines PRIOR_DEFAULT as 0.5' do
    expect(described_class::PRIOR_DEFAULT).to eq(0.5)
  end

  it 'defines all five STATUS_LABELS keys' do
    expect(described_class::STATUS_LABELS.keys).to match_array(%i[proposed testing confirmed disconfirmed inconclusive])
  end

  it 'defines five CONFIDENCE_LABELS entries' do
    expect(described_class::CONFIDENCE_LABELS.size).to eq(5)
  end

  it 'includes certain, confident, leaning, uncertain, agnostic labels' do
    labels = described_class::CONFIDENCE_LABELS.map { |_, label| label }
    expect(labels).to match_array(%w[certain confident leaning uncertain agnostic])
  end
end
