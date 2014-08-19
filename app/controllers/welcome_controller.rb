class WelcomeController < ApplicationController
  def index
    @media = Media.all.desc(:created_at).page params[:page]
  end
end
