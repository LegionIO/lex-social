# lex-social

Social standing and group dynamics modeling for LegionIO cognitive agents. Tracks group membership, multi-dimensional reputation, reciprocity balance, and norm violations.

## What It Does

`lex-social` gives cognitive agents a model of their place within social groups. Reputation is computed as a weighted composite across five dimensions (reliability, competence, benevolence, integrity, influence) using exponential moving averages. Group cohesion rises or falls with cooperative exchanges and norm violations.

- **Reputation dimensions**: reliability (0.25), competence (0.25), benevolence (0.20), integrity (0.20), influence (0.10)
- **Standing levels**: outsider, peripheral, associate, member, trusted, core
- **Cohesion levels**: fragmented, low, moderate, high, tight-knit
- **Reciprocity tracking**: net balance across the last 50 exchanges
- **Tick integration**: `update_social` reads trust and mesh signals from tick_results automatically

## Usage

```ruby
require 'legion/extensions/social'

client = Legion::Extensions::Social::Client.new

# Join a group
client.join_group(group_id: 'eng_team', role: :member)

# Update another agent's reputation in this group
client.update_reputation(
  agent_id: 'agent_007',
  group_id: 'eng_team',
  dimension: :reliability,
  value: 0.9
)

# Check reputation and standing
client.agent_reputation(agent_id: 'agent_007', group_id: 'eng_team')
# => { reputation: 0.72, standing: :trusted }

# Track reciprocity
client.record_exchange(with_agent: 'agent_007', exchange_type: :help, value: 0.8)
client.reciprocity_status
# => { balance: 0.8, exchange_count: 1 }

# Report a norm violation (reduces cohesion)
client.report_violation(group_id: 'eng_team', violation_type: :broken_promise)
# => { cohesion: 0.9 }

# Group status
client.group_status(group_id: 'eng_team')
# => { cohesion: 0.9, cohesion_label: :tight_knit, standing: :trusted }

# Per-tick update (extracts trust + mesh signals)
client.update_social(tick_results: tick_output)
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
