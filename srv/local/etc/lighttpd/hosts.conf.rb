#! /usr/bin/ruby -w
#
# This scripts scans for conf files and prints them inside the appropriate host
# conditionals.  Call this file from lighttpd.conf with include_shell
# 
# Set the config hash to match your servers configuration.  For each key (doesn't
# matter what it's called) you need to set :path and :host.  You can name parts of
# the path, and these can be used for printing the host spec.
#
# You can also set :match (to '=='), or :conf (to a path with no leading '/') if these
# depart from '=~' and 'conf/lighttpd.conf' respectively.
#
# This script sets a 'server-root' var inside each conditional to be equal to the
# matched path
#

#
# your config
#
Config = {
  :vhost => {
    :path  => '/var/www/vhosts/:vhost:',
    :host  => '(^|www\.):vhost:'
  },
  :subdomain => {
    :path  => '/var/www/vhosts/:vhost:/subdomains/:subdomain:',
    :match => '==',
    :host  => ':subdomain:.:vhost:'
  }
}

#
# defaults
#
Defaults = {
  :conf  => 'conf/lighttpd.conf',
  :match => '=~'
}

# Returns a hash of conf files mathcing the pattern, with the named parts in hash as the value
# pattern is in the form /var/www/:vhost:/foo
#
# e.g find_confs('/var/www/vhosts/:vhost:/subdomains/:subdomain/conf/lighttpd.conf') will return something like:
#   {'/var/www/vhosts/example.com/subdomains/blog/conf/lighttpd.conf' => {'vhost' => 'example.com', 'subdomain' => 'blog'}}
#
def find_hosts(pattern, config)
  glob   = pattern.gsub(/:\w+:/, '*') + "/" + config[:conf]
  regexp = Regexp.new(glob.gsub('*', '(.*)'))
  parts  = pattern.scan(/:\w+:/).collect {|p| p.gsub(':', '')}
  confs  = {}

  Dir[glob].each do |path|
    match = path.match(regexp).to_a
    root = match.shift.sub('/' + config[:conf], '')
    confs[root] = parts_conf = {}
    parts.each {|part| parts_conf[part.to_sym] = match.shift}
  end
  confs
end

def print_host_conf(host_path, host_spec, config)
  print "$HTTP[\"host\"] #{config[:match]} \"#{host_spec}\" {\n"
  print "  var.host-root = \"#{host_path}\"\n"
  IO.readlines("#{host_path}/#{config[:conf]}").each {|l| print "  #{l}"}
  print "}\n"
end

def build_host_spec(parts, config)
  host_spec = config[:host].dup  
  parts.each do |key, val|
    val = Regexp.escape(val) if config[:match] == '=~'
    host_spec.gsub!(":#{key}:", val)
  end
  host_spec
end

def print_host_confs(config)
  find_hosts(config[:path], config).each do |host_path, parts|
    host_spec = build_host_spec(parts, config)
    print_host_conf(host_path, host_spec, config)
  end
end

# main 
Config.each {|_,config| print_host_confs(Defaults.merge(config)) }
