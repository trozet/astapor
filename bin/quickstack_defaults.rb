#!/usr/bin/ruby
# Setup Foreman default values (create or update) for:
# - Smart Class Parameters for Quickstack puppet modules
# - Hostgroups
# Version 1.0
# Requires Foreman 1.6.0.15+

require 'rubygems'
require 'erb'
require 'foreman_api'
require 'logger'
require 'yaml'
require 'optparse'
require 'ostruct'

class Optparse
  def self.parse(args)
    options = OpenStruct.new
    options.base_url = 'https://127.0.0.1'
    options.debug = false
    options.hostgroups = '/usr/share/openstack-foreman-installer/config/hostgroups.yaml'
    options.params = '/usr/share/openstack-foreman-installer/config/quickstack.yaml.erb'
    options.password = 'changeme'
    options.username = 'admin'
    options.verbose = false

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{__FILE__} [options] parameters | hostgroups"

      opts.on('-b', '--url_base URL', 'Base URL') do |b|
        options.base_url = b
      end

      opts.on('-d', '--default_params FILE', 'File of Parameter defaults (YAML Template)') do |d|
        options.params = d
      end

      opts.on('-g', '--hostgroups File', 'File of Hostgroups defaults (YAML)') do |g|
        options.hostgroups = g
      end

      opts.on('-p', '--password NAME', 'password') do |p|
        options.password = p
      end

      opts.on('-u', '--username NAME', 'username') do |u|
        options.username = u
      end

      opts.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
        options.verbose = v
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end
    opt_parser.parse!(args)
    options
  end
end

class Configuration
  def initialize(filename)
    @data = YAML.load(File.open(filename))
  end

  def data
    @data
  end

  def to_s
    list=''
    @data.each { |k,v|  list << "#{k.to_s} => #{v.to_s}\n" }
    list
  end
end

class HostgroupsConf < Configuration
end

class QuickstackConf < Configuration
  def initialize(filename)
    template = ERB.new(File.new(filename).read, nil, '%-')
    @data  = YAML.load(template.result(binding))
  end
end

def get_key_type(value)
  # To Do - Fetch key_list via ForemanAPI
  key_list = %w( string boolean integer real array hash yaml json )
  value_type = value.class.to_s.downcase
  if key_list.include?(value_type)
    return value_type
  elsif [FalseClass, TrueClass].include? value.class
    return 'boolean'
  end
  # If we need to handle actual number classes like Fixnum, add those here
end

def environment_id
  env = @environment.index({:search => 'production'})[0]['results'][0]
  return env['id'] if env
end

def hostgroup_create_update(name)
  hostgroup = @hostgroups.index({ :search => name })[0]['results']
  if hostgroup == []
    # Create Hostgroup
    data = {
      'name' => name,
      'environment_id' => environment_id
    }
    hostgroup = @hostgroups.create(data)[0]
    @log.info("Hostgroup: #{name} [CREATED]")
    hostgroup['id']
  else
    # Hostgroup exists
    hostgroup[0]['id']
  end
end

def get_puppetclass(name)
  @puppetclasses.index({ :search => "name=#{name}" })[0]['results']
end

def get_puppet_classes(hg)
  list = []
  pclassnames = hg[:class].kind_of?(Array) ? hg[:class] : [ hg[:class] ]
  pclassnames.each do |pclassname|
    puppetclass = get_puppetclass(pclassname)
    if puppetclass.has_key?('quickstack')
        puppetclass['quickstack'].each do |pclass|
        list << pclass['id']
      end
    else
      @log.warn("#{pclassname} puppetclass not in 'quickstack'")
    end
  end
  return list
end

def set_hostgroups
  @log.info("Setting Hostgroups defaults")
  @config_hg.each do |hg|
    id = hostgroup_create_update(hg[:name])
    get_puppet_classes(hg).each do |pclass_id|
      hostgroupclasses = @hostgroupclasses.index({ 'hostgroup_id' => id, })[0]['results']
      if hostgroupclasses
        unless hostgroupclasses.include?(pclass_id)
          data = { 'hostgroup_id' => id, 'puppetclass_id' => pclass_id }
          @hostgroupclasses.create(data)
          @log.info("Hostgroup: #{hg[:name]}: puppetclass #{pclass_id} [ADDED]")
        end
      end
    end
  end
end

def set_params
  @log.info("Setting parameters defaults")
  @config_hg.each do |hg|
    pclassnames = hg[:class].kind_of?(Array) ? hg[:class] : [ hg[:class] ]
    pclassnames.each do |pclassname|
      puppetclass = get_puppetclass(pclassname)
      if puppetclass.has_key?('quickstack')
        puppetclass['quickstack'].each do |pclass|
          res = @puppetclasses.show({ 'id' => pclass['id'] })[0]
          res['smart_class_parameters'].each do |param|
            if @config_params.include?(param['parameter'])
              data = { 'id' => param['id'],
                'smart_class_parameter' => {
                  'default_value'  => @config_params[param['parameter']],
                  'parameter_type' => get_key_type(param['parameter'])}
              }
              @smart_params.update(data)
              @log.info("#{pclass['name']}: #{param['parameter']} [UPDATED]")
            end
          end
        end
      else
        @log.warn("#{pclassname} puppetclass not in 'quickstack'")
      end
    end
  end

end

# Main
options = Optparse.parse(ARGV)

@log = Logger.new(STDOUT)
@log.datetime_format = "%d/%m/%Y %H:%M:%S"
@log.level = options.verbose ? Logger::INFO : Logger::WARN

@config_params = QuickstackConf.new(options.params).data
@config_hg = HostgroupsConf.new(options.hostgroups).data

auth = {
  :logger   => options.debug ? @log : nil,
  :base_url => options.base_url,
  :username => options.username,
  :password => options.password
}

@environment   = ForemanApi::Resources::Environment.new(auth)
@hostgroups    = ForemanApi::Resources::Hostgroup.new(auth)
@hostgroupclasses = ForemanApi::Resources::HostgroupClass.new(auth)
@puppetclasses = ForemanApi::Resources::Puppetclass.new(auth)
@smart_params  = ForemanApi::Resources::SmartClassParameter.new(auth)

case ARGV[0]
when 'parameters'
  set_params
when 'hostgroups'
  set_hostgroups
end
