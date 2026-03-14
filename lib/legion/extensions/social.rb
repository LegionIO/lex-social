# frozen_string_literal: true

require 'legion/extensions/social/version'
require 'legion/extensions/social/helpers/constants'
require 'legion/extensions/social/helpers/social_graph'
require 'legion/extensions/social/runners/social'
require 'legion/extensions/social/client'

module Legion
  module Extensions
    module Social
      extend Legion::Extensions::Core if Legion::Extensions.const_defined?(:Core)
    end
  end
end
