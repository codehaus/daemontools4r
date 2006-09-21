
require 'fileutils'

module Daemontools4r
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
            names << child_path.sub( /^#{@root}\//, '' )
            dir_paths << child_path
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

    def remove_service(name)
      throw RuntimeError.new( "invalid service #{name}" ) if ! File.directory?( @root + '/' + name )
      service = self[name]
      `cd #{@root}/#{name} && rm #{File.expand_path(@root)}/#{name} && svc -dx .`
    end

  end

  class Service
    def initialize(tree,name)
      @tree = tree
      @name = name
    end

    def tree
      @tree
    end

    def name
      @name
    end

    def path
      @tree.root + '/' + name 
    end

    def svok?
      output = `svok #{path}`
      result = $?
      result == 0
    end

    def can_desupervise?
      File.symlink? path
    end

    def svc(opt_sym)
      opt = SVC_OPTS[ opt_sym.to_s.downcase.to_sym ]
      throw RuntimeError.new( "unknown opt '#{opt_sym}'" ) unless opt
      `svc -#{opt} #{path}` 
    end

    def svstat
      `svstat`
    end

    def down?
      svstat.split( ' ' )[1] == 'down'
    end

    def up?
      svstat.split( ' ' )[1] == 'up'
    end

  end

end
