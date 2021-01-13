module HostStatusesHelper
  include HostsHelper

  def host_status_global_status_icon_class(status)
    global_statuses = status.stats
                            .select { |item| item[:hosts_count] > 0 }
                            .map { |item| item[:global_status] }

    if global_statuses.include?(HostStatus::Global::ERROR)
      host_global_status_icon_class(HostStatus::Global::ERROR)
    elsif global_statuses.include?(HostStatus::Global::WARN)
      host_global_status_icon_class(HostStatus::Global::WARN)
    elsif global_statuses.include?(HostStatus::Global::OK)
      host_global_status_icon_class(HostStatus::Global::OK)
    else
      host_global_status_icon_class(nil)
    end
  end
end
