# rubocop:disable Style/LeadingCommentSpace
#ruby=2.1.5
#ruby-gemset=flux-hue
# rubocop:enable Style/LeadingCommentSpace
source "https://rubygems.org"

# See:
#   https://gist.github.com/EmmanuelOga/264060
#   http://reevoo.github.io/blog/2014/09/12/http-shooting-party/
#   https://docs.google.com/a/mrjoy.com/spreadsheets/d/1uS3UbQR6GaYsozaF5yQMLmkySY6TO42BIndr2hUW2L4/pub?hl=en&hl=en&output=html
#   http://www.slideshare.net/HiroshiNakamura/rubyhttp-clients-comparison
#   http://raml.org
#     https://github.com/coub/raml_ruby
#     https://github.com/mulesoft/api-console
#     https://github.com/mulesoft/api-notebook
#     https://github.com/mulesoft/raml-sublime-plugin
#     https://github.com/thebinarypenguin/raml-cop
#     https://github.com/cybertk/abao/
#     https://github.com/mulesoft/raml-client-generator
#     https://github.com/QuickenLoans/ramllint
# Try:
#   https://github.com/lostisland/faraday
#   https://github.com/typhoeus/typhoeus#readme
#   https://github.com/igrigorik/em-http-request
# Force keepalive off to see if that makes any difference:
#   Curl::Easy.http_get('http://www.yahoo.com') { |x| x.version = Curl::HTTP_1_0 }
#   easy.header_str.grep(/keep-alive/)

gemspec

gem "curb"

group :development do
  gem "rake",           require: false
  gem "rubocop",        require: false
  gem "bundler-audit",  require: false
end

group :development, :test do
  gem "pry"
end

group :test do
  gem "rspec", "~> 3.3.0"
  gem "webmock"
end
