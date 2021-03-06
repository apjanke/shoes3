require 'fileutils'
include FileUtils
# download.rb monkey patches Shoes download -replaces curl
require_relative 'download.rb'
# locate ~/.shoes
require 'tmpdir'
#require 'rubygems' # Loads a Gem class

lib_dir = nil
homes = []
homes << [ENV['LOCALAPPDATA'], File.join( ENV['LOCALAPPDATA'], 'Shoes')] if ENV['LOCALAPPDATA']
homes << [ENV['APPDATA'], File.join( ENV['APPDATA'], 'Shoes' )] if ENV['APPDATA']
homes << [ENV['HOME'], File.join( ENV['HOME'], '.shoes' )] if ENV['HOME']
homes.each do |home_top, home_dir|
  next unless home_top
  if File.exists? home_top
    lib_dir = home_dir
    break
  end
end
LIB_DIR = lib_dir || File.join(Dir::tmpdir, "shoes")
#LIB_DIR.gsub! /\\/, '\/'
#LIB_DIR.gsub! /\\+/, "/"
LIB_DIR.gsub!(/\\/, '/') # should not be needed? 

tight_shoes = Shoes::RELEASE_TYPE =~ /TIGHT/
rbv = RbConfig::CONFIG['ruby_version']
if tight_shoes 
  #require 'rbconfig'
  SITE_LIB_DIR = File.join(LIB_DIR, '+lib')
  GEM_DIR = File.join(LIB_DIR, '+gem')
  $:.unshift SITE_LIB_DIR
  $:.unshift GEM_DIR
  ENV['GEM_HOME'] = GEM_DIR
  np = []
  ENV['PATH'].split(':').each do |p|
    np << p unless p =~ /(\.rvm)|(\.rbenv)/
  end
  ENV['PATH'] = np.join(':')
  $stderr.puts "replaced $PATH with #{ENV['PATH']}"
else
  #puts "LOOSE Shoes #{RUBY_VERSION} #{DIR}"
  $:.unshift ENV['GEM_HOME'] if ENV['GEM_HOME']
  rv = case RUBY_VERSION
    when /1.9/
      '1.9.1'
    when /2.0.0/
      '2.0.0'
    when /2.1/
      '2.1.0'
    when /2.2/
      '2.2.0'
    when /2.3/
      '2.3.0'
    else
      RUBY_VERSION
  end
  $:.unshift DIR+"/lib/ruby/#{rv}/#{RbConfig::CONFIG['arch']}"
  $:.unshift DIR+"/lib/ruby/#{rv}"
  $:.unshift DIR+"/lib/shoes"
end

CACHE_DIR = File.join(LIB_DIR, '+cache')
mkdir_p(CACHE_DIR)
SHOES_RUBY_ARCH = RbConfig::CONFIG['arch']

