module Deploy
  class Runner < Thor
    include Deploy::Output
    include Deploy::Commands
    include Deploy::Checks
    include Deploy::Versions
    include Deploy::Utility

    method_option :version, aliases: '-v', desc: 'Version', type: :string, required: true
    method_option :environment, aliases: '-e', desc: 'Environment', type: :string, required: true
    method_option :build, aliases: '-b', desc: 'Build Image', type: :boolean, default: true
    desc 'deploy [files...]', 'build deploy.zip and deploy to Elastic Beanstalk; use relative paths for extra files!'
    def deploy(*files)
      self.build_zip(*files)

      environment = options[:environment]
      version = options[:version]
      build = options[:build]
      repo = ENV['DOCKER_REPO']

      if build && !version_exists?(version)
        announce_title = "Deployment started with an image that was just built"
        build_image(repo, version)
        push_image(repo, version)
      else
        announce_title = "Deployment started with an image that was already built"
      end

      announce({ color: '#6080C0', title: announce_title, text: "Deploying version #{version} to #{environment}" })
      run_deploy(version, environment)
      announce({ color: 'good', title: 'Deployment Succeeded!!', text: "The current version of #{environment} is #{version}" })
    end

    method_option :version, aliases: '-v', desc: 'Version', type: :string, required: true
    method_option :environment, aliases: '-e', desc: 'Environment', type: :string, required: true
    desc 'build_zip [files...]', 'build deploy.zip for testing (not needed before deploy); use relative paths for extra files!'
    def build_zip(*files)
      check_setup

      environment = options[:environment]
      version = options[:version]
      repo = ENV['DOCKER_REPO']

      check_version(version, environment)

      use_tag_in_dockerrun(repo, version)
      create_deploy_zip_file(*files)
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

    desc 'copy_env FROM TO', 'copy environment variables from one environment to another'
    def copy_env(from, to)
      copy_beanstalk_vars(from, to)
    end
  end
end
