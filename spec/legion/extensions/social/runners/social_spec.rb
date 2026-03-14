# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Social::Runners::Social do
  let(:graph) { Legion::Extensions::Social::Helpers::SocialGraph.new }

  let(:host) do
    Object.new.tap do |obj|
      obj.extend(described_class)
      obj.instance_variable_set(:@social_graph, graph)
    end
  end

  describe '#join_group' do
    it 'returns success' do
      result = host.join_group(group_id: :alpha, role: :contributor)
      expect(result[:success]).to be true
    end

    it 'returns the group_id and role' do
      result = host.join_group(group_id: :alpha, role: :leader, members: %w[a1])
      expect(result[:group_id]).to eq(:alpha)
      expect(result[:role]).to eq(:leader)
    end

    it 'includes the group hash' do
      result = host.join_group(group_id: :alpha)
      expect(result[:group]).to be_a(Hash)
    end
  end

  describe '#leave_group' do
    before { host.join_group(group_id: :alpha) }

    it 'returns success' do
      result = host.leave_group(group_id: :alpha)
      expect(result[:success]).to be true
    end

    it 'removes the group from the graph' do
      host.leave_group(group_id: :alpha)
      expect(graph.groups).not_to have_key(:alpha)
    end
  end

  describe '#update_reputation' do
    it 'returns success for valid dimension' do
      result = host.update_reputation(agent_id: :a1, dimension: :reliability, signal: 0.8)
      expect(result[:success]).to be true
    end

    it 'returns reputation hash' do
      result = host.update_reputation(agent_id: :a1, dimension: :competence, signal: 0.9)
      expect(result[:reputation]).to have_key(:composite)
    end

    it 'returns failure for invalid dimension' do
      result = host.update_reputation(agent_id: :a1, dimension: :fake, signal: 0.5)
      expect(result[:success]).to be false
    end
  end

  describe '#agent_reputation' do
    it 'returns reputation for known agent' do
      host.update_reputation(agent_id: :a1, dimension: :reliability, signal: 0.8)
      result = host.agent_reputation(agent_id: :a1)
      expect(result[:composite]).to be_a(Float)
    end

    it 'returns error for unknown agent' do
      result = host.agent_reputation(agent_id: :unknown)
      expect(result[:error]).to eq('unknown agent')
    end
  end

  describe '#reciprocity_status' do
    it 'returns balance for agent' do
      result = host.reciprocity_status(agent_id: :a1)
      expect(result[:given]).to eq(0)
      expect(result[:received]).to eq(0)
      expect(result[:balance]).to eq(0)
    end
  end

  describe '#record_exchange' do
    it 'returns success' do
      result = host.record_exchange(agent_id: :a1, action: :helped, direction: :given)
      expect(result[:success]).to be true
    end

    it 'updates the reciprocity ledger' do
      host.record_exchange(agent_id: :a1, action: :helped, direction: :given)
      expect(graph.reciprocity_ledger.size).to eq(1)
    end

    it 'converts direction to symbol' do
      host.record_exchange(agent_id: :a1, action: :helped, direction: 'received')
      expect(graph.reciprocity_ledger.first[:direction]).to eq(:received)
    end
  end

  describe '#report_violation' do
    before { host.join_group(group_id: :alpha) }

    it 'returns success for valid violation' do
      result = host.report_violation(group_id: :alpha, type: :free_riding, agent_id: :a1)
      expect(result[:success]).to be true
    end

    it 'returns the violation and cohesion' do
      result = host.report_violation(group_id: :alpha, type: :defection, agent_id: :a1)
      expect(result[:violation]).to be_a(Hash)
      expect(result[:cohesion]).to be_a(Float)
    end

    it 'returns failure for invalid group' do
      result = host.report_violation(group_id: :unknown, type: :free_riding, agent_id: :a1)
      expect(result[:success]).to be false
    end

    it 'converts type to symbol' do
      result = host.report_violation(group_id: :alpha, type: 'deception', agent_id: :a1)
      expect(result[:success]).to be true
    end
  end

  describe '#group_status' do
    before { host.join_group(group_id: :alpha, role: :leader, members: %w[a1 a2]) }

    it 'returns group details' do
      result = host.group_status(group_id: :alpha)
      expect(result[:group_id]).to eq(:alpha)
      expect(result[:role]).to eq(:leader)
      expect(result[:members]).to eq(2)
      expect(result[:cohesion]).to be_a(Float)
      expect(result[:cohesion_level]).to be_a(Symbol)
      expect(result[:violations]).to eq(0)
    end

    it 'returns error for unknown group' do
      result = host.group_status(group_id: :unknown)
      expect(result[:error]).to eq('unknown group')
    end
  end

  describe '#social_status' do
    it 'returns a state hash' do
      result = host.social_status
      expect(result).to have_key(:groups)
      expect(result).to have_key(:group_count)
      expect(result).to have_key(:social_standing)
    end
  end

  describe '#social_stats' do
    before do
      host.join_group(group_id: :alpha, role: :leader)
      host.join_group(group_id: :beta, role: :contributor)
    end

    it 'returns group count' do
      expect(host.social_stats[:groups]).to eq(2)
    end

    it 'returns group roles' do
      roles = host.social_stats[:group_roles]
      expect(roles[:alpha]).to eq(:leader)
      expect(roles[:beta]).to eq(:contributor)
    end

    it 'returns ledger size' do
      expect(host.social_stats[:ledger_size]).to eq(0)
    end
  end

  describe '#update_social' do
    before { host.join_group(group_id: :alpha) }

    it 'returns social summary hash' do
      result = host.update_social(tick_results: {})
      expect(result).to have_key(:groups)
      expect(result).to have_key(:agents_tracked)
      expect(result).to have_key(:standing)
      expect(result).to have_key(:ledger_size)
    end

    it 'extracts trust signals from tick results' do
      tick = {
        trust: {
          updates: [
            { agent_id: :a1, score: 0.9 },
            { agent_id: :a2, score: 0.7 }
          ]
        }
      }
      host.update_social(tick_results: tick)
      expect(graph.agents_tracked).to eq(2)
    end

    it 'handles missing trust data gracefully' do
      result = host.update_social(tick_results: { trust: {} })
      expect(result[:agents_tracked]).to eq(0)
    end

    it 'extracts mesh signals and updates cohesion' do
      initial_cohesion = graph.group_cohesion(:alpha)
      tick = { mesh_interface: { peer_count: 8 } }
      host.update_social(tick_results: tick)
      expect(graph.group_cohesion(:alpha)).to be > initial_cohesion
    end

    it 'skips mesh update when peer_count is zero' do
      initial_cohesion = graph.group_cohesion(:alpha)
      tick = { mesh_interface: { peer_count: 0 } }
      host.update_social(tick_results: tick)
      expect(graph.group_cohesion(:alpha)).to eq(initial_cohesion)
    end
  end
end
