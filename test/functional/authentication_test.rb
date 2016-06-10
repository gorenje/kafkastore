# encoding: UTF-8
require_relative '../test_helper'

class AuthenticaionTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('config.ru').first
  end

  def setup
  end

  context "authentication" do
    should "prevent access" do
      ["/sidekiq", "/auth", '/badclicks', '/badclicks/clear_all', '/'
       ].each do |path|
        get path
        assert_redirect_to("auth/google_oauth2", "Failed for #{path}")
      end
    end

    should "allow access" do
      ["/pingdom"].
        each do |path|
        get path
        assert last_response.ok?, "Failed for #{path}"
      end
    end

    should "redirect to google" do
      lgr = Object.new.tap do |o|
        mock(o).info("(google_oauth2) Request phase initiated.") { }
      end
      mock(OmniAuth).logger { lgr }

      get "/auth/google_oauth2"

      assert(last_response.headers["Location"] =~ /https:\/\/accounts.google.com\/o\/oauth2\/auth\?access_type=offline/)
    end
  end
end
