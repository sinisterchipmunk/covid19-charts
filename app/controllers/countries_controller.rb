class CountriesController < ApplicationController
  before_action :set_country, only: [:show, :edit, :update, :destroy]

  # GET /countries
  # GET /countries.json
  def index
    countries = params[:china] ? Country.all : Country.where.not(name: 'China')
    @countries = Rails.cache.fetch [params[:start_date], countries] do
      countries.sort do |a, b|
        b.reports.starting(@start_date).sum(:cases) <=>
        a.reports.starting(@start_date).sum(:cases)
      end
    end
  end

  def heatmap
    # @start_date = 3.weeks.ago.to_date
    @countries = Rails.cache.fetch(['heatmap', 'countries', Report.maximum(:reported_at), params[:china], params[:start_date]]) do
      countries.to_a.select do |c|
        c.reports.starting(@start_date).any?
      end.sort do |a,b|
        # i = a.reports.where('reported_at > ?', @start_date).first.reported_at <=> b.reports.where('reported_at > ?', @start_date).first.reported_at
        i = b.reports.group('date(reported_at)').count.size <=> a.reports.group('date(reported_at)').count.size
        j = b.reports.starting(@start_date).sum(:cases) <=> a.reports.starting(@start_date).sum(:cases)
        i == 0 ? j : i
      end
    end
    # @countries = @countries[0...40]
    @dates = Report.starting(@start_date).pluck(:reported_at).map(&:to_date).uniq.sort
    @metric = :cases
  end

  def cumulative
    @reports = countries.reports.where("reported_at >= ?", @start_date)
    render :stacked
  end

  def acceleration
    if params[:id]
      @country = Country.find params[:id]
      @reports = @country.reports.starting(@start_date).group('date(reported_at)')
    else
      @reports = countries.reports.starting(@start_date).group('date(reported_at)')
    end
  end

  def cfr
    if params[:id]
      @country    = Country.find params[:id]
      @cases      = @country.reports.starting(@start_date).group('date(reported_at)').sum(:cases)
      @deaths     = @country.reports.starting(@start_date).group('date(reported_at)').sum(:deaths)
      @recoveries = @country.reports.starting(@start_date).group('date(reported_at)').sum(:recovered)
    else
      @cases      = countries.reports.starting(@start_date).group('date(reported_at)').sum(:cases)
      @deaths     = countries.reports.starting(@start_date).group('date(reported_at)').sum(:deaths)
      @recoveries = countries.reports.starting(@start_date).group('date(reported_at)').sum(:recovered)
    end
  end

  # GET /countries/1
  # GET /countries/1.json
  def show
  end

  def totals
    @country = Country.find params[:id]
    @reports = Country.find(params[:id]).reports.starting(@start_date)
    render :stacked
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_country
      @country = Country.find(params[:id])
    end
end
