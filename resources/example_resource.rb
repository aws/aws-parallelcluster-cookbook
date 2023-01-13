# frozen_string_literal: true

provides :example_resource
unified_mode true

# Resource:: example resource

default_action :example

action :example do
  file "/tmp/example_file" do
    action :create_if_missing
  end
end
