# metadata-json-deps

The metadata-json-deps tool validates dependencies in `metadata.json` files in Puppet modules against the latest published versions on the [Puppet Forge](https://forge.puppet.com/).

## Compatibility

metadata-json-deps is compatible with Ruby versions 2.0.0 and newer.

## Installation

via `gem` command:
``` shell
gem install metadata_json_deps
```

via Gemfile:
``` ruby
gem 'metadata_json_deps'
```

## Usage

### Testing with metadata-json-deps

On the command line, run `metadata-json-deps` with the path of your modules_list file, which contains a list of all the modules that you want to check,
 updated module name, updated version for that module, logs file path, true/false for the option to send logs to slack to a specific channel:

```shell
metadata-json-deps module_list.txt puppetlabs/stdlib 7.0.0 logs.log true
```

It can also be run verbosely to show valid dependencies:

```shell
metadata-json-deps module_list.txt puppetlabs/stdlib 7.0.0 logs.log -v true
```

### Testing with metadata-json-deps as a Rake task

You can also integrate `metadata-json-deps` checks into your tests using a Rake task:

```ruby
desc 'Compare specfified module and version against dependencies of other modules'
task :compare_dependencies, [:managed_modules, :module, :version, :verbose, :use_slack] do |task, args|
  MetadataJsonDeps::Runner.run(args[:managed_modules], args[:module], args[:version], args[:verbose], args[:use_slack], args[:logs_file])
end
```
