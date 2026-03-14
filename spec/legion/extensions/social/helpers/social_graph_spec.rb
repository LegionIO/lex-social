# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Social::Helpers::SocialGraph do
  subject(:graph) { described_class.new }

  describe '#initialize' do
    it 'starts with empty groups' do
      expect(graph.groups).to be_empty
    end

    it 'starts with empty reputation scores' do
      expect(graph.reputation_scores).to be_empty
    end

    it 'starts with empty reciprocity ledger' do
      expect(graph.reciprocity_ledger).to be_empty
    end
  end

  describe '#join_group' do
    it 'creates a new group entry' do
      graph.join_group(group_id: :alpha)
      expect(graph.groups).to have_key(:alpha)
    end

    it 'returns the group hash' do
      result = graph.join_group(group_id: :alpha, role: :leader)
      expect(result[:role]).to eq(:leader)
    end

    it 'defaults role to contributor' do
      graph.join_group(group_id: :alpha)
      expect(graph.groups[:alpha][:role]).to eq(:contributor)
    end

    it 'stores members' do
      graph.join_group(group_id: :alpha, members: %w[a1 a2])
      expect(graph.groups[:alpha][:members]).to eq(%w[a1 a2])
    end

    it 'initializes cohesion at 0.5' do
      graph.join_group(group_id: :alpha)
      expect(graph.groups[:alpha][:cohesion]).to eq(0.5)
    end

    it 'initializes empty violations' do
      graph.join_group(group_id: :alpha)
      expect(graph.groups[:alpha][:violations]).to be_empty
    end

    it 'does not overwrite existing group' do
      graph.join_group(group_id: :alpha, role: :leader)
      graph.join_group(group_id: :alpha, role: :observer)
      expect(graph.groups[:alpha][:role]).to eq(:leader)
    end

    it 'trims groups beyond MAX_GROUPS' do
      max = Legion::Extensions::Social::Helpers::Constants::MAX_GROUPS
      (max + 3).times { |i| graph.join_group(group_id: :"group_#{i}") }
      expect(graph.group_count).to eq(max)
    end
  end

  describe '#leave_group' do
    before { graph.join_group(group_id: :alpha) }

    it 'removes the group' do
      graph.leave_group(:alpha)
      expect(graph.groups).not_to have_key(:alpha)
    end

    it 'returns nil for unknown group' do
      expect(graph.leave_group(:unknown)).to be_nil
    end
  end

  describe '#update_role' do
    before { graph.join_group(group_id: :alpha, role: :contributor) }

    it 'updates the role' do
      graph.update_role(group_id: :alpha, role: :leader)
      expect(graph.groups[:alpha][:role]).to eq(:leader)
    end

    it 'returns nil for unknown group' do
      expect(graph.update_role(group_id: :unknown, role: :leader)).to be_nil
    end

    it 'returns nil for invalid role' do
      expect(graph.update_role(group_id: :alpha, role: :invalid)).to be_nil
    end
  end

  describe '#update_reputation' do
    it 'initializes reputation scores for new agent' do
      graph.update_reputation(agent_id: :a1, dimension: :reliability, signal: 0.8)
      expect(graph.reputation_scores[:a1]).to be_a(Hash)
    end

    it 'updates the specified dimension via EMA' do
      graph.update_reputation(agent_id: :a1, dimension: :reliability, signal: 1.0)
      score = graph.reputation_scores[:a1][:reliability]
      expect(score).to be > 0.5
      expect(score).to be < 1.0
    end

    it 'clamps signal to 0..1' do
      graph.update_reputation(agent_id: :a1, dimension: :reliability, signal: 5.0)
      score = graph.reputation_scores[:a1][:reliability]
      expect(score).to be <= 1.0
    end

    it 'returns nil for invalid dimension' do
      result = graph.update_reputation(agent_id: :a1, dimension: :fake, signal: 0.5)
      expect(result).to be_nil
    end

    it 'converges toward signal over repeated updates' do
      20.times { graph.update_reputation(agent_id: :a1, dimension: :competence, signal: 0.9) }
      expect(graph.reputation_scores[:a1][:competence]).to be > 0.8
    end
  end

  describe '#reputation_for' do
    before do
      graph.update_reputation(agent_id: :a1, dimension: :reliability, signal: 0.8)
    end

    it 'returns agent_id in the result' do
      expect(graph.reputation_for(:a1)[:agent_id]).to eq(:a1)
    end

    it 'returns a composite score' do
      expect(graph.reputation_for(:a1)[:composite]).to be_a(Float)
    end

    it 'returns a standing classification' do
      expect(graph.reputation_for(:a1)[:standing]).to be_a(Symbol)
    end

    it 'returns rounded scores' do
      rep = graph.reputation_for(:a1)
      rep[:scores].each_value do |v|
        expect(v.to_s.split('.').last.length).to be <= 4
      end
    end

    it 'returns nil for unknown agent' do
      expect(graph.reputation_for(:unknown)).to be_nil
    end
  end

  describe '#social_standing' do
    it 'returns :neutral when no agents tracked' do
      expect(graph.social_standing).to eq(:neutral)
    end

    it 'returns a classification symbol with agents' do
      graph.update_reputation(agent_id: :a1, dimension: :reliability, signal: 0.9)
      expect(graph.social_standing).to be_a(Symbol)
    end
  end

  describe '#record_reciprocity' do
    it 'adds an entry to the ledger' do
      graph.record_reciprocity(agent_id: :a1, action: :helped, direction: :given)
      expect(graph.reciprocity_ledger.size).to eq(1)
    end

    it 'tracks direction' do
      graph.record_reciprocity(agent_id: :a1, action: :helped, direction: :given)
      expect(graph.reciprocity_ledger.first[:direction]).to eq(:given)
    end

    it 'enforces RECIPROCITY_WINDOW' do
      window = Legion::Extensions::Social::Helpers::Constants::RECIPROCITY_WINDOW
      (window + 10).times do |i|
        graph.record_reciprocity(agent_id: :a1, action: :"action_#{i}", direction: :given)
      end
      expect(graph.reciprocity_ledger.size).to eq(window)
    end
  end

  describe '#reciprocity_balance' do
    before do
      3.times { graph.record_reciprocity(agent_id: :a1, action: :help, direction: :given) }
      graph.record_reciprocity(agent_id: :a1, action: :assist, direction: :received)
      2.times { graph.record_reciprocity(agent_id: :a2, action: :teach, direction: :given) }
    end

    it 'counts given correctly' do
      expect(graph.reciprocity_balance(:a1)[:given]).to eq(3)
    end

    it 'counts received correctly' do
      expect(graph.reciprocity_balance(:a1)[:received]).to eq(1)
    end

    it 'computes balance as given - received' do
      expect(graph.reciprocity_balance(:a1)[:balance]).to eq(2)
    end

    it 'isolates by agent' do
      expect(graph.reciprocity_balance(:a2)[:given]).to eq(2)
      expect(graph.reciprocity_balance(:a2)[:received]).to eq(0)
    end
  end

  describe '#record_violation' do
    before { graph.join_group(group_id: :alpha) }

    it 'records the violation' do
      result = graph.record_violation(group_id: :alpha, type: :free_riding, agent_id: :a1)
      expect(result[:type]).to eq(:free_riding)
    end

    it 'reduces cohesion' do
      initial = graph.groups[:alpha][:cohesion]
      graph.record_violation(group_id: :alpha, type: :defection, agent_id: :a1)
      expect(graph.groups[:alpha][:cohesion]).to be < initial
    end

    it 'returns nil for unknown group' do
      result = graph.record_violation(group_id: :unknown, type: :free_riding, agent_id: :a1)
      expect(result).to be_nil
    end

    it 'returns nil for invalid violation type' do
      result = graph.record_violation(group_id: :alpha, type: :invalid, agent_id: :a1)
      expect(result).to be_nil
    end

    it 'cohesion does not go below 0' do
      10.times { graph.record_violation(group_id: :alpha, type: :free_riding, agent_id: :a1) }
      expect(graph.groups[:alpha][:cohesion]).to be >= 0.0
    end
  end

  describe '#group_cohesion' do
    it 'returns nil for unknown group' do
      expect(graph.group_cohesion(:unknown)).to be_nil
    end

    it 'returns the cohesion value' do
      graph.join_group(group_id: :alpha)
      expect(graph.group_cohesion(:alpha)).to eq(0.5)
    end
  end

  describe '#update_cohesion' do
    before { graph.join_group(group_id: :alpha) }

    it 'moves cohesion toward signal via EMA' do
      graph.update_cohesion(group_id: :alpha, signal: 1.0)
      expect(graph.group_cohesion(:alpha)).to be > 0.5
    end

    it 'clamps signal to 0..1' do
      graph.update_cohesion(group_id: :alpha, signal: 5.0)
      expect(graph.group_cohesion(:alpha)).to be <= 1.0
    end

    it 'returns nil for unknown group' do
      expect(graph.update_cohesion(group_id: :unknown, signal: 0.8)).to be_nil
    end
  end

  describe '#classify_cohesion' do
    before { graph.join_group(group_id: :alpha) }

    it 'returns :moderate for default cohesion (0.5)' do
      expect(graph.classify_cohesion(:alpha)).to eq(:moderate)
    end

    it 'returns :tight for high cohesion' do
      5.times { graph.update_cohesion(group_id: :alpha, signal: 1.0) }
      10.times { graph.update_cohesion(group_id: :alpha, signal: 1.0) }
      expect(graph.classify_cohesion(:alpha)).to eq(:tight)
    end

    it 'returns nil for unknown group' do
      expect(graph.classify_cohesion(:unknown)).to be_nil
    end
  end

  describe '#group_count' do
    it 'returns 0 with no groups' do
      expect(graph.group_count).to eq(0)
    end

    it 'returns the number of groups' do
      graph.join_group(group_id: :alpha)
      graph.join_group(group_id: :beta)
      expect(graph.group_count).to eq(2)
    end
  end

  describe '#agents_tracked' do
    it 'returns 0 with no agents' do
      expect(graph.agents_tracked).to eq(0)
    end

    it 'counts unique agents with reputation' do
      graph.update_reputation(agent_id: :a1, dimension: :reliability, signal: 0.5)
      graph.update_reputation(agent_id: :a2, dimension: :competence, signal: 0.7)
      expect(graph.agents_tracked).to eq(2)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      result = graph.to_h
      expect(result).to have_key(:groups)
      expect(result).to have_key(:group_count)
      expect(result).to have_key(:agents_tracked)
      expect(result).to have_key(:social_standing)
      expect(result).to have_key(:ledger_size)
    end
  end
end
