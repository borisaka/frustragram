require 'rails_helper'
require 'digest'
#TODO make json wrapper to results


RSpec.describe ApiController, :type => :controller do
  describe "POST #media" do
    it "errors with wrong content type" do
      post :media
      expect(response).to have_http_status (417)
      expect(response.body).to eq ({error: {code: 30, message: 'Content type "application/json is required"'}}.to_json)
    end

    it "store media data" do
      dig_secret = Digest::SHA1.hexdigest Rails.application.credentials[:client_secret]
      dt = DateTime.now.to_time.to_i
      sig = Digest::SHA1.hexdigest "#{dig_secret}#{dt}"
      fake_media= {
          link: "http://example.com/123",
          thumb_url: "http://example.com/ex.png",
          small_url: "http://example.com/ex.png",
          big_url: "http://example.com/ex.png",
          uid: "123",
          tags: ["pain", "frustration", "linux"],
      }

      secured = {data: {
          media: fake_media,
          secure: {
              time: dt,
              sig: sig
          }
        }
      }
      request.headers["Content-Type"] = "application/json"
      request.env["HTTP_ACCEPT"] = "application/json"
      post :media, secured
      expect(response.body).to eq( {id: fake_media[:uid], message: 'Media was succesfully created'}.to_json)
      expect(response).to have_http_status (201)
      #post :media, data: secured
      #expect(response).to have_http_status (403)
      Media.where({uid:"123"}).delete

    end

    context "Security" do
      before(:each) do
        request.headers["Content-Type"] = "application/json"
        request.env["HTTP_ACCEPT"] = "application/json"
      end

      it "fails with wrong or missing secure" do
        post :media, data: {media: {}}
        expect(response).to have_http_status (403)
        expect(response.body).to eq ({error: {code:20, message: 'Auth signature is missing'}}.to_json)

      end

      it "fails with missing sig or time" do
        #request.env["RAW_POST_DATA"] = {media:{}, secure:{sig: "234234234"}}.to_json
        post :media, data:  {media:{}, secure:{sig: "234234234"}}
            # puts response.body.inspect
        expect(response).to have_http_status (403)
        expect(response.body).to eq ({error: {code:21, message: 'Wrong auth signature'}}.to_json)
      end

      it "fails with time older then 30 seconds" do
        dig_secret = Digest::SHA1.hexdigest Rails.application.credentials[:client_secret]
        dt = 24.hours.ago.to_time.to_i
        sig = Digest::SHA1.hexdigest "#{dig_secret}#{dt}"
        post :media, data: {media: {}, secure: {sig: sig, time: dt}}
        expect(response.body).to eq ({error: {code: 22, message: 'Auth signature is expired'}}.to_json)
      end

      it "fails with wrong sig" do
        dig_secret = Digest::SHA1.hexdigest Rails.application.credentials[:client_secret]+"abc"
        dt = DateTime.now.to_time.to_i
        sig = Digest::SHA1.hexdigest "#{dig_secret}#{dt}"
        post :media, data: {media: {}, secure: {sig: sig, time: dt}}
        expect(response.body).to eq ({error: {code:21, message: 'Wrong auth signature'}}.to_json)
      end

    end


  end
end
