
require 'fileutils'

module Daemontools4r
  #Make sure there's a trailing slash
  DAEMONTOOLS_PATH = '/package/admin/daemontools/command/'
  
  SVC_OPTS = {
    :u=>'u', :up=>'u',
    :d=>'d', :down=>'d',
    :o=>'o', :once=>'o',
    :p=>'p', :pause=>'p', :stop=>'p',
    :c=>'c', :continue=>'c', :cont=>'c',
    :h=>'h', :hangup=>'h', :hup=>'h',
    :a=>'a', :alarm=>'a', :alrm=>'a',
    :i=>'i', :interrupt=>'i', :int=>'i',
    :t=>'t', :terminate=>'t', :term=>'t',
    :k=>'k', :kill=>'k',
    :x=>'x', :exit=>'x',
  }

  def self.build_service(template_path, output_path, variables={})
    throw RuntimeError.new( "output path #{output_path} exists" ) if ( File.exist? output_path )
    FileUtils.cp_r( template_path, output_path )
    FileUtils.mkdir_p( output_path + '/user_env' ) unless variables.empty?
    variables.each do |key, value|
      File.open( output_path + "/user_env/#{key.to_s.upcase}", 'w' ) do |file|
        file.puts value
      end
    end
    File.chmod( 0755, output_path + '/run' ) if File.exist?( output_path + '/run' )
    File.chmod( 0755, output_path + '/log/run' ) if File.exist?( output_path + '/log/run' )
    output_path
  end

  class ServiceTree

    def initialize(root='/service')
      @root = root
    end

    def root
      @root
    end

    def service_names
      names = []
      dir_paths = []
      dir_paths << @root
      while ( dir_path = dir_paths.shift ) 
        dir = Dir.new( dir_path )
        dir.each do |child|
          next if ( child == '.' || child == '..' )
          child_path = dir_path + '/' + child
          if ( File.directory?( child_path ) )
            if ( ! ( child.to_s =~ /^\./ ) )
              names << child_path.sub( /^#{@root}\//, '' )
              dir_paths << child_path
            end
          end
        end
      end
      names
    end

    def services
      service_names.collect{|name| Service.new(self,name)}
    end

    def [](name)
      path = @root + '/' + name
      if ( File.directory?( path ) )
        Service.new( self, name )
      end
    end

    def add_service(name, service_path)
      throw RuntimeError.new( "service #{name} in use" ) if File.exist?( @root + '/' + name )
      File.symlink( File.expand_path( service_path ), @root + '/' + name )
      service = Service.new( self, name )
      1.upto( 10 ) do |i|
        return service if service.svok? 
        sleep( 1 )
      end
      return service
    end

    def remove_service(name,kill_after=60)
      throw RuntimeError.new( "invalid service #{name}" ) if ! File.directory?( @root + '/' + name )
      service = self[name]
      extra = ''
      if ( File.directory?( @root + '/' + name + '/log' ) )
        extra = '&& sudo #{DAEMONTOOLS_PATH}svc -dx ./log'
      end
      service.down! kill_after
      `cd #{@root}/#{name} && rm #{File.expand_path(@root)}/#{name} && sudo #{DAEMONTOOLS_PATH}svc -dx . #{extra}`
    end

  end

  class Service
    def initialize(tree,name,normal_state=:up)
      @tree = tree
      @name = name
      @normal_state = normal_state
    end

    def tree
      @tree
    end

    def name
      @name
    end

    def remove
      @tree.remove_service( name )
    end

    def normal_state
      @normal_state
    end

    def normal_state=(state)
      @normal_state = state
    end

    def path
      @tree.root + '/' + name 
    end

    def svok?
      output = `sudo #{DAEMONTOOLS_PATH}svok #{path}`
      result = $?
      result == 0
    end

    def can_desupervise?
      File.symlink? path
    end

    def svc(opt_sym)
      opt = SVC_OPTS[ opt_sym.to_s.downcase.to_sym ]
      throw RuntimeError.new( "unknown opt '#{opt_sym}'" ) unless opt
      cmdline = "sudo #{DAEMONTOOLS_PATH}svc -#{opt} #{path}"
      puts "CMD: #{cmdline}"
      `#{cmdline}`
    end

    def down(wait_for=true)
      svc :d
      1.upto( 10 ) do |i|
        return if down?
        sleep( 1 )
      end
    end

    def down!(kill_after=60)
      svc :d
      start = Time.now.to_i
      while ( true )
        return if down?
        if ( (Time.now.to_i - start) >= kill_after )
          svc :k
          kill_start = Time.now.to_i
          while ( true )
            return if down?
            if ( (Time.now_to_i - kill_start) >= kill_after )
              throw RuntimeError.new( "service not down" )
            end
            sleep( 1 )
          end
        end
        sleep( 1 )
      end
    end

    def svstat
      stat = `sudo #{DAEMONTOOLS_PATH}svstat #{path}`
      pp stat
      stat
    end

    def down?
      svstat.split( ' ' )[1] == 'down'
    end

    def up?
      svstat.split( ' ' )[1] == 'up'
    end

    def want_up?
      svstat =~ /want up/
    end

    def want_down?
      svstat =~ /want down/
    end

  end

end
