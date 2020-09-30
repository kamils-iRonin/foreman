require 'test_helper'

class TemplatesRenderingStatusTest < ActiveSupport::TestCase
  subject { host.get_status(HostStatus::TemplatesRenderingStatus) }

  setup do
    Setting.find_by(name: :safemode_render).update(value: false)
  end

  describe '#to_status' do
    let(:operatingsystem) { FactoryBot.create(:operatingsystem, :with_associations) }
    let(:provisioning_template) do
      FactoryBot.create(
        :provisioning_template,
        operatingsystems: [operatingsystem],
        locations: [host.location],
        organizations: [host.organization],
        template: template
      )
    end
    let(:template_combination) do
      FactoryBot.create(
        :template_combination,
        provisioning_template: provisioning_template,
        hostgroup: host.hostgroup,
        environment: host.environment
      )
    end
    let(:host) do
      FactoryBot.create(
        :host,
        :managed,
        :with_hostgroup,
        operatingsystem: operatingsystem,
        medium: operatingsystem.media.first,
        ptable: operatingsystem.ptables.first
      )
    end

    describe 'pending' do
      let(:host) { FactoryBot.create(:host) }

      it { assert_equal HostStatus::TemplatesRenderingStatus::PENDING, subject.to_status }
    end

    describe 'missing template error' do
      let(:host) { FactoryBot.create(:host, :managed) }

      it { assert_equal HostStatus::TemplatesRenderingStatus::MISSING_TEMPLATE_ERROR, subject.to_status }
    end

    describe 'safemode ok' do
      let(:expected) { HostStatus::TemplatesRenderingStatus::SAFEMODE_OK }
      let(:template) { '<%= @host.name %>' }

      setup do
        template_combination
      end

      it { assert_equal expected, subject.to_status }

      describe 'snippet rendering' do
        let(:template) { "<%= snippet('#{snippet.name}') %>" }
        let(:snippet) { FactoryBot.create(:provisioning_template, :snippet, template: '<%= @host.name %>') }

        it { assert_equal expected, subject.to_status }
      end
    end

    describe 'safemode error' do
      let(:expected) { HostStatus::TemplatesRenderingStatus::SAFEMODE_ERRORS }
      let(:template) { '<%= @host.owner_name %>' }

      setup do
        template_combination
      end

      it { assert_equal expected, subject.to_status }

      describe 'snippet rendering' do
        let(:template) { "<%= snippet('#{snippet.name}') %>" }
        let(:snippet) { FactoryBot.create(:provisioning_template, :snippet, template: '<%= @host.owner_name %>') }

        it { assert_equal expected, subject.to_status }
      end
    end

    describe 'unsafemode error' do
      let(:expected) { HostStatus::TemplatesRenderingStatus::UNSAFEMODE_ERRORS }
      let(:template) { '<%= invalid_macro %>' }

      setup do
        template_combination
      end

      it { assert_equal expected, subject.to_status }

      describe 'snippet rendering' do
        let(:template) { "<%= snippet('#{snippet.name}') %>" }
        let(:snippet) { FactoryBot.create(:provisioning_template, :snippet, template: '<%= invalid_macro %>') }

        it { assert_equal expected, subject.to_status }
      end
    end
  end
end
