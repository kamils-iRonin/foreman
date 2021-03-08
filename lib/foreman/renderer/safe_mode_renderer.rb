module Foreman
  module Renderer
    class SafeModeRenderer < BaseRenderer
      extend Foreman::Observable

      def self.render(source, scope)
        result = super

        trigger_hook(:safemode_rendered, payload: { host_id: scope.host&.id, template_id: source.template&.id }) unless scope.preview? || source.template&.snippet?

        result
      rescue StandardError => e
        trigger_hook(:safemode_rendering_error, payload: { host_id: scope.host&.id, template_id: source.template&.id }) unless scope.preview? || source.template&.snippet?

        raise e
      end

      def render
        box = Safemode::Box.new(scope, allowed_helpers, source_name)
        erb = ERB.new(source_content, nil, '-')
        box.eval(erb.src, allowed_variables)
      rescue ::Racc::ParseError => e
        new_e = SyntaxError.new(name: source_name, message: e.message)
        new_e.set_backtrace(e.backtrace)
        raise new_e
      end

      delegate :allowed_variables, :allowed_helpers, to: :scope
    end
  end
end
