# frozen_string_literal: true

module Legion
  module Extensions
    module Social
      module Helpers
        module Constants
          # Social roles an agent can hold in a group
          ROLES = %i[
            leader
            contributor
            specialist
            observer
            mentor
            newcomer
          ].freeze

          # Group relationship types
          RELATIONSHIP_TYPES = %i[
            ally
            collaborator
            neutral
            competitor
            adversary
          ].freeze

          # Reputation dimensions
          REPUTATION_DIMENSIONS = {
            reliability: { weight: 0.25, description: 'Follows through on commitments' },
            competence:  { weight: 0.25, description: 'Quality of work output' },
            benevolence: { weight: 0.20, description: 'Acts in others interests' },
            integrity:   { weight: 0.15, description: 'Consistency between words and actions' },
            influence:   { weight: 0.15, description: 'Ability to shape group direction' }
          }.freeze

          # EMA alpha for reputation updates
          REPUTATION_ALPHA = 0.1

          # Social standing thresholds
          STANDING_LEVELS = {
            exemplary:  0.8,
            respected:  0.6,
            neutral:    0.4,
            marginal:   0.2,
            ostracized: 0.0
          }.freeze

          # Group cohesion thresholds
          COHESION_LEVELS = {
            tight:     0.7,
            moderate:  0.5,
            loose:     0.3,
            fractured: 0.0
          }.freeze

          # Maximum tracked groups
          MAX_GROUPS = 20

          # Maximum members per group
          MAX_GROUP_MEMBERS = 50

          # Social norms violation types
          NORM_VIOLATIONS = %i[
            free_riding
            defection
            deception
            dominance_abuse
            exclusion
          ].freeze

          # Reciprocity tracking window
          RECIPROCITY_WINDOW = 50

          # Valid reciprocity directions
          RECIPROCITY_DIRECTIONS = %i[given received].freeze

          # Social influence decay rate
          INFLUENCE_DECAY = 0.02
        end
      end
    end
  end
end
