# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Social::Helpers::Constants do
  describe 'ROLES' do
    it 'contains exactly 6 roles' do
      expect(described_class::ROLES.size).to eq(6)
    end

    it 'is frozen' do
      expect(described_class::ROLES).to be_frozen
    end

    %i[leader contributor specialist observer mentor newcomer].each do |role|
      it "includes #{role}" do
        expect(described_class::ROLES).to include(role)
      end
    end
  end

  describe 'RELATIONSHIP_TYPES' do
    it 'contains exactly 5 types' do
      expect(described_class::RELATIONSHIP_TYPES.size).to eq(5)
    end

    it 'is frozen' do
      expect(described_class::RELATIONSHIP_TYPES).to be_frozen
    end
  end

  describe 'REPUTATION_DIMENSIONS' do
    it 'contains exactly 5 dimensions' do
      expect(described_class::REPUTATION_DIMENSIONS.size).to eq(5)
    end

    it 'has weights summing to 1.0' do
      total = described_class::REPUTATION_DIMENSIONS.values.sum { |c| c[:weight] }
      expect(total).to be_within(0.001).of(1.0)
    end

    it 'has descriptions for every dimension' do
      described_class::REPUTATION_DIMENSIONS.each_value do |config|
        expect(config[:description]).to be_a(String)
        expect(config[:description]).not_to be_empty
      end
    end
  end

  describe 'STANDING_LEVELS' do
    it 'is ordered from highest to lowest threshold' do
      thresholds = described_class::STANDING_LEVELS.values
      expect(thresholds).to eq(thresholds.sort.reverse)
    end

    it 'has exemplary as the highest standing' do
      expect(described_class::STANDING_LEVELS.keys.first).to eq(:exemplary)
    end
  end

  describe 'COHESION_LEVELS' do
    it 'is ordered from highest to lowest threshold' do
      thresholds = described_class::COHESION_LEVELS.values
      expect(thresholds).to eq(thresholds.sort.reverse)
    end
  end

  describe 'NORM_VIOLATIONS' do
    it 'contains exactly 5 violation types' do
      expect(described_class::NORM_VIOLATIONS.size).to eq(5)
    end

    it 'is frozen' do
      expect(described_class::NORM_VIOLATIONS).to be_frozen
    end
  end

  describe 'scalar constants' do
    it 'has REPUTATION_ALPHA between 0 and 1' do
      expect(described_class::REPUTATION_ALPHA).to be_between(0.0, 1.0)
    end

    it 'has positive MAX_GROUPS' do
      expect(described_class::MAX_GROUPS).to be > 0
    end

    it 'has positive MAX_GROUP_MEMBERS' do
      expect(described_class::MAX_GROUP_MEMBERS).to be > 0
    end

    it 'has positive RECIPROCITY_WINDOW' do
      expect(described_class::RECIPROCITY_WINDOW).to be > 0
    end

    it 'has INFLUENCE_DECAY between 0 and 1' do
      expect(described_class::INFLUENCE_DECAY).to be_between(0.0, 1.0)
    end
  end
end
