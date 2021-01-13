module HostStatus
  class BuildStatus < Status
    PENDING = 1
    TOKEN_EXPIRED = 2
    BUILD_FAILED = 3
    BUILT = 0

    LABELS = {
      PENDING => N_("Pending installation"),
      TOKEN_EXPIRED => N_("Token expired"),
      BUILD_FAILED => N_("Installation error"),
      BUILT => N_("Installed"),
    }.freeze

    def self.status_name
      N_("Build")
    end

    def self.stats
      data = group(:status).count

      [
        { label: LABELS[PENDING], hosts_count: data.fetch(PENDING,  0), global_status: HostStatus::Global::OK },
        { label: LABELS[TOKEN_EXPIRED], hosts_count: data.fetch(TOKEN_EXPIRED,  0), global_status: HostStatus::Global::ERROR },
        { label: LABELS[BUILD_FAILED], hosts_count: data.fetch(BUILD_FAILED,  0), global_status: HostStatus::Global::ERROR },
        { label: LABELS[BUILT], hosts_count: data.fetch(BUILT,  0), global_status: HostStatus::Global::OK }
      ]
    end

    def to_label(options = {})
      LABELS.fetch(to_status, N_("Unknown build status"))
    end

    def to_global(options = {})
      case to_status
        when TOKEN_EXPIRED, BUILD_FAILED
          HostStatus::Global::ERROR
        else
          HostStatus::Global::OK
      end
    end

    def to_status(options = {})
      if waiting_for_build?
        if token_expired?
          TOKEN_EXPIRED
        else
          PENDING
        end
      else
        if build_errors?
          BUILD_FAILED
        else
          BUILT
        end
      end
    end

    def relevant?(options = {})
      SETTINGS[:unattended] && host.managed?
    end

    def waiting_for_build?
      host&.build
    end

    def token_expired?
      host&.token_expired?
    end

    def build_errors?
      host && host.build_errors.present?
    end
  end
end

HostStatus.status_registry.add(HostStatus::BuildStatus)
