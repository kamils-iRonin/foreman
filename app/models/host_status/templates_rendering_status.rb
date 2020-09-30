# frozen_string_literal: true

module HostStatus
  class TemplatesRenderingStatus < ::HostStatus::Status
    PENDING = 0
    SAFEMODE_OK = 1
    SAFEMODE_ERRORS = 2
    UNSAFEMODE_ERRORS = 3
    MISSING_TEMPLATE_ERROR = 4

    def self.status_name
      N_('Templates Rendering Status')
    end

    has_many :combinations, primary_key: :host_id,
                            foreign_key: :host_id,
                            class_name: 'TemplatesRenderingStatusCombination',
                            inverse_of: :host_status,
                            autosave: true,
                            dependent: :destroy
    has_many :templates, through: :combinations

    scope :pending, -> { where(status: PENDING) }

    delegate :provisioning_template, to: :host

    def to_status(_options = {})
      return PENDING unless relevant?

      actual_templates = TemplateKind.order(:name)
                                     .map { |kind| provisioning_template(kind: kind.name) }
                                     .compact

      logger.debug("#{host}: templates: #{actual_templates.map(&:name).to_sentence}")

      statuses_for_destruction = combinations.where.not(template: actual_templates)
      logger.debug("#{host}: statuses for destruction: #{statuses_for_destruction.map { |c| "#{c.template} - #{c.status}" }.to_sentence}")
      statuses_for_destruction.map(&:mark_for_destruction)

      return MISSING_TEMPLATE_ERROR unless actual_templates.any?

      actual_templates.reject { |template| templates.include?(template) }
                      .map { |template| combinations.first_or_initialize(template: template) }

      combinations.reject(&:marked_for_destruction?).map(&:refresh_status)

      statuses = combinations.reject(&:marked_for_destruction?).pluck(:status)

      logger.debug("#{host}: recognized statuses #{combinations.reject(&:marked_for_destruction?).map { |c| "#{c.template} - #{c.status}" }.to_sentence}")

      return PENDING if statuses.include?(PENDING)
      return UNSAFEMODE_ERRORS if statuses.include?(UNSAFEMODE_ERRORS)
      return SAFEMODE_ERRORS if statuses.include?(SAFEMODE_ERRORS)

      SAFEMODE_OK
    end

    def to_global(_options = {})
      case status
      when UNSAFEMODE_ERRORS, MISSING_TEMPLATE_ERROR
        HostStatus::Global::ERROR
      when SAFEMODE_ERRORS
        HostStatus::Global::WARN
      else
        HostStatus::Global::OK
      end
    end

    def to_label(_options = {})
      case status
      when SAFEMODE_OK
        N_('OK')
      when SAFEMODE_ERRORS
        N_('Safe mode Error')
      when UNSAFEMODE_ERRORS
        N_('Unsafe mode Error')
      when MISSING_TEMPLATE_ERROR
        N_('Provisioning Template is missing')
      else
        N_('Pending')
      end
    end

    def relevant?(_options = {})
      host.managed?
    end
  end
end