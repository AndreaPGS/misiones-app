# frozen_string_literal: true

class Admin::RankingController < Admin::ApplicationController
  def index
    @ranked_guests = Guest.order(points: :desc, name: :asc)
  end
end
