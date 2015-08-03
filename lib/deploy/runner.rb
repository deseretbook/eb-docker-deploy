module Deploy
  class Runner < Thor
    include Deploy::Output
    include Deploy::Commands
    include Deploy::Checks
    include Deploy::Versions
    include Deploy::Utility

    method_option :version, aliases: '-v', desc: 'Version', required: true
    method_option :environment, aliases: '-e', desc: 'Environment', required: true
    method_option :build, aliases: '-b', desc: 'Build Image', default: true
    desc 'deploy', 'deploy'
    def deploy
      check_setup

      environment = options[:environment]
      build = options[:build]

      version = options[:version]
      check_version(version, environment)

      repo = ENV['DOCKER_REPO']

      if build && !version_exists?(version)
        announce_title = "Deployment started with build"
        build_image(repo, version)
      else
        announce_title = "Deployment started without build"
        pull_image(repo, version)
      end

      tag_image_as_latest(repo, version)

      push_image(repo, version)
      push_image(repo, 'latest')

      announce({ color: '#6080C0', title: announce_title, text: "Deploying version #{version} to #{environment}" })
      run_deploy(version, environment)
      announce({ color: 'good', title: 'Deployment Succeeded!!', text: "The current version of #{environment} is #{version}" })
    end

    method_option :version, aliases: '-v', desc: 'Version', required: true
    method_option :environment, aliases: '-e', desc: 'Environment', required: true
    desc 'rollback', 'rollback'
    def rollback
      check_setup

      environment = options[:environment]
      version = options[:version]
      check_rollback_version(version, environment)

      repo = ENV['DOCKER_REPO']

      announce({ color: '#6080C0', title: "Rollback started", text: "Rolling back to #{version} on #{environment}" })

      pull_image(repo, version)

      tag_image_as_latest(repo, version)

      push_image(repo, 'latest')

      run_rollback(version, environment)
      announce({ color: 'good', title: 'Rollback Succeeded!!', text: "The current version of #{environment} is #{version}" })
    end

    desc 'send test notification', 'send test notification'
    def test_slack
      notifier('', { color: 'good', title: 'This is a test notification from eb-docker-deploy.' })
    end

    desc 'list versions', 'list all application versions'
    def versions
      check_setup

      application_versions_array.each do |version|
        shout version
      end
    end

    method_option :environment, aliases: '-e', desc: 'Environment', required: true
    desc 'show version', 'show environment version'
    def version
      check_setup

      shout current_version_for_environment(options[:environment])
    end

    desc 'setup config', 'setup config'
    def setup
      (shout('AWS creds already configured in ~/.bashrc'); exit(1)) if ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY'] && ENV['AWS_REGION']

      key = ask('Enter AWS Key:')
      secret = ask('Enter AWS Secret:')
      region = ask('Enter AWS Region:', default: 'us-west-2')

      File.open(File.expand_path('~/.bashrc'), 'a') do |f|
        f.puts ''
        f.puts '# Variables defined by eb-docker-deploy:'
        f.puts "export AWS_ACCESS_KEY_ID=#{key}"
        f.puts "export AWS_SECRET_ACCESS_KEY=#{secret}"
        f.puts "export AWS_REGION=#{region}"
      end

      shout('AWS creds successfully configured at ~/.bashrc.')
      shout('You must now run "source ~/.bashrc"')
    end

  end
end
