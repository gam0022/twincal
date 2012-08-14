#! /usr/local/rvm/rubies/ruby-1.9.3-p0/bin/ruby
# -*- coding: utf-8 -*-

require 'cgi'
require './functions.rb'

class View

  def initialize(has_error)
    @has_error = has_error
  end

  extend ERB::DefMethod
  def_erb_method('to_html', 'views/index.erb')

end

begin
  cgi = CGI.new
  has_error = cgi.params["has_error"][0]

  # ビュー
  puts cgi.header("charset"=>"UTF-8")
  puts View.new(has_error).to_html

rescue
  # エラー
  print cgi.header( { 
    "status"     => "REDIRECT",
    "Location"   => "http://gam0022.net/app/twincal/?has_error=true"
  })
end
