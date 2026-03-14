# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Social::Client do
  describe '#initialize' do
    it 'creates a default social graph' do
      client = described_class.new
      expect(client.social_graph).to be_a(Legion::Extensions::Social::Helpers::SocialGraph)
    end

    it 'accepts an injected social graph' do
      graph = Legion::Extensions::Social::Helpers::SocialGraph.new
      client = described_class.new(social_graph: graph)
      expect(client.social_graph).to equal(graph)
    end

    it 'ignores unknown keyword arguments' do
      expect { described_class.new(unknown: true) }.not_to raise_error
    end
  end

  describe 'runner integration' do
    subject(:client) { described_class.new }

    it 'responds to join_group' do
      expect(client).to respond_to(:join_group)
    end

    it 'responds to leave_group' do
      expect(client).to respond_to(:leave_group)
    end

    it 'responds to update_reputation' do
      expect(client).to respond_to(:update_reputation)
    end

    it 'responds to agent_reputation' do
      expect(client).to respond_to(:agent_reputation)
    end

    it 'responds to social_status' do
      expect(client).to respond_to(:social_status)
    end

    it 'responds to social_stats' do
      expect(client).to respond_to(:social_stats)
    end

    it 'responds to report_violation' do
      expect(client).to respond_to(:report_violation)
    end

    it 'responds to record_exchange' do
      expect(client).to respond_to(:record_exchange)
    end

    it 'can perform a full workflow' do
      client.join_group(group_id: :team, role: :contributor, members: %w[a1])
      client.update_reputation(agent_id: :a1, dimension: :reliability, signal: 0.9)
      client.record_exchange(agent_id: :a1, action: :helped, direction: :given)

      status = client.group_status(group_id: :team)
      expect(status[:group_id]).to eq(:team)

      stats = client.social_stats
      expect(stats[:groups]).to eq(1)
      expect(stats[:agents_tracked]).to eq(1)
      expect(stats[:ledger_size]).to eq(1)
    end
  end
end
