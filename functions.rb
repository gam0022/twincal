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

Locations = {
  "GB12016" => "3C301",
  "GB13604" => "3A207",
  "GB12301" => "3A202",
  "GB12901" => "3A203",
  "GB11701" => "3A203",
  "GB11404" => "3A402",
  "GB11111" => "3A304"
}

def get_subjects(raw_data)
  subjects = Array.new

  # 曜日
  WEEK.each_with_index do |week, i|
    # 時限
    (0..5).each do |j|
      crow = ROW_PAD + j*3
      ccol = COL_PAD + i
      if ((code_class = raw_data[crow][ccol]) != "未登録")
        # GB12016　1A:専門科目（必修）
        if /(\w+)　(.+)/ =~ code_class
          s = {
            :wday     => i,
            :period   => j,
            :time     => "#{week}#{j+1}",
            :time_jp  => "#{WEEK_JP[i]}#{j+1}",
            :code     => $1,
            :name     => raw_data[crow+1][ccol],
            :class    => $2,
            :teacher  => raw_data[crow+2][ccol],
            :location => Locations[$1]
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
  def to_icsf
    self.strftime("%Y%m%dT%H%M00")
  end

  def to_icsf_date
    self.strftime("%Y%m%d")
  end

end

def parse_params(params)

  # 各曜日の学期初めの日付を求める
  current = term_start = Date.parse(params["term_start"][0])
  term_end = Time.parse("#{params["term_end"][0]} 20:00").to_icsf
  #term_end = Time.parse(params["term_end"][0]).to_icsf_date

  i = yday = term_start.yday
  j = wday = term_start.wday
  term_start_each_wday = Array.new

  while i < (yday + 7) do
    term_start_each_wday[j-1] = current.to_s if WEEK_MAP[j]
    i += 1
    j = (j+1)%7
    current = current.next
  end

  # subjectsの復元
  keys = [
    :wday, :period, :time, :time_jp, 
    :code, :name, :class, :teacher,
    :location, :dump,
    :start, :end
  ]
  subjects = params["subject[]"].map do |item|
    a = Hash.new
    item.split("::").each_with_index do |val, i|
      a[keys[i]] = val
    end
    a
  end

  subjects.each_with_index do |item, i|
    # location
    item[:location] = params["l_#{item[:time]}"][0]
    # 授業の始まる時間・終わる時間
    item[:start] = Time.parse("#{term_start_each_wday[item[:wday].to_i]} #{P_START[item[:period].to_i]}").to_icsf
    item[:end] = Time.parse("#{term_start_each_wday[item[:wday].to_i]} #{P_END[item[:period].to_i]}").to_icsf
  end

  user = params["user"][0]

  return subjects, term_end, user
end

# 使ってくれた人の学籍番号をメモ
def log(user)
  `echo '#{user} - #{Time.now.to_s}' >> ./users.log`
end
