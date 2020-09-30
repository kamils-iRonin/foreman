namespace :templates_rendering_statuses do
  task refresh: :environment do
    Host::Managed.where(managed: true).in_batches(of: 100) do |batch|
      batch.map { |host| host.refresh_statuses([HostStatus::TemplatesRenderingStatus]) }
    end
  end
end
