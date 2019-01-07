require 'puppet_forge'
require 'semantic_puppet'
require 'yaml'

module MetadataJsonDeps
  class ForgeHelper
    def initialize(cache = {})
      @cache = cache
    end

    def get_current_version(name)
      name = name.sub('/', '-')
      version = @cache[name]

      unless version
        @cache[name] = version = get_version(get_mod(name))
      end

      version
    end

    def get_metadata_json(name)
      name = name.sub('/', '-')
      version = @cache[name]
      metadata = @cache["#{name}-metadata"]

      if metadata.nil?
        begin
          version = get_current_version(name) unless version
        rescue Exception
        end
      end

      unless metadata
        @cache["#{name}-metadata"] = metadata = get_metadata("#{name}-#{version}")
      end

      metadata
    end

    def get_module_list(filename)
      modules = PuppetForge::V3::Module.where(:owner => 'puppetlabs', :limit => 100)
      module_list = []

      modules.each do |mod|
        module_list.push(mod.uri.split('/').last)
      end
      until modules.next.nil?
        modules = modules.next
        modules.each do |mod|
          module_list.push(mod.uri.split('/').last)
        end
      end
      File.open(filename, 'w') {|f| f.write module_list.join("\n")}
      module_list
    end

    private

    def get_mod(name)
      PuppetForge::Module.find(name)
    end

    def get_metadata(name)
      PuppetForge::Release.find(name).metadata
    end

    def get_version(mod)
      SemanticPuppet::Version.parse(mod.current_release.version)
    end

    def get_metadata(name)
      PuppetForge::Release.find(name).metadata
    end
  end
end
