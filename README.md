# lex-hypothesis-testing

Bayesian hypothesis management for LegionIO agents. Part of the LegionIO cognitive architecture extension ecosystem (LEX).

## What It Does

`lex-hypothesis-testing` gives an agent a formal system for proposing beliefs about the world and updating them with evidence. Hypotheses start at a default prior (0.5), accumulate supporting or disconfirming evidence via Bayesian-style posterior updates, and are automatically confirmed or disconfirmed when their posterior crosses a threshold. Competing hypotheses in the same domain can be surfaced to detect belief conflicts.

Key capabilities:

- **Bayesian posterior updates**: evidence steps raise or lower the posterior by `evidence_strength * 0.1`
- **Auto-confirmation**: posterior >= 0.8 confirms; posterior <= 0.2 disconfirms
- **Competing hypothesis detection**: find active hypotheses in the same domain
- **Confidence labels**: very_low / low / moderate / high / very_high per posterior range
- **Confirmation rate**: metacognitive signal tracking prediction reliability over time

## Installation

Add to your Gemfile:

```ruby
gem 'lex-hypothesis-testing'
```

Or install directly:

```
gem install lex-hypothesis-testing
```

## Usage

```ruby
require 'legion/extensions/hypothesis_testing'

client = Legion::Extensions::HypothesisTesting::Client.new

# Propose a hypothesis
result = client.propose_hypothesis(
  content: 'The API latency spike is caused by connection pool exhaustion',
  domain: :performance
)
hypothesis_id = result[:hypothesis][:id]

# Add evidence
client.test_hypothesis(id: hypothesis_id, evidence_strength: 0.9, supporting: true)
# After enough supporting evidence, automatically confirmed

# Compete hypotheses in the same domain
client.competing_hypotheses(domain: :performance)

# Top hypotheses by confidence
client.most_confident_hypotheses(limit: 5)

# Summary
client.hypothesis_report
```

## Runner Methods

| Method | Description |
|---|---|
| `propose_hypothesis` | Propose a new hypothesis with optional custom prior |
| `test_hypothesis` | Apply a piece of evidence and auto-evaluate thresholds |
| `evaluate_hypothesis` | Re-check confirmation thresholds without adding evidence |
| `competing_hypotheses` | Active hypotheses competing in the same domain |
| `most_confident_hypotheses` | Top N by posterior probability |
| `hypothesis_report` | Status counts, confirmation rate, average posterior |
| `get_hypothesis` | Retrieve a specific hypothesis by ID |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
