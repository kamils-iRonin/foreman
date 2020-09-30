# frozen_string_literal: true

class TemplatesRenderingStatusCombination < ::ApplicationRecord
  belongs_to_host
  belongs_to :template, class_name: 'ProvisioningTemplate'
  belongs_to :host_status, primary_key: :host_id,
                           foreign_key: :host_id,
                           inverse_of: :combinations,
                           class_name: 'HostStatus::TemplatesRenderingStatus'

  validates :host, presence: true
  validates :template, presence: true
  validates :status, presence: true
  validates :host, uniqueness: { scope: :template }

  def refresh_status
    logger.debug("Refreshing the template rendering status combination of host #{host} with template: #{template}")

    assign_attributes(status: to_status)
  end

  private

  def to_status
    return HostStatus::TemplatesRenderingStatus::UNSAFEMODE_ERRORS if !Setting::Provisioning[:safemode_render] && !render_unsafemode
    return HostStatus::TemplatesRenderingStatus::SAFEMODE_ERRORS unless render_safemode

    HostStatus::TemplatesRenderingStatus::SAFEMODE_OK
  end

  def render_safemode
    template.render(renderer: Foreman::Renderer::SafeModeRenderer, host: host)
    true
  rescue StandardError
    false
  end

  def render_unsafemode
    template.render(renderer: Foreman::Renderer::UnsafeModeRenderer, host: host)
    true
  rescue StandardError
    false
  end
end
