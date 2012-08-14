#! /usr/local/rvm/rubies/ruby-1.9.3-p0/bin/ruby
# -*- coding: utf-8 -*-

require 'cgi'
require './functions.rb'

class View

  def initialize(subjects, term_end)
    @subjects = subjects
    @term_end = term_end
    @DTSTAMP = @CREATED = @LAST_MODIFIED = Time.now.to_icsf
  end

  extend ERB::DefMethod
  def_erb_method('to_ics', 'views/ics_format.erb')

end

begin
  cgi = CGI.new

  # 時間割の配列
  subjects, term_end, user = parse_params(cgi.params)

  # ビュー
  puts 'Content-Disposition: attachment; filename="twincal.ics"'
  puts cgi.header(
    "charset"=>"UTF-8",
    "type"=>'application/octet-stream; name="twincal.ics"'
  )
  puts View.new(subjects, term_end).to_ics
  log(user)

rescue
  # エラー
  print cgi.header( { 
    "status"     => "REDIRECT",
    "Location"   => "http://gam0022.net/app/twincal/?has_error=true"
  })
end
