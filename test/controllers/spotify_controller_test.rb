require 'test_helper'

class SpotifyControllerTest < ActionController::TestCase
  test "should get playlists" do
    get :playlists
    assert_response :success
  end

end
