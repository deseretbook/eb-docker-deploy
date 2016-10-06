require 'open3'

module Deploy
  module Utility

    def command?(command)
      system("which #{command} > /dev/null 2>&1")
    end

    def run_cli(command)
      stdin, stdout, stderr, wait_thr = Open3.popen3(command)
      resp = stdout.gets(nil)
      stdout.close
      err = stderr.gets(nil)
      stderr.close
      exit_code = wait_thr.value.exitstatus
      puts resp
      puts err unless err.nil?
      true unless resp.downcase.include?("error") || exist_code != 0
    end

  end
end
