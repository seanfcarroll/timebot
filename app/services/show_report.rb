class ShowReport < BaseService
  include ServiceHelper

  attr_reader :user, :text

  def initialize(user, text)
    @user = user
    @text = text
    super()
  end

  def call
    time         = text.downcase.match(Message::Conditions::MESSAGE_IN_REPORT)[1]
    project_name = text.downcase.match(Message::Conditions::MESSAGE_IN_REPORT)[2]

    if project_name.present?
      project = find_project_by_name(project_name)
      if project.present?
        handle_show_by(time, project)
      else
        sender.send_message(user, 'No such project.')
        handle_message_show_projects
      end
    else
      handle_show_by time
    end
  end

  private

  def handle_show_by(time, project = nil)
    case time
    when 'week'
      handle_report(Time.zone.now.beginning_of_week.to_date, Time.zone.today, project)
    when 'last week'
      handle_report(1.week.ago.beginning_of_week.to_date, 1.week.ago.end_of_week.to_date, project)
    when 'month'
      handle_report(Time.zone.now.beginning_of_month.to_date, Time.zone.today, project)
    when 'last month'
      handle_report(1.month.ago.beginning_of_month.to_date, 1.month.ago.end_of_month.to_date, project)
    end
  end

  def handle_report(start_date, end_date, project)
    date = suitable_start_date(start_date)

    list = (date..end_date).to_a.map do |day|
      entries = user.time_entries.where(date: day)
      entries = entries.where(project_id: project.id) if project.present?
      entries.empty? ? [day, []] : [day, entries.map(&:description).join("\n")]
    end

    strings = list.map do |day, entries|
      "`#{day.strftime('%d.%m.%y` (%A)')}: #{entries.empty? ? 'No entries' : "\n#{entries}"}"
    end

    strings << "*Total*: #{user.total_time_for_range(start_date, end_date, project)}."
    sender.send_message(user, strings.join("\n"))
  end
end