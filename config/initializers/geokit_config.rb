Geokit::Geocoders::NominatimGeocoder.server = 'open.mapquestapi.com/nominatim/v1/search'
Geokit::Geocoders::MapQuestGeocoder.key = 'ZQMLdFHuE1gWLe3kCTgqhA3H6WfsG8Yg' #'cYOondyn4ktJAf7frbiVD5jkdGNASuf0'
Geokit::Geocoders::BingGeocoder.key = 'AtLX7Y8IdQFAS0od22ALpNcw_kKYmuqayO0knEs08ymFw3ZNg47XsjfbWpsbXDL-'
Epm::Application.configure do
  config.geokit.default_units = :kms
  # config.geokit.geocoders.google
  #Geokit::Geocoders::MapQuestGeocoder.key = "cYOondyn4ktJAf7frbiVD5jkdGNASuf0"
  # AtLX7Y8IdQFAS0od22ALpNcw_kKYmuqayO0knEs08ymFw3ZNg47XsjfbWpsbXDL-
  config.geokit.geocoders.provider_order = [:map_quest]
end