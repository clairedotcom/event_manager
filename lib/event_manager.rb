#puts 'EventManager Initialized!'

#lines = File.readlines('event_attendees.csv')
#lines.each_with_index do |line,index|
#    next if index == 0
#    columns = line.split(",")
#    name = columns[2]
#    puts name
#end    

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5,'0')[0..4]
end

def representative_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
    
    begin
        civic_info.representative_info_by_address(
            address:zip,
            levels:'country',
            roles:['legislatorUpperBody','legislatorLowerBody']
        ).officials
    rescue
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end  

def save_thank_you_letter(id,form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename,'w') do |file|
        file.puts form_letter
    end 
end

def clean_phone_number(number)
    trimmed_num = number.gsub(/[^0-9]/,"")
    if trimmed_num.length == 10
        trimmed_num
    elsif trimmed_num.length == 11 && trimmed_num[0] == 1
        trimmed_num[1..11]
    else
        "Number unavailable"
    end        
end

def pull_hour(date)
    d = DateTime.strptime(date.to_s,"%m/%d/%g %H:%M")
    d.hour
end

def pull_weekday(date)
    d = Date.strptime(date,"%m/%d/%y")
    d.wday
end

puts 'EventManager initialized.'

contents = CSV.open('event_attendees.csv', 
    headers: true,
    header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
line_count = File.readlines('event_attendees.csv').size
erb_template = ERB.new template_letter

hours_count = []
weekday_count = []
weekdays = ["Sunday", "Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    phone_number = clean_phone_number(row[:homephone])
    
    hour = pull_hour(row[:regdate])
    hours_count.push(hour)

    weekday = pull_weekday(row[:regdate])
    weekday_count.push(weekday)

    h_count = hours_count.reduce(Hash.new(0)) do |h,total|
        h[total] += 1
        h
    end

    wd_count = weekday_count.reduce(Hash.new(0)) do |wd,total|
        wd[total] += 1
        wd
    end
    
    max_h = h_count.max_by{|k,v| v}
    max_wd = wd_count.max_by{|k,v| v}

    if id.to_i == line_count - 1
        puts "Most people registered on #{weekdays[max_wd[0]]} at #{max_h[0]} o'clock."
    end    

    legislators = representative_by_zipcode(zipcode)
    form_letter = erb_template.result(binding)
    save_thank_you_letter(id,form_letter)
end

