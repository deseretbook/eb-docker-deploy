require 'deploy/utility'

module Deploy
  module Versions
    include Deploy::Utility

    def eb
      @eb ||= Aws::ElasticBeanstalk::Client.new
    end

    def version_exists?(version)
      application_versions_array.include?(version)
    end

    def current_version_for_environment(environment)
      eb.describe_environments(application_name: application_name, environment_names: [environment]).environments.first.version_label
    end

    def application_versions_array
      @array ||= eb.describe_application_versions(application_name: application_name).application_versions.reverse.map(&:version_label)
    end

    def delete_old_versions
      versions = eb.describe_application_versions(application_name: application_name).application_versions.sort_by(&:date_updated)
      environments = eb.describe_environments(application_name: application_name).environments
      env_versions = environments.map(&:version_label)
      versions.reject!{|v|
        env = environments.detect{|e| e.version_label == v.version_label}
        if env
          shout "Not deleting version #{v.version_label} in use by #{env.environment_name}"
          true
        elsif v.date_updated >= Time.now - (86400 * 2)
          shout "Not deleting version #{v.version_label} that is less than two days old"
          true
        else
          false
        end
      }

      versions.each_with_index do |v, idx|
        if idx < versions.count - 50
          say "Deleting old version #{red v.version_label} from #{pink v.date_updated}"
          eb.delete_application_version(application_name: application_name, version_label: v.version_label, delete_source_bundle: true)
        else
          say "Keeping version #{blue v.version_label} from #{pink v.date_updated}"
        end
      end
    end
  end
end
