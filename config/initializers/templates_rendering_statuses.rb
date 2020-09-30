::Foreman::Application.dynflow.config.on_init do |world|
  RefreshTemplatesRenderingStatuses.spawn_if_missing(world)
end
