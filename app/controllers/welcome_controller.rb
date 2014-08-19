class WelcomeController < ApplicationController
  def index
    @media = Media.all.asc(:created_at).page params[:page]
  end
end
