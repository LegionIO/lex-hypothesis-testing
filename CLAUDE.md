# lex-hypothesis-testing

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-hypothesis-testing`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::HypothesisTesting`

## Purpose

Bayesian hypothesis management for LegionIO agents. Allows the agent to propose hypotheses about the world, accumulate evidence for or against each one via posterior updates, automatically confirm or disconfirm at threshold, and identify competing hypotheses in the same domain. Tracks confirmation rate as a metacognitive reliability signal.

## Gem Info

- **Require path**: `legion/extensions/hypothesis_testing`
- **Ruby**: >= 3.4
- **License**: MIT
- **Registers with**: `Legion::Extensions::Core`

## File Structure

```
lib/legion/extensions/hypothesis_testing/
  version.rb
  helpers/
    constants.rb            # Limits, thresholds, labels
    hypothesis.rb           # Hypothesis value object with Bayesian update
    hypothesis_engine.rb    # In-memory store and evaluation logic
  runners/
    hypothesis_testing.rb   # Runner module

spec/
  legion/extensions/hypothesis_testing/
    helpers/
      constants_spec.rb
      hypothesis_spec.rb
      hypothesis_engine_spec.rb
    runners/hypothesis_testing_spec.rb
  spec_helper.rb
```

## Key Constants

```ruby
MAX_HYPOTHESES             = 300
CONFIRMATION_THRESHOLD     = 0.8   # posterior >= this -> auto-confirm
DISCONFIRMATION_THRESHOLD  = 0.2   # posterior <= this -> auto-disconfirm
EVIDENCE_WEIGHT            = 0.1   # step size for Bayesian posterior update
PRIOR_DEFAULT              = 0.5   # starting posterior for new hypotheses
```

## Helpers

### `Helpers::Hypothesis` (class)

Value object representing one testable hypothesis.

| Attribute | Type | Description |
|---|---|---|
| `id` | String (UUID) | unique identifier |
| `content` | String | the hypothesis statement |
| `domain` | Symbol | subject area |
| `posterior` | Float (0..1) | current Bayesian posterior |
| `status` | Symbol | :active / :confirmed / :disconfirmed |
| `evidence_count` | Integer | total evidence events |

Key methods:

| Method | Description |
|---|---|
| `update_posterior!(evidence_strength, supporting)` | Bayesian-style step: supporting raises posterior by `evidence_strength * EVIDENCE_WEIGHT`; disconfirming lowers it; clamped 0..1 |
| `confirm!` | transitions status to :confirmed |
| `disconfirm!` | transitions status to :disconfirmed |
| `confidence_label` | :very_low / :low / :moderate / :high / :very_high based on posterior |

### `Helpers::HypothesisEngine` (class)

In-memory store and orchestration for hypothesis lifecycle.

| Method | Description |
|---|---|
| `propose(content:, domain:, prior:)` | creates and stores new hypothesis; enforces MAX_HYPOTHESES |
| `test_hypothesis(id:, evidence_strength:, supporting:)` | applies posterior update, then calls evaluate |
| `evaluate(id:)` | auto-confirms at CONFIRMATION_THRESHOLD, auto-disconfirms at DISCONFIRMATION_THRESHOLD |
| `competing_hypotheses(domain:)` | active hypotheses in the same domain, sorted by posterior desc |
| `most_confident(limit:)` | top N active hypotheses by posterior |
| `confirmation_rate` | ratio of confirmed to total terminal hypotheses |

## Runners

Module: `Legion::Extensions::HypothesisTesting::Runners::HypothesisTesting`

Private state: `@engine` (memoized `HypothesisEngine` instance).

| Runner Method | Parameters | Description |
|---|---|---|
| `propose_hypothesis` | `content:, domain:, prior: PRIOR_DEFAULT` | Propose a new hypothesis |
| `test_hypothesis` | `id:, evidence_strength:, supporting:` | Apply evidence and evaluate |
| `evaluate_hypothesis` | `id:` | Re-evaluate thresholds without adding evidence |
| `competing_hypotheses` | `domain:` | Active hypotheses competing in the same domain |
| `most_confident_hypotheses` | `limit: 5` | Top N by posterior |
| `hypothesis_report` | (none) | Status counts, confirmation rate, avg posterior |
| `get_hypothesis` | `id:` | Retrieve a specific hypothesis by ID |

## Integration Points

- **lex-prediction**: predictions are forward-model hypotheses; hypothesis-testing provides a formal evidence accumulation layer on top of prediction confidence.
- **lex-curiosity**: wonders can trigger hypothesis formation; confirmed hypotheses reduce wonder strength for that domain.
- **lex-metacognition**: `HypothesisTesting` is listed under `:cognition` capability category.
- **lex-conditioner / lex-transformer**: hypothesis IDs can be embedded in task payloads to condition task chains on confirmation status.

## Development Notes

- Posterior update formula: `new_posterior = posterior ± (evidence_strength * EVIDENCE_WEIGHT)`, clamped to 0..1. This is a simplified Bayesian-like step, not a full likelihood-ratio update.
- `evaluate` is called automatically inside `test_hypothesis`. Calling `evaluate_hypothesis` standalone re-checks thresholds without adding new evidence (useful after manual posterior manipulation).
- MAX_HYPOTHESES enforcement: when limit is reached, oldest disconfirmed hypotheses are pruned first; then oldest confirmed; if still over limit, propose returns an error.
- Competing hypotheses only returns `:active` status — confirmed/disconfirmed hypotheses are not returned as competitors.
- No decay mechanism — hypotheses persist until explicitly disconfirmed or pruned by the MAX_HYPOTHESES limit.
- No actor defined; evaluation is driven by explicit `test_hypothesis` calls.
