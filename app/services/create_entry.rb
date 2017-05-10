class CreateEntry < BaseService
  include ServiceHelper

  attr_reader :user, :text, :messages

  def initialize(user, text, messages)
    @user     = user
    @text     = text
    @messages = messages
    super()
  end

  def call
    match_data = text.match(Message::Conditions::ENTER_TIME_REGEXP)

    if match_data
      handle_valid_timesheet_entry(match_data[1], match_data[2], match_data[3])
    else
      sender.send_message(user, 'Please add entry in following format: `PROJECT_NAME HOURS:MINUTES COMMENT`')
    end
  end

  private

  def handle_valid_timesheet_entry(project_name, time, details)
    project = find_project_by_name(project_name)

    unless project
      sender.send_message(user, 'No such project.')
      ShowProjects.call(user)
      return
    end

    message = messages['log'].sample
    minutes = parse_time(time)
    time = format('%2d:%02d', minutes / 60, minutes % 60)
    user.time_entries.create!(project_id: project.id, time: time, minutes: minutes, details: details, date: Time.zone.today)
    sender.send_message(user, message['text'], message['options'])
  end

  private

  def parse_time(time)
    match_data = time.match(/^(\d?\d):([0-5]\d)$/)
    match_data[1].to_i * 60 + match_data[2].to_i
  end
end
