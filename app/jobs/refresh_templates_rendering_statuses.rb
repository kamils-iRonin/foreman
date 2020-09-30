# frozen_string_literal: true

class RefreshTemplatesRenderingStatuses < ApplicationJob
  after_perform do
    self.class.set(wait: self.class.wait_time).perform_later
  end

  def self.wait_time
    Setting[:templates_rendering_statuses_refresh_interval].minutes
  end

  queue_as :refresh_templates_rendering_statuses

  def perform
    Host::Managed.joins(medium: :operatingsystems)
                 .where(Operatingsystem.arel_table[:id].eq(Host::Managed.arel_table[:operatingsystem_id]))
                 .where(managed: true)
                 .where(id: HostStatus::TemplatesRenderingStatus.pending.select(:host_id))
                 .map do |host|
                   Foreman::Logging.logger('background').debug("Refreshing templates rendering status of host")
                   host.refresh_statuses([HostStatus::TemplatesRenderingStatus])
                 end
  end

  rescue_from(StandardError) do |error|
    Foreman::Logging.logger('background').error("Refresh templates rendering statuses #{error}: #{error.backtrace}")
  end

  def humanized_name
    _('Refresh templates rendering statuses')
  end
end
