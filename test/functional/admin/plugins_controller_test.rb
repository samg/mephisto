require File.dirname(__FILE__) + '/../../test_helper'

class Admin::PluginsControllerTest < Test::Unit::TestCase
  fixtures :contents, :content_versions, :sections, :assigned_sections, :users, :sites, :tags, :taggings, :memberships
  @@test_plugin_dir = RAILS_PATH + 'test/fixtures/plugins/lib'
  @@plugin_dir      = RAILS_PATH + 'vendor/plugins/mephisto_test_plugin'
  @@plugin_lib_dir  = @@plugin_dir + 'lib'

  def setup
    @controller = Admin::PluginsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    #here we create a temporary and simple plugin 
    FileUtils.mkdir_p(@@plugin_dir)
    FileUtils.cp_r @@test_plugin_dir, @@plugin_dir
    $LOAD_PATH << @@plugin_lib_dir.to_s
    load @@plugin_lib_dir + 'test_plugin.rb'
  end

  def teardown
    $LOAD_PATH.delete @@plugin_lib_dir.to_s
    FileUtils.rm_rf(@@plugin_dir)
  end

  def test_should_not_allow_site_admin_access_to_plugins
    login_as :arthur
    get :index
    assert_redirected_to :controller => '/account', :action => 'login'
  end
  
  def test_should_not_allow_site_member_access_to_plugins
    login_as :ben
    get :index
    assert_redirected_to :controller => '/account', :action => 'login'
  end

  def test_should_allow_globl_admin_access_to_plugins
    login_as :quentin
    get :index
    assert_response :success
  end

  def test_should_allow_global_admin_access_to_plugin
    login_as :quentin
    get :show, :id => 'test_plugin'
    assert_response :success
  end

  def test_should_list_plugins
    login_as :quentin
    get :index
    assert_response :success
    test_dir_plugin = assigns(:plugins).detect { |p| p.path == 'test_plugin' }
    assert test_dir_plugin.configurable?, "Test Plugin is not configurable!"
  end

  def test_should_show_plugin
    login_as :quentin
    assert_not_nil Mephisto::Plugins::TestPlugin.new
    get :show, :id => 'test_plugin'
    assert_response :success
  end

  def test_should_update_plugin_options
    login_as :quentin
    put :update, :id => 'test_plugin', :options => { :notes => 'foo bar' }
    assert_redirected_to :action => "show"
    assert_equal "foo bar", assigns(:plugin).notes
  end

  def test_should_delete_plugin
    login_as :quentin
    test_should_update_plugin_options
    delete :destroy, :id => 'test_plugin'
    assert_redirected_to :action => "show"

    # weird, in the below the assigns hash holds the plugin object from delete
    # not the second plugin reloaded from show. So I suppose assigns is built by
    # the get.
    # I'd like to work out a way to access the plugin object reloaded in the 302 show.
    #
    # TODO: Convert to integration test for this
    #
    plugin = assigns["plugin"]
    assert_equal "test", plugin.config["one"]
  end
end
