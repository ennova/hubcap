module ApplicationHelpers
  def project
    @project ||= Project.new
  end

  def related_issues_as_links(issue)
    related_issues = issue['body'].scan(/#(\d+)/)
    links = ''
    if related_issues.size > 0
      related_issues.each do |issue|
        links += html_href(project.issue_url(issue[0]), issue[0])
        links += ' '
      end
    end
    links
  end

  def milestone_as_link(issue)
    if issue['milestone']
      html_href(issue['milestone']['url'], html_span('label label-important', issue['milestone']['title']))
    end
  end

  def blocked_label(issue)
    if issue['labels'] && issue['labels'].find { |l| l['name'] == 'blocked' }
       html_span('label label-inverse', 'blocked')
    end
  end

  def item_assignee(issue)
    if issue['assignee']
      html_span('label label-info', Project::NAMES[issue['assignee']['login']])
    end
  end

  def item_age(issue)
    age_days = (Date.today - Time.parse(issue['created_at']).to_date).to_i
    case age_days
    when 0..10
      html_span('badge badge-success', age_days)
    when 11..20
      html_span('badge badge-warning', age_days)
    when 20..100
      html_span('badge badge-important', age_days)
    else
      html_span('badge', age_days)
    end
  end

  def class_for_issue(issue)
    if item_bug_label?(issue)
      'error'
    elsif item_important_label?(issue)
      'warning'
    end
  end

  def item_bug_label?(issue)
    issue['labels'] && issue['labels'].collect { |l| l['name'].downcase }.join(' ').match('bug')
  end

  def item_important_label?(issue)
    issue['labels'] && issue['labels'].collect { |l| l['name'].downcase }.join(' ').match('important')
  end

  def assigned_items(issues, assignee_login)
    issues.find_all {|i| i['assignee'] && i['assignee']['login'] == assignee_login }
  end

  def html_href(target, text)
    %Q[<a href="#{target}">#{text}</a>]
  end

  def html_span(style, text)
    %Q[<span class="#{style}">#{text}</span>]
  end
end
