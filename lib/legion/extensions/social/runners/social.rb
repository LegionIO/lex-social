# frozen_string_literal: true

module Legion
  module Extensions
    module Social
      module Runners
        module Social
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def update_social(tick_results: {}, **)
            extract_social_signals(tick_results)

            Legion::Logging.debug "[social] groups=#{social_graph.group_count} " \
                                  "agents=#{social_graph.agents_tracked} standing=#{social_graph.social_standing}"

            {
              groups:         social_graph.group_count,
              agents_tracked: social_graph.agents_tracked,
              standing:       social_graph.social_standing,
              ledger_size:    social_graph.reciprocity_ledger.size
            }
          end

          def join_group(group_id:, role: :contributor, members: [], **)
            group = social_graph.join_group(group_id: group_id, role: role, members: members)
            return { success: false, error: 'invalid role or group full' } if group.nil? || (group.is_a?(Hash) && group[:error])

            Legion::Logging.info "[social] joined group=#{group_id} role=#{role}"
            { success: true, group_id: group_id, role: role, group: group }
          end

          def leave_group(group_id:, **)
            social_graph.leave_group(group_id)
            Legion::Logging.info "[social] left group=#{group_id}"
            { success: true, group_id: group_id }
          end

          def update_reputation(agent_id:, dimension:, signal:, **)
            result = social_graph.update_reputation(agent_id: agent_id, dimension: dimension.to_sym, signal: signal)
            return { success: false, error: 'invalid dimension' } unless result

            rep = social_graph.reputation_for(agent_id)
            Legion::Logging.debug "[social] reputation updated agent=#{agent_id} dim=#{dimension}"
            { success: true, reputation: rep }
          end

          def agent_reputation(agent_id:, **)
            rep = social_graph.reputation_for(agent_id)
            return { error: 'unknown agent' } unless rep

            Legion::Logging.debug "[social] reputation for #{agent_id}: #{rep[:composite]}"
            rep
          end

          def reciprocity_status(agent_id:, **)
            balance = social_graph.reciprocity_balance(agent_id)
            Legion::Logging.debug "[social] reciprocity #{agent_id}: #{balance}"
            balance
          end

          def record_exchange(agent_id:, action:, direction:, **)
            result = social_graph.record_reciprocity(agent_id: agent_id, action: action, direction: direction.to_sym)
            return { success: false, error: 'invalid direction' } unless result

            Legion::Logging.debug "[social] exchange agent=#{agent_id} dir=#{direction}"
            { success: true }
          end

          def report_violation(group_id:, type:, agent_id:, **)
            violation = social_graph.record_violation(group_id: group_id, type: type.to_sym, agent_id: agent_id)
            return { success: false, error: 'invalid group or violation type' } unless violation

            Legion::Logging.warn "[social] violation: #{type} by #{agent_id} in #{group_id}"
            { success: true, violation: violation, cohesion: social_graph.group_cohesion(group_id)&.round(4) }
          end

          def group_status(group_id:, **)
            return { error: 'unknown group' } unless social_graph.groups.key?(group_id)

            group = social_graph.groups[group_id]
            {
              group_id:       group_id,
              role:           group[:role],
              members:        group[:members].size,
              cohesion:       group[:cohesion].round(4),
              cohesion_level: social_graph.classify_cohesion(group_id),
              violations:     group[:violations].size
            }
          end

          def social_status(**)
            state = social_graph.to_h
            Legion::Logging.debug "[social] status: #{state[:social_standing]}"
            state
          end

          def social_stats(**)
            Legion::Logging.debug '[social] stats'

            {
              groups:         social_graph.group_count,
              agents_tracked: social_graph.agents_tracked,
              standing:       social_graph.social_standing,
              ledger_size:    social_graph.reciprocity_ledger.size,
              group_roles:    social_graph.groups.transform_values { |g| g[:role] }
            }
          end

          private

          def social_graph
            @social_graph ||= Helpers::SocialGraph.new
          end

          def extract_social_signals(tick_results)
            extract_trust_signals(tick_results)
            extract_mesh_signals(tick_results)
          end

          def extract_trust_signals(tick_results)
            trust_updates = tick_results.dig(:trust, :updates)
            return unless trust_updates.is_a?(Array)

            trust_updates.each do |update|
              social_graph.update_reputation(
                agent_id:  update[:agent_id],
                dimension: :reliability,
                signal:    update[:score] || 0.5
              )
            end
          end

          def extract_mesh_signals(tick_results)
            peer_count = tick_results.dig(:mesh_interface, :peer_count) || 0
            return if peer_count.zero?

            social_graph.groups.each_key do |group_id|
              social_graph.update_cohesion(group_id: group_id, signal: [peer_count * 0.1, 1.0].min)
            end
          end
        end
      end
    end
  end
end
