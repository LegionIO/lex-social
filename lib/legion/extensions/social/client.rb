# frozen_string_literal: true

require 'legion/extensions/social/helpers/constants'
require 'legion/extensions/social/helpers/social_graph'
require 'legion/extensions/social/runners/social'

module Legion
  module Extensions
    module Social
      class Client
        include Runners::Social

        attr_reader :social_graph

        def initialize(social_graph: nil, **)
          @social_graph = social_graph || Helpers::SocialGraph.new
        end
      end
    end
  end
end
