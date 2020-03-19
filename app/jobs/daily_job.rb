require 'csv'

class DailyJob < ApplicationJob
  queue_as :default

  def perform(*args)
    if File.exist?(Rails.root.join('data/COVID-19'))
      Dir.chdir Rails.root.join('data/COVID-19') do
        raise "could not update data set" unless system "git", "pull"
      end
    else
      FileUtils.mkdir_p(Rails.root.join('data'))
      Dir.chdir Rails.root.join('data') do
        raise "could not clone repo" unless system "git", "clone", "https://github.com/CSSEGISandData/COVID-19"
      end
    end
    cases = {}
    deaths = {}
    recoveries = {}
    all_rows = []
    Dir[Rails.root.join('data/COVID-19/csse_covid_19_data/csse_covid_19_daily_reports/*.csv')].sort.each do |csv|
      rows = CSV.new(File.open(csv, 'r'), headers: true).map do |row|
        row = row.to_hash
        if row['Last Update'][/\//]
          if row['Last Update'][/\/20(?:[^\d]|$)/]
            date = DateTime.strptime(row['Last Update'], '%m/%d/%y %H:%M')
          else
            date = DateTime.strptime(row['Last Update'], '%m/%d/%Y %H:%M')
          end
        else
          date = DateTime.strptime(row['Last Update'], '%Y-%m-%dT%H:%M:%S')
        end

        # This looks like reporting (human) error - all of the dates on 3/12 and 3/13
        # are entered as 3/11. No idea if times are accurate. Let's assume the filename
        # has the correct date since otherwise we end up with big gaps.
        # Seems this error occurs on other days as well. Just assume filenames are
        # always authoritative in terms of date.
        real_date = File.basename(csv, '.csv')
        date = DateTime.strptime("#{real_date}T#{date.strftime('%H:%M:%S')}",
                                 '%m-%d-%YT%H:%M:%S')
        # if date.month == 3
        #   if date.day == 11
        #     real_date = File.basename(csv, '.csv')
        #     p real_date
        #     if ['03-12-2020', '03-13-2020'].include? real_date
        #       date = DateTime.strptime(p("#{real_date}T#{date.strftime('%H:%M:%S')}"),
        #                                '%m-%d-%YT%H:%M:%S')
        #       p date
        #     end
        #   end
        # end

        row.delete('Latitude')
        row.delete('Longitude')
        row['Last Update'] = date
        row
      end
      all_rows.concat rows
    end

    all_rows.sort! do |a, b|
      x = a['Last Update'] <=> b['Last Update']
      # sometimes we have 2 records with same timestamp - if that happens, order
      # by case count descending so that subsequent ones can be skipped.
      if x == 0
        b['Confirmed'].to_i <=> a['Confirmed'].to_i
      else
        x
      end
    end

    Report.transaction do
      Report.delete_all
      all_rows.uniq.each do |row|
        date = row['Last Update']
        province_name = row[row.keys.detect { |k| k[/Provinc/] }]
        province_name&.strip!
        country_name = row['Country/Region'].strip

        # special case country names
        country_name.gsub! /\*/, ''
        country_name = 'South Korea' if country_name == 'Korea, South'
        country_name = 'South Korea' if country_name == 'Republic of Korea'
        country_name = 'Vietnam'     if country_name == 'Viet Nam'
        country_name = 'Iran'        if country_name == 'Iran (Islamic Republic of)'
        country_name = 'Hong Kong'   if country_name == 'Hong Kong SAR'
        country_name = 'China'       if country_name == 'Mainland China'

        country = Country.where(name: country_name).first_or_create!
        province = Province.where(name: province_name,
                                  country: country).first_or_create!
        row['province_id'] = province.id
        
        # longitude: row['Longitude'],
        # latitude: row['Latitude']

        # don't process a report already processed
        report = province.reports.where(reported_at: date)
                                 .first_or_initialize(country: country)
        # CSV contains total counts, we prefer deltas, so need to solve for that.
        report.cases     = row['Confirmed'].to_i - cases[province.id].to_i
        report.deaths    = row['Deaths'].to_i    - deaths[province.id].to_i
        report.recovered = row['Recovered'].to_i - recoveries[province.id].to_i
        next if report.cases == 0 && report.deaths == 0 && report.recovered == 0
        next if report.cases < 0
        # p [country.id, province.id, cases[province.id], report.cases, row['Last Update'].to_f, row] if country.name[/Korea/]
        cases[province.id] = row['Confirmed'].to_i
        deaths[province.id] = row['Deaths'].to_i
        recoveries[province.id] = row['Recovered'].to_i
        report.save!

        # sanity check
        sum = province.reports.where("reported_at <= ?", report.reported_at).sum(:cases)
        unless sum == row['Confirmed'].to_i
          raise "Sum mismatch: #{sum} != #{row.inspect} (#{country.id} => #{report.cases})"
        end
      end

      # cache busting and cleanup
      Country.all.each do |c|
        if c.reports.empty?
          c.destroy
        else
          c.touch
        end
      end
    end
  end
end