if tight_shoes 
  #puts "Dir: #{DIR} #{RbConfig::CONFIG["oldincludedir"]}"
  incld = "#{DIR}/lib/ruby/include/ruby-1.9.1"
  config = {
	  'ruby_install_name' => "shoes --ruby",
	  'RUBY_INSTALL_NAME' => "shoes --ruby",
	  'prefix' => "#{DIR}", 
	  'bindir' => "#{DIR}", 
	  'rubylibdir' => "#{DIR}/lib/ruby",
	  'includedir' => incld,
	  'rubyhdrdir' => incld,
	  'vendorhdrdir' => incld,
	  'sitehdrdir' => incld,
	  'datarootdir' => "#{DIR}/share",
	  'dvidir' => "#{DIR}/doc/${PACKAGE}",
	  'psdir' => "#{DIR}/doc/${PACKAGE}",
	  'htmldir' => "#{DIR}/doc/${PACKAGE}",
	  'docdir' => "#{DIR}/doc/${PACKAGE}",
#	  'archdir' => "#{DIR}/ruby/lib/#{SHOES_RUBY_ARCH}",
	  'archdir' => "#{DIR}/lib/ruby/1.9.1/#{SHOES_RUBY_ARCH}",
	  'sitedir' => SITE_LIB_DIR,
	  'sitelibdir' => SITE_LIB_DIR,
	  'sitearchdir' => "#{SITE_LIB_DIR}/#{SHOES_RUBY_ARCH}",
	  'LIBRUBYARG_STATIC' => "",
	  'libdir' => "#{DIR}",
	  'LDFLAGS' => "-L. -L#{DIR}",
	  'rubylibprefix' => "#{DIR}/ruby"
  }
  RbConfig::CONFIG.merge! config
  RbConfig::MAKEFILE_CONFIG.merge! config
  # Add paths to Shoes builtin Gems TODO: may not be needed
  GEM_CENTRAL_DIR = File.join(DIR, 'lib/ruby/gems/' + RbConfig::CONFIG['ruby_version'])
  Dir[GEM_CENTRAL_DIR + "/gems/*"].each do |gdir|
    $: << "#{gdir}/lib"  # needed for OSX ?
  end
  #jloc = "#{ENV['HOME']}/.shoes/#{Shoes::RELEASE_NAME}/getoutofjail.card"
  jloc = File.join(LIB_DIR, Shoes::RELEASE_NAME, 'getoutofjail.card')
  #puts "Jailbreak location #{jloc}"
  # Jailbreak for Gems. Load them a from a pre-existing ruby's gems
  # or file contents
  if File.exist? jloc
    open(jloc, 'r') do |f|
      f.each do |l| 
        ln = l.strip
        $:.unshift ln if ln.length > 0
      end
    end
    if ENV['GEM_PATH']
      ENV['GEM_PATH'].split(':').each {|p| $:.unshift p }
    end
    require 'rubygems'
    ShoesGemJailBreak = true
  else
    if ENV['GEM_PATH']
      # replace GEM_PATH 
      ENV['GEM_PATH'] = "#{GEM_DIR}:#{GEM_CENTRAL_DIR}"
      Gem.use_paths(GEM_DIR, [GEM_DIR, GEM_CENTRAL_DIR])
      Gem.refresh
      $stderr.puts "GEM_PATH: #{ENV['GEM_PATH']}"
    end
    ShoesGemJailBreak = false
  end
else # Loose Shoes
  ShoesGemJailBreak = true
  # NOTE -  lib/shoes/setup.rb uses GEM_DIR and GEM_CENTRAL_DIR 
  #   GEM_DIR would point to ~/.shoes/+gem and we don't want that 
  #   GEM_CENTRAL_DIR points to Ruby's gems
  # TODO: assumes rvm or system ruby BUT system ruby could be RVM
  #       Doesn't deal with rbenv setups
  if ENV['GEM_HOME'] && ENV['GEM_HOME'] =~ /home\/.*\/.rvm/
	  GEM_CENTRAL_DIR = GEM_DIR =  ENV['GEM_HOME']
  else
    # here from a Menu launch of a loose shoes -- GEM_HOME, GEM_PATH do not exist
    # only minlin and minbsd can do this - they probably shouldn't attempt it, but still?
    # We guess where the gems are
    gp = ""  #path to rubygems internal store
    binloc = RbConfig::CONFIG['prefix']
    rbv = RbConfig::CONFIG['ruby_version']
    if binloc =~ /home\/.*\/.rvm/
      gp = "#{ENV['HOME']}/.rvm/gems/ruby-#{RUBY_VERSION}"
    elsif binloc =~ /\/usr\//
      # ruby is installed in system dirs - bsd? 
      gp = "#{binloc}/lib/ruby/gems/#{rbv}"
    else
      gp = "Missing"
    end
    #debug "Trying to use #{gp} and #{ip}"
    GEM_CENTRAL_DIR = GEM_DIR = gp # don't use ~/.shoes/+gem/
    Dir[GEM_CENTRAL_DIR + "/gems/*"].each do |gdir|
      #debug "adding to loadpath: #{gdir}"
      $: << "#{gdir}/lib"
    end
    Gem.use_paths(GEM_DIR, [GEM_DIR, GEM_CENTRAL_DIR])
    Gem.refresh
  end
end
# find vlc libs
require_relative 'vlcpath'
yamlp = File.join(LIB_DIR, Shoes::RELEASE_NAME, 'vlc.yaml')
Vlc_path.load yamlp
if ENV['GEM_HOME'] && !ShoesGemJailBreak
	$stderr.puts "Killing rvm in paths"
	$:.each do |p| 
	  if p =~ /(\.rvm)|(\.rbenv)/
			$:.delete(p)
		end
	end
end

