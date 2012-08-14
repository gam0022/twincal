# -*- coding: utf-8 -*-
require 'csv'
require 'erb'
require 'time'
require 'date'

WEEK      = ["MON", "TUE", "WED", "THU", "FRI"]
WEEK_JP   = ["月", "火", "水", "木", "金"]
WEEK_MAP  = [nil, "MON", "TUE", "WED", "THU", "FRI", nil]

P_START   = ["8:40", "10:10", "12:15", "13:45", "15:15", "16:45"]
P_END     = ["9:55", "11:25", "13:30", "15:00", "16:30", "18:00"]

LOCATIONS = {
  "GB12016" => "3C301",
  "GB13604" => "3A207",
  "GB12301" => "3A202",
  "GB12901" => "3A203",
  "GB11701" => "3A203",
  "GB11404" => "3A402",
  "GB11111" => "3A304"
}

#
# CSVテーブルを授業ごとの配列に変換する
#
def get_subjects_from_table(table)
  subjects = Array.new

  # 曜日
  WEEK.each_with_index do |week, i|
    # 時限
    (0..5).each do |j|
      crow = ROW_PAD + j*3
      ccol = COL_PAD + i
      if ((code_class = table[crow][ccol]) != "未登録")
        # GB12016　1A:専門科目（必修）
        if /(\w+)　(.+)/ =~ code_class
          s = {
            :wday     => i,
            :period   => j,
            :time     => "#{week}#{j+1}",
            :time_jp  => "#{WEEK_JP[i]}#{j+1}",
            :code     => $1,
            :name     => table[crow+1][ccol],
            :class    => $2,
            :teacher  => table[crow+2][ccol],
            :location => LOCATIONS[$1]
            #:dump
            #:start
            #:end
          }
          s[:dump] = s.values.join("::")
          subjects.push s
        else
          raise "invalid csv file"
        end
      end
    end
  end
  subjects
end

class Time

  # http://www.asahi-net.or.jp/~CI5M-NMR/iCal/ref.html
  # 日付と時刻を一緒に記述する時は、間を T で区切る。例： 19980119T230000
  def to_icsf
    self.strftime("%Y%m%dT%H%M00")
  end

end

#
# 学期の終了日時をフォーマット済みの状態で求める
#
def get_term_end(params)
  Time.parse("#{params["term_end"][0]} 20:00").to_icsf
end

#
# 各曜日の授業開始日を求める
#
def get_term_start_each_wday(params)

  term_start_each_wday = Array.new

  current = term_start = Date.parse(params["term_start"][0])
  i = yday = term_start.yday
  j = wday = term_start.wday

  while i < (yday + 7) do
    term_start_each_wday[j-1] = current.to_s if WEEK_MAP[j]
    i += 1
    j = (j+1)%7
    current = current.next
  end

  term_start_each_wday
end

#
# CGIのパラメータからsubjectsを復元
#
def get_subjects_from_params(params)

  keys = [
    :wday, :period, :time, :time_jp, 
    :code, :name, :class, :teacher,
    :location, :dump,
    :start, :end
  ]
  # ハッシュの配列にしたかった。これはひどい。
  subjects = params["subjects[]"].map do |item|
    a = Hash.new
    item.split("::").each_with_index do |val, i|
      a[keys[i]] = val
    end
    a
  end

  # 各曜日の授業開始日
  term_start_each_wday = get_term_start_each_wday(params)

  # subjectに追加情報を付加する
  subjects.each_with_index do |item, i|
    # 場所
    item[:location] = params["l_#{item[:time]}"][0]
    # 授業の開始日時と終了日時
    item[:start] = Time.parse("#{term_start_each_wday[item[:wday].to_i]} #{P_START[item[:period].to_i]}").to_icsf
    item[:end] = Time.parse("#{term_start_each_wday[item[:wday].to_i]} #{P_END[item[:period].to_i]}").to_icsf
  end

  return subjects
end

#
# ログ
# 
def log(str, file)
  `echo '#{str} - #{Time.now.to_s}' >> #{file}`
end

#
# エラー処理は全部これ
#
def exception_handling(e, cgi)
  print cgi.header( { 
    "status"     => "REDIRECT",
    "Location"   => "http://gam0022.net/app/twincal/?has_error=true"
  })
  log(e.to_s, "./error.log")
end
