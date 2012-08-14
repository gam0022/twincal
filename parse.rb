#! /usr/local/rvm/rubies/ruby-1.9.3-p0/bin/ruby
# -*- coding: utf-8 -*-

require 'cgi'
require './functions.rb'

class View

  def initialize(subjects, user)
    @subjects = subjects
    @user     = user
  end

  extend ERB::DefMethod
  def_erb_method('to_html', 'views/config.erb')

end


# consts
VALID_ROWS = 25
VALID_COLS = 6
ROW_PAD = 5 # 時間割のデータの始まる行
COL_PAD = 1 # 時間割のデータの始まる列

begin
  cgi = CGI.new

  # CSVを配列にしたもの
  raw_data = CSV.parse(cgi.params['file'][0].read.encode("UTF-8", "CP932"))

  # CSVの表の大きさをチェックする
  raise "invalid csv file" if raw_data.size != VALID_ROWS || raw_data[0].size != VALID_COLS

  # 時間割の配列
  subjects = get_subjects(raw_data)
  user = raw_data[1][5]

  # ビュー
  puts cgi.header("charset"=>"UTF-8")
  puts View.new(subjects, user).to_html

rescue
  # エラー
  print cgi.header( { 
    "status"     => "REDIRECT",
    "Location"   => "http://gam0022.net/app/twincal/?has_error=true"
  })
end
