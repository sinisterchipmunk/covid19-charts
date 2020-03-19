json.extract! report, :id, :reported_at, :country_id, :cases, :deaths, :created_at, :updated_at
json.url report_url(report, format: :json)
