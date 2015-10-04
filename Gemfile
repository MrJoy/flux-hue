# rubocop:disable Style/LeadingCommentSpace
#ruby-gemset=sparkle_motion
# rubocop:enable Style/LeadingCommentSpace
# TODO: Look into these:
# TODO:   https://github.com/skaes/rvm-patchsets
# TODO:   http://tmm1.net/ruby21-rgengc/
# TODO:   http://blog.paracode.com/2015/08/28/ruby-and-go-sitting-in-a-tree
source "https://rubygems.org"
ruby "2.2.3"

# http://masa16.github.io/ruby-pgplot/
# http://masa16.github.io/narray/mdary.html
# http://hans.fugal.net/src/ruby-audio/doc/
# http://gridflow.ca/
# http://rb-gsl.rubyforge.org/
# http://ruby.gfd-dennou.org/

# See:
#   https://github.com/junegunn/perlin_noise
#   https://gist.github.com/EmmanuelOga/264060
#   http://reevoo.github.io/blog/2014/09/12/http-shooting-party/
#   https://docs.google.com/a/mrjoy.com/spreadsheets/d/1uS3UbQR6GaYsozaF5yQMLmkySY6TO42BIndr2hUW2L4/pub?hl=en&hl=en&output=html
#   http://www.slideshare.net/HiroshiNakamura/rubyhttp-clients-comparison
#   https://github.com/karlstav/cava
#   http://www.fftw.org/fftw3_doc/Wisdom.html#Wisdom
#     https://rubygems.org/gems/fftw3
#     https://rubygems.org/gems/hornetseye-fftw3
#     https://rubygems.org/gems/ruby-fftw3
#     http://www.fftw.org/fftw3_doc/Words-of-Wisdom_002dSaving-Plans.html#Words-of-Wisdom_002dSaving-Plans
#     http://www.fftw.org/links.html
#     http://www.fftw.org/pruned.html
#   http://raml.org
#     https://github.com/coub/raml_ruby
#     https://github.com/cybertk/abao/
#     https://github.com/drb/raml-mock-server
#     https://github.com/EconomistDigitalSolutions/ramlapi
#     https://github.com/farolfo/raml-server
#     https://github.com/gtrevg/golang-rest-raml-validation
#     https://github.com/isaacloud/local-api
#     https://github.com/mulesoft-labs/raml-generator
#     https://github.com/mulesoft/api-console
#     https://github.com/mulesoft/api-notebook
#     https://github.com/mulesoft/raml-client-generator
#     https://github.com/mulesoft/raml-sublime-plugin
#     https://github.com/nogates/vigia
#     https://github.com/QuickenLoans/ramllint
#     https://github.com/thebinarypenguin/raml-cop
#     https://github.com/mcuadros/go-candyjs
#  https://github.com/birkirb/hue-lib
# Try:
#   https://github.com/arirusso/unimidi
#     https://github.com/arirusso/micromidi
#   https://github.com/IFTTT/Kashmir
#   https://github.com/IFTTT/memoize_via_cache
#   https://github.com/lostisland/faraday
#   https://github.com/typhoeus/typhoeus#readme
#   https://github.com/igrigorik/em-http-request

gemspec
# gem "os",               require: false # https://github.com/rdp/os -- rss_bytes returns KiB, not B

group :development do
  gem "rake",             require: false
  gem "rubocop",          require: false
  gem "bundler-audit",    require: false
  gem "todo_lint",        require: false
  gem "ruby-graphviz",    require: false # for `bundle viz`.

  gem "rgb",              require: false

  gem "ruby-prof",        require: false # https://github.com/ruby-prof/ruby-prof
  gem "memory_profiler",  require: false

  gem "chunky_png",       require: false
  gem "oily_png",         require: false
end

# gem "ncursesw-ruby" # https://github.com/sup-heliotrope/ncursesw-ruby
# gem "curses" # https://github.com/ruby/curses/blob/master/sample/hello.rb
# gem "ncurses-ruby" # https://github.com/eclubb/ncurses-ruby

# Measure memory usage thusly:
#   pid, size = `ps ax -o pid,rss | grep -E "^[[:space:]]*#{$$}"`.strip.split.map(&:to_i)
# Note problem of PID 1234 when PID 12345 exists... Maybe use this instead:
#   size = `ps -o rss -p #{$$}`.chomp.split("\n").last.to_i
#   size = `ps -o rss= -p #{Process.pid}`.to_i
# Or:
#   "The OS gem has an rss_bytes method that works for Linux/windows/OS X ..."

group :development, :test do
  gem "pry"
end

# group :test do
#   gem "rspec", "~> 3.3.0"
#   gem "webmock"
# end
