#! /usr/bin/ruby
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

  # 授業情報の配列
  subjects = get_subjects_from_params(cgi.params)
  # 学期の終了日時(フォーマット済み)
  term_end = get_term_end(cgi.params)

  # ビュー
  print "Content-Disposition: attachment; filename=\"twincal.ics\"\r\n"
  print cgi.header(
    "charset"=>"UTF-8",
    "type"=>'application/octet-stream; name="twincal.ics"'
  )
  print View.new(subjects, term_end).to_ics

  # ログ
  log(cgi.params["user"][0], "./success.log")

rescue => e
  # エラー処理
  exception_handling(e, cgi) 
end
