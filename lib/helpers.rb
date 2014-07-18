module ApplicationHelpers
  def project
    @project ||= Project.new
  end

  def related_issues_as_links(issue)
    related_issues = issue['body'].scan(/#(\d+)/).uniq
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

  def state_label(issue)
    style = issue['state'] == 'closed' ? 'label-success' : 'label-warning'
    html_span("label #{style}", issue['state'])
  end

  def blocked_label(issue)
    if issue['labels'] && issue['labels'].find { |l| l['name'] == 'blocked' }
       html_span('label label-inverse', 'blocked')
    end
  end

  def accepted_label(issue)
    if issue['labels'] && issue['labels'].find { |l| l['name'] == 'accepted' }
       html_span('label label-success', 'accepted')
    end
  end

  def item_assignee(issue)
    if issue['assignee']
      html_span('label label-info', Project::NAMES[issue['assignee']['login']])
    end
  end

  def age_in_days(issue)
    (Date.today - Time.parse(issue['created_at']).to_date).to_i
  end

  def age_style(issue)
    case age_in_days(issue)
    when 0..10
      'badge badge-success'
    when 11..20
      'badge badge-warning'
    when 20..100
      'badge badge-important'
    else
      'badge'
    end
  end

  def item_number(issue)
    html_span(age_style(issue), issue['number'])
  end

  def item_age(issue)
    html_span(age_style(issue), age_in_days(issue))
  end

  def pull_request_label(issue)
    pr_number = @project.issue_mentioned_by_pull_request[issue['number'].to_s]
    html_span('label label-info', "PR#{pr_number}") if pr_number
  end

  def class_for_issue(issue)
    if item_bug_label?(issue)
      'error'
    elsif item_important_label?(issue)
      'warning'
    elsif item_tech_debt_label?(issue)
      'info'
    end
  end

  def item_bug_label?(issue)
    issue['labels'] && issue['labels'].collect { |l| l['name'].downcase }.join(' ').match('bug')
  end

  def item_tech_debt_label?(issue)
    issue['labels'] && issue['labels'].collect { |l| l['name'].downcase }.join(' ').match('tech debt')
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
