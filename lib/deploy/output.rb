module Deploy
  module Output

    def announce(attachments)
      shout("#{attachments[:title]} - #{attachments[:text]}")
      notifier('', attachments)
    end

    def notifier(message, attachments)
      if ENV['SLACK_WEBHOOK']
        @notifier ||= Slack::Notifier.new(ENV['SLACK_WEBHOOK'])
        @notifier.ping(message, {
          attachments: [attachments]
        })
      else
        shout 'You can send deployment notifications if you set the SLACK_WEBHOOK environment variable.'
      end
    end

    def shout(message)
      message_size = message.size
      if message_size < 77
        # lines are always 80 characters
        stars = '*' * (77 - message_size)
        puts(red("+ ") + "#{message} #{red(stars)}")
      else
        puts(red('+ ') + message)
      end
    end

    def red(message)
      colorize(31, message)
    end

    def green(message)
      colorize(32, message)
    end

    def yellow(message)
      colorize(33, message)
    end

    def pink(message)
      colorize(35, message)
    end

    def blue(message)
      colorize(34, message)
    end

    def colorize(color_code, message)
      "\e[#{color_code}m#{message}\e[0m"
    end

  end
end

