class ApplicationController < ActionController::Base
  before_action :set_start_date

  protected

  def set_start_date
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : 1.month.ago.to_date
  end

  def countries
    @countries ||= if params[:china]
                     Country.all
                   else
                     Country.where.not(name: ['Mainland China', 'China'])
                   end
  end
end
