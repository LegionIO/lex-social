# lex-social

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-social`
- **Version**: `0.1.1`
- **Namespace**: `Legion::Extensions::Social`

## Purpose

Models the agent's social standing within groups. Tracks group membership, roles, multi-dimensional reputation, reciprocity balance, and norm violations. Reputation is computed as a weighted composite across five dimensions: reliability, competence, benevolence, integrity, and influence. Each dimension is updated via EMA on observed interactions. Designed to feed into the `lex-tick` cycle from trust and mesh signals.

## Gem Info

- **Gem name**: `lex-social`
- **License**: MIT
- **Ruby**: >= 3.4
- **No runtime dependencies** beyond the Legion framework

## File Structure

```
lib/legion/extensions/social/
  version.rb                   # VERSION = '0.1.0'
  helpers/
    constants.rb               # roles, relationship types, reputation dimensions/weights, standing levels, etc.
    social_graph.rb            # SocialGraph class — membership, reputation, reciprocity, cohesion
  runners/
    social.rb                  # Runners::Social module — all public runner methods
  client.rb                    # Client class including Runners::Social
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `ROLES` | 6 symbols | `:member`, `:leader`, `:peer`, `:mentor`, `:observer`, `:contributor` |
| `RELATIONSHIP_TYPES` | 5 symbols | `:cooperative`, `:competitive`, `:neutral`, `:adversarial`, `:supportive` |
| `REPUTATION_DIMENSIONS` | hash | 5 dimensions with weights: `reliability: 0.25, competence: 0.25, benevolence: 0.20, integrity: 0.20, influence: 0.10` |
| `REPUTATION_ALPHA` | 0.1 | EMA alpha for reputation dimension updates |
| `STANDING_LEVELS` | array | `:outsider`, `:peripheral`, `:associate`, `:member`, `:trusted`, `:core` |
| `COHESION_LEVELS` | array | `:fragmented`, `:low`, `:moderate`, `:high`, `:tight_knit` |
| `MAX_GROUPS` | 20 | Maximum groups tracked |
| `MAX_GROUP_MEMBERS` | 50 | Maximum members per group |
| `NORM_VIOLATIONS` | 5 symbols | Types of norm violations that reduce cohesion |
| `RECIPROCITY_WINDOW` | 50 | Maximum reciprocity exchange records kept |
| `INFLUENCE_DECAY` | 0.02 | Per-tick influence dimension decay |

## Helpers

### `Helpers::SocialGraph`

Social membership and reputation store for the agent.

- `initialize` — groups hash, reputation hash (keyed by `agent_id:group_id`), reciprocity array, violation history
- `join_group(group_id:, role: :member)` — adds agent to group; returns nil if at MAX_GROUPS; returns `:already_member` if already joined
- `leave_group(group_id)` — removes membership record
- `update_role(group_id:, role:)` — changes role for existing membership
- `update_reputation(agent_id:, group_id:, dimension:, value:)` — EMA update on the named dimension for agent within group; creates reputation record if absent
- `reputation_for(agent_id:, group_id:)` — weighted composite across all 5 dimensions: `sum(dim_value * weight)`
- `social_standing(group_id)` — maps composite reputation to STANDING_LEVELS
- `record_reciprocity(with_agent:, exchange_type:, value:)` — appends exchange record; trims to RECIPROCITY_WINDOW
- `reciprocity_balance` — sum of recent exchange values (positive = net giver, negative = net receiver)
- `record_violation(group_id:, violation_type:)` — appends violation; reduces group cohesion by 0.1
- `group_cohesion(group_id)` — returns current cohesion float for group
- `update_cohesion(group_id:, delta:)` — adjusts cohesion by delta; clamps 0.0–1.0
- `classify_cohesion(group_id)` — maps cohesion float to COHESION_LEVELS
- `trim_groups` — removes groups when at MAX_GROUPS (evicts lowest-cohesion group)

## Runners

All runners are in `Runners::Social`. The `Client` includes this module and owns a `SocialGraph` instance.

| Runner | Parameters | Returns |
|---|---|---|
| `update_social` | `tick_results: {}` | Summary hash; extracts trust and mesh signals from tick_results, updates reputation accordingly, decays influence dimension |
| `join_group` | `group_id:, role: :member` | `{ success:, group_id:, role: }` |
| `leave_group` | `group_id:` | `{ success:, group_id: }` |
| `update_reputation` | `agent_id:, group_id:, dimension:, value:` | `{ success:, agent_id:, group_id:, reputation: }` |
| `agent_reputation` | `agent_id:, group_id:` | `{ success:, agent_id:, group_id:, reputation:, standing: }` |
| `reciprocity_status` | (none) | `{ success:, balance:, exchange_count: }` |
| `record_exchange` | `with_agent:, exchange_type:, value:` | `{ success:, balance: }` |
| `report_violation` | `group_id:, violation_type:` | `{ success:, group_id:, cohesion: }` |
| `group_status` | `group_id:` | `{ success:, group_id:, cohesion:, cohesion_label:, standing: }` |
| `social_status` | (none) | All group memberships with standing and cohesion |
| `social_stats` | (none) | Summary: group count, total agents tracked, overall reputation composite |

### Tick Integration

`update_social` reads `tick_results` and:
- Extracts trust scores from `tick_results.dig(:trust_update)` to update `reliability` and `integrity` dimensions
- Extracts mesh messages from `tick_results.dig(:mesh_interface)` to update `influence` dimension
- Applies `INFLUENCE_DECAY` to all influence dimension scores

## Integration Points

- **lex-tick / lex-cortex**: `update_social` wired as a tick phase handler to consume trust and mesh signals automatically
- **lex-trust**: trust scores per agent-domain pair feed into reputation dimension updates for `reliability` and `integrity`
- **lex-mesh**: mesh message patterns (frequency, acknowledgment rates) can drive `influence` dimension updates
- **lex-identity**: the agent's behavioral fingerprint shapes how other agents observe and rate reputation dimensions
- **lex-consent**: social standing in a group can inform consent tier defaults — core standing could unlock higher autonomy

## Development Notes

- Reputation is keyed by `"#{agent_id}:#{group_id}"` — agent can have different reputations in different groups
- Weighted composite uses `REPUTATION_DIMENSIONS` weights that sum to 1.0
- `REPUTATION_ALPHA = 0.1` — slow EMA means reputation changes gradually and resists sudden swings
- Cohesion is stored per group; violations reduce it by a fixed 0.1; `update_cohesion` allows positive adjustments (cooperative exchanges)
- Influence decay (`INFLUENCE_DECAY = 0.02`) per tick keeps the influence dimension from compounding without ongoing activity
- `join_group` validates role against `ROLES` and members count against `MAX_GROUP_MEMBERS` (50)
- `record_reciprocity` validates direction against `RECIPROCITY_DIRECTIONS` (`[:given, :received]`)
