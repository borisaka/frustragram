class Media
  include Mongoid::Document
  include Mongoid::Timestamps
  paginates_per 20
  field :link, type: String
  field :big_url, type: String
  field :small_url, type: String
  field :thumb_url, type: String
  field :uid, type: String
  field :voters, type: Array,default: []
  field :tags, type: Array, default: []

  index({:uid => 1}, {unique: true })

  def media_params
    params.permit(:link,:big_url,:small_url,:thumb_url,:uid,:tags)
  end
end
