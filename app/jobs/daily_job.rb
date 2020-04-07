require 'csv'

class DailyJob < ApplicationJob
  queue_as :default

  def perform(*args)
    if File.exist?(Rails.root.join('data/COVID-19'))
      Dir.chdir Rails.root.join('data/COVID-19') do
        raise "could not checkout branch" unless system "git", "checkout", "origin/web-data"
        raise "could not update data set" unless system "git", "pull", "origin", "web-data"
      end
    else
      FileUtils.mkdir_p(Rails.root.join('data'))
      Dir.chdir Rails.root.join('data') do
        raise "could not clone repo" unless system "git", "clone", "https://github.com/CSSEGISandData/COVID-19"
        Dir.chdir Rails.root.join('data/COVID-19') do
          raise "could not checkout branch" unless system "git", "checkout", "origin/web-data"
        end
      end
    end

    Report.transaction do
      missing_countries = []
      prev_reports = {}
      avg = {}
      Report.delete_all
      CSV.parse(File.open(Rails.root.join('data/COVID-19/data/cases_time.csv'), 'r'), headers: true) do |row|
        row = row.to_hash
        # special case country names
        country_name = row['Country_Region']
        country_name.gsub! /\*/, ''
        country_name = case country_name
                       when 'Korea, South'                   then 'South Korea'
                       when 'Republic of Korea'              then 'South Korea'
                       when 'Viet Nam'                       then 'Vietnam'
                       when 'Iran (Islamic Republic of)'     then 'Iran'
                       when 'Hong Kong SAR'                  then 'Hong Kong'
                       when 'Mainland China'                 then 'China'
                       when 'US'                             then 'United States'
                       when 'UK'                             then 'United Kingdom'
                       when 'North Ireland'                  then 'Northern Ireland'
                       when 'Republic of Ireland'            then 'Ireland'
                       when 'Saint Martin'                   then 'St. Martin'
                       when 'Taipei and environs'            then 'Taiwan'
                       when 'Macao SAR'                      then 'Macau'
                       when 'occupied Palestinian territory' then 'Palestine'
                       when 'The Gambia'                     then 'Gambia'
                       when 'Gambia, The'                    then 'Gambia'
                       when 'The Bahamas'                    then 'Bahamas'
                       when 'Bahamas, The'                   then 'Bahamas'
                       when 'Republic of the Congo'          then 'DR Congo'
                       when 'Congo (Brazzaville)'            then 'DR Congo'
                       when 'Guernsey'                       then 'Guernsey and Jersey'
                       when 'Jersey'                         then 'Guernsey and Jersey'
                       when 'Russian Federation'             then 'Russia'
                       when 'Republic of Moldova'            then 'Moldova'
                       when "Congo (Kinshasa)"               then 'DR Congo'
                       when 'Czechia'                        then 'Czech Republic'
                       when "Cote d'Ivoire"                  then 'Ivory Coast'
                       when 'Curacao'                        then 'Curaçao'
                       when 'Reunion'                        then 'Réunion'
                       when 'Cabo Verde'                     then 'Cape Verde'
                       when 'Timor-Leste'                    then 'East Timor'
                       when 'Diamond Princess'               then 'Cruise Ship'
                       when 'West Bank and Gaza'             then 'Palestine'
                       when 'Burma'                          then 'Myanmar'
                       when 'MS Zaandam'                     then 'MS Zaandam (Cruise Ship)'
                       when 'Sao Tome and Principe'          then 'São Tomé and Príncipe'
                       else country_name
                       end
        country = Country.where(name: country_name).first
        if !country
          unless missing_countries.include?(country_name)
            missing_countries << country_name
            warn "Country not found: #{country_name.inspect}"
          end
          next
        end

        prev_report = prev_reports[country.id] ||= country.reports.build
        report = country.reports.build reported_at: DateTime.strptime(row['Last_Update'], '%m/%d/%y'),
                                       cum_cases: row['Confirmed'].to_i,
                                       cum_deaths: row['Deaths'].to_i,
                                       cum_recovered: row['Recovered'].to_i,
                                       cases: row['Delta_Confirmed'].to_i,
                                       deaths: row['Deaths'].to_i - prev_report.cum_deaths.to_i,
                                       recovered: row['Delta_Recovered'].to_i,
                                       accel_cases: row['Delta_Confirmed'].to_i - prev_report.cases.to_i,
                                       accel_deaths: (row['Deaths'].to_i - prev_report.cum_deaths.to_i) - prev_report.deaths.to_i,
                                       accel_recovered: row['Delta_Recovered'].to_i - prev_report.recovered.to_i
        prev_reports[country.id] = report

        report.save!
      end

      raise 'one or more countries is missing' if missing_countries.any?

      # cache busting and cleanup
      Country.touch_all
    end
  end
end
