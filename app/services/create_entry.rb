# frozen_string_literal: true

class CreateEntry < BaseService
  include ServiceHelper

  attr_reader :user, :text, :messages, :project_number

  def initialize(user, text, messages, project_number = nil)
    @user     = user
    @text     = text
    @messages = messages
    @project_number = project_number
    super()
  end

  def call
    match_data = text.match(Message::Conditions::ENTER_TIME_REGEXP)

    create_entry(match_data[1], match_data[2], match_data[3])
  end

  private

  def create_entry(project_name, time, details)
    projects = find_project_by_name_like(project_name)
    precise_match = find_project_by_name(project_name)

    handle_multiple_projects.call(projects, precise_match)
    handle_no_projects.call(projects)
    add_entry_to_db(projects, precise_match, time, details)
  end

  def handle_multiple_projects
    proc do |projects, precise_match|
      if projects.count > 1 && project_number.nil? && precise_match.nil?
        outgoing_message = 'Specify the number of project : '
        projects.each_with_index { |obj, i| outgoing_message += "\n#{i + 1} - #{obj.name}" }
        sender.send_message(user, outgoing_message)
        user.update!(last_message: text)
        return
      end
    end
  end

  def handle_no_projects
    proc do |projects|
      if projects.count.zero?
        sender.send_message(user, 'No such project.')
        ShowProjects.call(user)
        return
      end
    end
  end

  def add_entry_to_db(projects, precise_match, time, details)
    project = projects.count > 1 && project_number.present? ? projects[project_number - 1] : precise_match || projects.first
    user.time_entries.create!(project_id: project.id, time: time, details: details, date: Time.zone.today)

    notify_user(project, details, time)
  end

  def notify_user(project, details, time)
    message = "Set timesheet for #{Time.zone.today.strftime('%b %-d, %Y')} for #{project.name}: #{time}."
    message += "\nDetails: #{details || 'none'}." if details

    sender.send_message(user, message)
  end
end
