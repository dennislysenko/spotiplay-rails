require 'test_helper'

class GoogleControllerTest < ActionController::TestCase
  test "should get playlists" do
    get :playlists
    assert_response :success
  end

  test "should get playlist_entries" do
    get :playlist_entries
    assert_response :success
  end

end
