Geokit::Geocoders::NominatimGeocoder.server = 'open.mapquestapi.com/nominatim/v1/search?key=cYOondyn4ktJAf7frbiVD5jkdGNASuf0'

Epm::Application.configure do
  config.geokit.default_units = :kms
  config.geokit.geocoders.provider_order = [:nominatim, :google]
end