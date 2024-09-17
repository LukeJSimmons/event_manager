require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thank_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  cleaned_phone_number = phone_number.tr('^0-9', '')
  if cleaned_phone_number.length != 10
    if cleaned_phone_number.length == 11 && cleaned_phone_number[0] == '1'
      cleaned_phone_number = cleaned_phone_number[1..10]
    else
      return ""
    end
  end
  cleaned_phone_number
end

def convert_regdate_to_time_object(regdate)
  time_object = Time.strptime(regdate, "%m/%d/%y %H:%M")
end

def convert_to_12_hours(hour)
  hour_num = hour.to_i
  if hour_num > 12
    (hour_num-12).to_s + "PM"
  else
    hour_num.to_s + "AM"
  end
end

def get_weekday(date)
  days_of_the_week = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
  days_of_the_week[date.wday]
end

puts "Event Manager Initialized!"

contents = CSV.open(
  'event_attendees.csv', 
  headers: true,
  header_converters: :symbol
  )

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  regdate = row[:regdate]
  date = convert_regdate_to_time_object(regdate)

  
  p "#{convert_to_12_hours(date.hour)} on #{get_weekday(date)}"

  save_thank_you_letter(id, form_letter)
end