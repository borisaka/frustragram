class ApiController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :content_type_json, :secure
  def media
    Rails.logger.debug (request.params["data"]["media"])
    if Media.where({uid: request.params["data"]["media"]["uid"]}).count > 0
      response.status = :error
      render json: {error: {code: 10, message: 'This media is already exists'}}
    else
      media = Media.create! request.params["data"]["media"]
      response.status = :created
      render json: created(media.uid)
    end
  end

  private

  #only content-type JSON is acceped, becouse is simple to handle in Rails
  def content_type_json
    unless request.headers["Content-Type"] == "application/json"
      response.status = :expectation_failed
      render json: wrong_content_type
    end
  end

  def secure
    require 'digest'
    #without secure pbject
    puts params.inspect
    unless params.key? "data"
      response.status = 500
      render json: wrong_parameters
    end
    js_args = params["data"]
    if !js_args.key?("secure")
      response.status = :forbidden
      render json: missing_signature
    elsif !js_args["secure"].key?("sig") || !js_args["secure"].key?("time")
      response.status = :forbidden
      render json: wrong_signature
    else
      client_time = js_args["secure"]["time"]
      if Time.at(client_time.to_i) < 1.day.ago
        response.status = :forbidden
        render json: expired_signature
      else
        client_sig = js_args["secure"]["sig"]
        dig_secret = Digest::SHA1.hexdigest Rails.application.credentials[:client_secret]
        true_sig = Digest::SHA1.hexdigest "#{dig_secret}#{client_time}"
        unless client_sig == true_sig
          response.status = :forbidden
          render json: wrong_signature
        end
      end
    end
  end

  def client_secret
    Rails.application.credentials[:client_secret]
  end

  def created uid
    {id: uid, message: 'Media was succesfully created'}
  end

  def already_exists
    {error: {code: 10, message: 'This media is already exists'}}
  end

  def wrong_parameters
    {error: {code: 11, message: 'Wrong parameters'}}
  end

  def missing_signature
    {error: {code:20, message: 'Auth signature is missing'}}
  end

  def wrong_signature
    {error: {code:21, message: 'Wrong auth signature'}}
  end

  def expired_signature
    {error: {code: 22, message: 'Auth signature is expired'}}
  end

  def wrong_content_type
    {error: {code: 30, message: 'Content type "application/json is required"'}}
  end


end
