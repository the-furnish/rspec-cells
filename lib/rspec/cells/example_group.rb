module RSpec
  module Cells
    # Lets you call #render_cell in Rspec2. Move your cell specs to <tt>spec/cells/</tt>.
    module ExampleGroup
      extend ActiveSupport::Concern

      include RSpec::Rails::RailsExampleGroup
      include Cell::TestCase::TestMethods
      include ActionController::UrlFor

      if defined?(::Webrat)
        include ::Webrat::Matchers
        include ::Webrat::Methods

      elsif defined?(::Capybara)
        begin
          include ::Capybara::DSL
        rescue NameError
          include ::Capybara
        end

        # Overwrite to wrap render_cell into a Capybara custom string with a
        # lot of matchers.
        #
        # Read more at:
        #
        # The Capybara.string method documentation:
        #   - http://rubydoc.info/github/jnicklas/capybara/master/Capybara#string-class_method
        #
        # Return value is an instance of Capybara::Node::Simple
        #   - http://rubydoc.info/github/jnicklas/capybara/master/Capybara/Node/Simple
        #
        # That expose all the methods from the following capybara modules:
        #   - http://rubydoc.info/github/jnicklas/capybara/master/Capybara/Node/Matchers
        #   - http://rubydoc.info/github/jnicklas/capybara/master/Capybara/Node/Finders
        def render_cell(*)
          Capybara.string super
        end

        def cell(*)
          Content.new(super)
        end


        # TODO: test if view model cell wrapping works (and normal dialect)
        # test with both webrick and capybara
        class Content
          def initialize(cell)
            @cell = cell
          end

          def method_missing(*args)
            content = @cell.send(*args)

            return Capybara.string(content) if content.is_a?(String)
            content
          end
        end
      end

      attr_reader :controller, :routes

      def method_missing(method, *args, &block)
        # Send the route helpers to the application router.
        if @routes && @routes.named_routes.route_defined?(method)
          @controller.send(method, *args, &block)
        else
          super
        end
      end

      included do
        metadata[:type] = :cell
        before do # called before every it.
          @routes = ::Rails.application.routes
          ActionController::Base.allow_forgery_protection = false
          setup # defined in Cell::TestCase.
        end

        # we always render views in rspec-cells, so turn it on.
        subject { controller }
      end
    end
  end
end

RSpec.configure do |c|
  c.include RSpec::Cells::ExampleGroup, :file_path => /spec\/cells/
  c.include RSpec::Cells::ExampleGroup, :type => :cell
end
