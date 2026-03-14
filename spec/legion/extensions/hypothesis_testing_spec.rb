# frozen_string_literal: true

require 'legion/extensions/hypothesis_testing/client'

RSpec.describe Legion::Extensions::HypothesisTesting::Client do
  it 'responds to all runner methods' do
    client = described_class.new
    expect(client).to respond_to(:propose_hypothesis)
    expect(client).to respond_to(:test_hypothesis)
    expect(client).to respond_to(:evaluate_hypothesis)
    expect(client).to respond_to(:competing_hypotheses)
    expect(client).to respond_to(:most_confident_hypotheses)
    expect(client).to respond_to(:hypothesis_report)
    expect(client).to respond_to(:get_hypothesis)
  end
end
