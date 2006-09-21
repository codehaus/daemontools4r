
require 'daemontools4r'
require 'fileutils'
require 'pp'

require 'test/unit'

class Daemontools4rTest < Test::Unit::TestCase

  def setup()
    @svscan_pid = nil
    FileUtils.mkdir_p tmp_service_dir
    FileUtils.mkdir_p tmp_service_real_dir
  end

  def teardown()
    FileUtils.rm_rf tmp_service_dir
    FileUtils.rm_rf tmp_service_real_dir
  end

  def test_service_names()
    tree = Daemontools4r::ServiceTree.new( service_dir )
    service_names = tree.service_names
    assert_equal 4, service_names.size
    assert service_names.include?( 'service-1' )
    assert service_names.include?( 'service-1/log' )
    assert service_names.include?( 'service-2' )
    assert service_names.include?( 'service-3' )
    assert ! service_names.include?( 'nonservice-1' )
  end

  def test_services()
    tree = Daemontools4r::ServiceTree.new( service_dir )
    services = tree.services
    assert_equal 4, services.size
    services.each do |s|
      assert_same tree, s.tree
    end
    service_names = services.collect{|s|s.name}
    assert service_names.include?( 'service-1' )
    assert service_names.include?( 'service-1/log' )
    assert service_names.include?( 'service-2' )
    assert service_names.include?( 'service-3' )
    assert ! service_names.include?( 'nonservice-1' )
  end

  def test_service_indexing()
    tree = Daemontools4r::ServiceTree.new( service_dir )
    service = tree['service-1']
    assert_not_nil service
    service = tree['service-1/log']
    assert_not_nil service
    service = tree['non-service-1']
    assert_nil service
  end

  def test_can_desupervise()
    tree = Daemontools4r::ServiceTree.new( service_dir )
    service = tree['service-1']
    assert service.can_desupervise?
    service = tree['service-3']
    assert ! service.can_desupervise?
  end

  def test_build_service()
    service = Daemontools4r.build_service( service_template_dir + '/flapping-app', tmp_service_real_dir + '/flapping-1' )
    assert File.exists?( tmp_service_real_dir + '/flapping-1/run' )
  end

  def test_svscan()
    svscan( tmp_service_dir ) do
      sleep( 3 )
    end
  end

  def test_svok()
    service_path = Daemontools4r.build_service( service_template_dir + '/flapping-app', tmp_service_real_dir + '/flapping-1' )
    
    svscan( tmp_service_dir ) do
      tree = Daemontools4r::ServiceTree.new( tmp_service_dir )
      assert_equal 0, tree.service_names.size
      service = tree.add_service( 'flapping-1-svc', service_path )
      assert_not_nil service
      assert service.svok?
      tree.remove_service( 'flapping-1-svc' )
      assert_equal 0, tree.service_names.size
    end
  end

  private

  def svscan(dir)
    begin
      start_svscan( dir )
      sleep( 2 )
      yield if block_given?
    ensure
      stop_svscan
    end
  end
  
  def service_dir
    File.dirname( __FILE__ ) + '/../test-data/service'
  end

  def service_real_dir
    File.dirname( __FILE__ ) + '/../test-data/service-real'
  end

  def service_template_dir
    File.dirname( __FILE__ ) + '/../test-data/service-template'
  end

  def tmp_service_dir
    File.dirname( __FILE__ ) + '/../tmp/service'
  end

  def tmp_service_real_dir
    File.dirname( __FILE__ ) + '/../tmp/service-real'
  end

  def start_svscan(dir)
    @svscan_dir = dir
    @svscan_pid = Process.fork {
      exec '/bin/bash',  '-c', "exec svscan #{dir}", '2>&1'
    }
  end

  def stop_svscan()
    return unless @svscan_pid
    return if @svscan_pid == Process.pid
    glob = File.expand_path(@svscan_dir) + '/*'
    `svc -dx #{glob}`
    Process.kill( 'INT', @svscan_pid ) 
    Process.wait( @svscan_pid )
    @svscan_pid = nil
    sleep( 5 )
  end

end
