module Skylight::Core
  module Probes
    module ActionView
      class Probe
        def install
          ::ActionView::TemplateRenderer.class_eval do
            alias render_with_layout_without_sk render_with_layout

            def render_with_layout(path, locals, *args, &block) #:nodoc:
              layout = nil

              if path
                if method(:find_layout).arity == 3
                  # Rails 5
                  layout = find_layout(path, locals.keys, [formats.first])
                else
                  # Rails 4
                  layout = find_layout(path, locals.keys)
                end
              end

              if layout
                instrument(:template, :identifier => layout.identifier) do
                  render_with_layout_without_sk(path, locals, *args, &block)
                end
              else
                render_with_layout_without_sk(path, locals, *args, &block)
              end
            end
          end
        end
      end
    end

    register("ActionView::TemplateRenderer", "action_view", ActionView::Probe.new)
  end
end
