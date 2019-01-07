require 'json'
require 'yaml'
require 'logger'
require 'net/http'

module MetadataJsonDeps
  class Runner
    def initialize(filename, updated_module, updated_module_version, logs_file, verbose, use_slack)
      #def initialize(options)
      @module_names = return_modules(filename)
      @filename = filename
      @use_slack = use_slack
      @updated_module = updated_module.sub('-', '/')
      @logs_file = logs_file
      @updated_module_version = updated_module_version
      @verbose = verbose
      @forge = MetadataJsonDeps::ForgeHelper.new
      @slack_webhook = 'https://hooks.slack.com/services/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'
    end

    def run
      #@forge.get_module_list(@filename)
      conflict_found = false
      File.delete(@logs_file) if File.exists?(@logs_file)
      logger = Logger.new File.new(@logs_file, 'w')
      logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      if @updated_module
        @updated_module = @updated_module.sub('-', '/')
        msg = "\n Checked against module: #{@updated_module} with version #{@updated_module_version} \n" + "-" * 60 + "\n"
      end
      @module_names.split(" ").each do |module_name|
        msg += "Checking #{module_name} \n"
        metadata = @forge.get_metadata_json(module_name)
        checker = MetadataJsonDeps::MetadataChecker.new(metadata, @forge, @updated_module, @updated_module_version)

        checker.dependencies.each do |dependency, constraint, current, satisfied|
          if @updated_module
            if dependency.sub('-', '/') == @updated_module.sub('-', '/')
              current = @updated_module_version
            end
          end

          if checker.dependencies
            msg += "NO dependencies found for #{module_name}!'" + "\n" +"-" * 60 + "\n"
            next
          end

          if satisfied
            if @verbose
              msg += "\t #{dependency} (#{constraint}) matches #{current} \n"
            end
          else
            conflict_found = true
            msg += "\t #{dependency} (#{constraint}) doesn't match #{current} \n"
          end
        end
        if conflict_found == false
          msg += "NO conflicts found for #{module_name}!'" + "\n" +"-" * 60 + "\n"
        else
          msg += "-" * 60 + "\n"
          conflict_found = false
        end
      end

      logger.info msg
      post_to_slack(msg) if @use_slack
    rescue Interrupt
    end

    def return_modules(filename)
      raise "File '#{filename}' is empty/does not exist" if File.size?(filename).nil?
      YAML.safe_load(File.open(filename))
    end

    def post_to_slack(message)
      raise 'METADATA_JSON_DEPS_SLACK_WEBHOOK env var not specified' unless @slack_webhook

      uri = URI.parse(@slack_webhook)
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/json'
      request.body = JSON.dump({
                                   'text' => message
                               })

      req_options = {
          use_ssl: uri.scheme == 'https',
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      raise 'Encountered issue posting to Slack' unless response.code == '200'
    end

    def self.run(filename, module_name, new_version, logs_file, verbose = false, use_slack = 'false')
      self.new(filename, module_name, new_version, logs_file, verbose, use_slack = 'false').run
    end
  end
end
