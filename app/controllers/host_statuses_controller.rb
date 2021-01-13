class HostStatusesController < ApplicationController
  def welcome
  end

  def index
    @statuses = HostStatus.status_registry.select(&:stats_present?)
  end
end
