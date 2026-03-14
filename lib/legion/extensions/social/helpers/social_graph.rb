# frozen_string_literal: true

module Legion
  module Extensions
    module Social
      module Helpers
        class SocialGraph
          attr_reader :groups, :reputation_scores, :reciprocity_ledger

          def initialize
            @groups = {}
            @reputation_scores = {}
            @reciprocity_ledger = []
          end

          def join_group(group_id:, role: :contributor, members: [])
            @groups[group_id] ||= {
              role:       role,
              members:    members.dup,
              joined_at:  Time.now.utc,
              norms:      [],
              cohesion:   0.5,
              violations: []
            }
            trim_groups
            @groups[group_id]
          end

          def leave_group(group_id)
            @groups.delete(group_id)
          end

          def update_role(group_id:, role:)
            return nil unless @groups.key?(group_id)
            return nil unless Constants::ROLES.include?(role)

            @groups[group_id][:role] = role
          end

          def update_reputation(agent_id:, dimension:, signal:)
            return nil unless Constants::REPUTATION_DIMENSIONS.key?(dimension)

            @reputation_scores[agent_id] ||= Constants::REPUTATION_DIMENSIONS.keys.to_h { |d| [d, 0.5] }
            current = @reputation_scores[agent_id][dimension]
            @reputation_scores[agent_id][dimension] = ema(current, signal.clamp(0.0, 1.0), Constants::REPUTATION_ALPHA)
          end

          def reputation_for(agent_id)
            scores = @reputation_scores[agent_id]
            return nil unless scores

            composite = 0.0
            Constants::REPUTATION_DIMENSIONS.each do |dim, config|
              composite += scores[dim] * config[:weight]
            end

            {
              agent_id:  agent_id,
              scores:    scores.transform_values { |v| v.round(4) },
              composite: composite.round(4),
              standing:  classify_standing(composite)
            }
          end

          def social_standing
            return :neutral if @reputation_scores.empty?

            all_composites = @reputation_scores.map { |id, _| reputation_for(id)[:composite] }
            avg = all_composites.sum / all_composites.size.to_f
            classify_standing(avg)
          end

          def record_reciprocity(agent_id:, action:, direction:)
            @reciprocity_ledger << {
              agent_id:  agent_id,
              action:    action,
              direction: direction,
              at:        Time.now.utc
            }
            @reciprocity_ledger.shift while @reciprocity_ledger.size > Constants::RECIPROCITY_WINDOW
          end

          def reciprocity_balance(agent_id)
            entries = @reciprocity_ledger.select { |e| e[:agent_id] == agent_id }
            given = entries.count { |e| e[:direction] == :given }
            received = entries.count { |e| e[:direction] == :received }

            { given: given, received: received, balance: given - received }
          end

          def record_violation(group_id:, type:, agent_id:)
            return nil unless @groups.key?(group_id)
            return nil unless Constants::NORM_VIOLATIONS.include?(type)

            violation = { type: type, agent_id: agent_id, at: Time.now.utc }
            @groups[group_id][:violations] << violation
            reduce_cohesion(group_id, 0.1)
            violation
          end

          def group_cohesion(group_id)
            return nil unless @groups.key?(group_id)

            @groups[group_id][:cohesion]
          end

          def update_cohesion(group_id:, signal:)
            return nil unless @groups.key?(group_id)

            current = @groups[group_id][:cohesion]
            @groups[group_id][:cohesion] = ema(current, signal.clamp(0.0, 1.0), Constants::REPUTATION_ALPHA)
          end

          def classify_cohesion(group_id)
            cohesion = group_cohesion(group_id)
            return nil unless cohesion

            Constants::COHESION_LEVELS.each do |level, threshold|
              return level if cohesion >= threshold
            end
            :fractured
          end

          def group_count
            @groups.size
          end

          def agents_tracked
            @reputation_scores.keys.size
          end

          def to_h
            {
              groups:          @groups.keys,
              group_count:     @groups.size,
              agents_tracked:  agents_tracked,
              social_standing: social_standing,
              ledger_size:     @reciprocity_ledger.size
            }
          end

          private

          def ema(current, observed, alpha)
            (current * (1.0 - alpha)) + (observed * alpha)
          end

          def classify_standing(composite)
            Constants::STANDING_LEVELS.each do |level, threshold|
              return level if composite >= threshold
            end
            :ostracized
          end

          def reduce_cohesion(group_id, amount)
            current = @groups[group_id][:cohesion]
            @groups[group_id][:cohesion] = [current - amount, 0.0].max
          end

          def trim_groups
            oldest = @groups.keys.sort_by { |k| @groups[k][:joined_at] }
            oldest.first([@groups.size - Constants::MAX_GROUPS, 0].max).each { |k| @groups.delete(k) }
          end
        end
      end
    end
  end
end
