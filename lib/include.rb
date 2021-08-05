require 'rubygems'
require 'bundler'
Bundler.setup(:default, :ci)

require 'csv'
require 'json'
require 'time'

require 'colorize'

require_relative './paths.rb'
require_relative './errors.rb'
require_relative './test.rb'
require_relative './old_html.rb'
require_relative './html.rb'
require_relative './reference.rb'

require_relative './document/document.rb'
require_relative './document/structure.rb'
require_relative './document/punctuation.rb'
require_relative './document/date.rb'
require_relative './document/line.rb'

require_relative './segments/una.rb'
require_relative './segments/unh.rb'
require_relative './segments/unb.rb'
require_relative './segments/uns.rb'
require_relative './segments/unt.rb'
require_relative './segments/unz.rb'
require_relative './segments/bgm.rb'
require_relative './segments/ali.rb'
require_relative './segments/dtm.rb'
require_relative './segments/gir.rb'
require_relative './segments/ftx.rb'
require_relative './segments/rff.rb'
require_relative './segments/nad.rb'
require_relative './segments/tax.rb'
require_relative './segments/lin.rb'
require_relative './segments/pac.rb'
require_relative './segments/qty.rb'
require_relative './segments/imd.rb'
require_relative './segments/pia.rb'
require_relative './segments/mea.rb'
require_relative './segments/pri.rb'
require_relative './segments/gin.rb'
require_relative './segments/cps.rb'
require_relative './segments/pci.rb'
require_relative './segments/loc.rb'
require_relative './segments/inv.rb'
require_relative './segments/cdi.rb'
require_relative './segments/cnt.rb'
require_relative './segments/moa.rb'

require_relative './cli.rb'