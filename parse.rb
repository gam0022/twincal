#! /usr/bin/ruby
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

  # CSVを2次元配列にしたもの
  table = CSV.parse(cgi.params['file'][0].read.encode("UTF-8", "CP932"))

  # 連続するコマの授業をまとめるオプション
  opt_merge = cgi.params['opt'].index("merge")

  # CSVテーブルの大きさをチェックする
  # (行数は履修した選択科目数により変化する)
  raise "invalid csv table size" if table.size < VALID_ROWS || table[0].size != VALID_COLS

  # 時間割の配列
  subjects = get_subjects_from_table(table, opt_merge)
  user = table[1][5]

  # ビュー
  print cgi.header("charset"=>"UTF-8")
  print View.new(subjects, user).to_html

rescue => e
  # エラー処理
  exception_handling(e, cgi) 
end
