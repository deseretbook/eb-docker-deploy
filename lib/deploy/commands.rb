require 'deploy/utility'
require 'zip'

module Deploy
  module Commands
    include Deploy::Utility

    def build_image(repo, tag)
      if File.readable? 'Dockerfile.erb'
        shout "Processing Dockerfile.erb with ERB"
        system('erb Dockerfile.erb > Dockerfile') || exit(1)
      end

      shout "Building Docker Image: #{repo}:#{tag}"
      command = "docker build -t #{repo}:#{tag} ."
      exit(1) unless system(command)
    end

    def create_deploy_zip_file
      shout "Creating or overwriting deploy.zip"

      File.unlink('deploy.zip') if File.exists?('deploy.zip')

      Zip::File.open('deploy.zip', Zip::File::CREATE) do |zip|
        Dir['.elasticbeanstalk/*', '.ebextensions/*', 'Dockerrun.aws.json'].each do |f|
          zip.add(f, f)
        end
      end

      exit(1) unless File.readable?('deploy.zip')
    end

    def use_tag_in_dockerrun(repo, tag)
      shout "Changing Dockerrun.aws.json to contain latest tag"
      command = "sed 's/<TAG>/#{tag}/' < Dockerrun.aws.json.template > Dockerrun.aws.json"
      exit(1) unless system(command)
    end

    def push_image(repo, tag)
      shout "Pushing Docker Image: #{repo}:#{tag}"
      command = "docker push #{repo}:#{tag}"
      exit(1) unless system(command)
    end

    def pull_image(repo, tag)
      shout "Pulling Docker Image: #{repo}:#{tag}"
      command = "docker pull #{repo}:#{tag}"
      exit(1) unless system(command)
    end

    def run_deploy(version, environment)
      command = "eb deploy #{environment} --label #{version}"
      shout "deploying #{version} to elastic beanstalk with command:\n\t#{command}"
      exit(1) unless system(command)
    end

    def run_rollback(version, environment)
      command = "eb deploy #{environment} --version #{version}"
      shout "deploying #{version} to elastic beanstalk with command:\n\t#{command}"
      exit(1) unless system(command)
    end

    # FIXME: Parsing command line output is brittle
    def copy_beanstalk_vars(from_env, to_env)
      var_regexp = %r{^[-A-Za-z0-9\\_.:/+@]}

      vars = `eb printenv #{from_env.inspect}`.lines.select{|l|
        l.include?(' = ')
      }.map{|l|
        l.strip.split(' = ', 2)
      }.reject{|l|
        k, v = *l
        if l.include?('=')
          shout "Excluding #{k} due to name including an equal sign"
          true
        elsif !(k =~ var_regexp && v =~ var_regexp)
          shout "Excluding #{k} due to name or value starting with an invalid character"
          true
        else
          false
        end
      }.map{|l|
        l.map(&:inspect).join('=')
      }

      exit(1) unless $?.exitstatus == 0

      command = "eb setenv #{vars.join(' ')} -e #{to_env.inspect}"

      shout "copying environment variables from #{from_env} to #{to_env} with command:\n\t#{command}"
      exit(1) unless system(command)
    end
  end
end
