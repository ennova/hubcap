require 'json'
require 'httparty'
require 'redis'
require 'dotenv'

Dotenv.load

class Project
  CACHE_TTL = 300
  PAGE_COUNT = 3

  # NAME_MAPPING format: twe4ked=Odin,jasoncodes=Jason
  NAMES = Hash[ENV['NAME_MAPPING'].split(',').map { |x| x.split('=') }]

  attr_accessor :username, :password, :organisation, :repository

  def initialize
    @username = ENV['GITHUB_USERNAME']
    @password = ENV['GITHUB_PASSWORD']
    @organisation = ENV['GITHUB_USER']
    @repository = ENV['GITHUB_REPO']

    @opts = {
      :basic_auth => {:username => @username, :password => @password},
      :headers => {'User-Agent' => 'hubcap'}
    }
  end

  def open_issues
    get_issues('open')
  end

  def closed_issues
    get_issues('closed')
  end

  def milestones
    %w[open closed].map do |state|
      get_milestones state
    end.flatten.sort_by { |milestone| milestone_sort_key(milestone) }
  end

  def pull_requests
    get_pull_requests('open')
  end

  def ready_issues
    open_issues_with_tag('1 - ready')
  end

  def working_issues
    open_issues_with_tag('2 - working')
  end

  def review_issues
    open_issues_containing_tag('review')
  end

  def issues_for_milestone(milestone_title)
    all_issues.find_all { |i| i['milestone'] ? i['milestone']['title'] == milestone_title : false }
  end

  def milestone_with_title(title)
    milestones.select { |milestone| milestone['title'] == title }
  end

  def clear
    redis.keys("hubcap_cache_#{@repository}*").each do |key|
      redis.del key
    end
  end

  def issue_url(issue_number)
    "https://github.com/#{@organisation}/#{@repository}/issues/#{issue_number}"
  end

  def issue_mentioned_by_pull_request
    mapping = {}
    pull_requests.each do |pr|
      mentioned_issues = pr['body'].scan(/#(\d+)/).flatten
      mentioned_issues.each do |issue|
        begin
          mapping[issue] = pr['number']
        rescue
          # It is possible that more than on PR mention the same issue
        end
      end
    end
    mapping
  end

  private

  def all_issues
    open_issues + closed_issues
  end

  def open_issues_with_tag(tag)
    open_issues.find_all { |i| i['labels'].find { |l| l['name'] == tag } }
  end

  def open_issues_containing_tag(tag)
    open_issues.find_all { |i| i['labels'].find { |l| l['name'].match(tag) } }
  end

  def api_url
    "https://api.github.com/repos/#{@organisation}/#{@repository}"
  end

  def get_issues(state, label='')
    issues = fetch "issues_#{state}#{label.empty? ? '' : '_' + label}", CACHE_TTL do
      issues ||= []
      (1..PAGE_COUNT).each do |page|
        issues += HTTParty.get("#{api_url}/issues?filter=all&labels=#{label}&state=#{state}&page=#{page}&per_page=100", @opts).parsed_response
      end
      issues
    end
    issues
  end

  def get_pull_requests(state)
    fetch "pulls_#{state}", CACHE_TTL do
      HTTParty.get("#{api_url}/pulls?state=#{state}", @opts).parsed_response
    end
  end

  def milestone_sort_key(milestone)
    title = milestone['title']

    case title
    when 'Next+1'
      [4, title]
    when 'Next'
      [3, title]
    when /\Av(\d.+)\z/
      [2, Gem::Version.new($1)]
    else
      [1, title]
    end
  end

  def get_milestones(state)
    fetch "milestones_#{state}", CACHE_TTL do
      HTTParty.get("#{api_url}/milestones?state=#{state}&per_page=100", @opts).parsed_response
    end
  end

  def fetch(key, ttl)
    key = "hubcap_cache_#{@repository}_#{key}"
    data = redis.get key

    unless data
      data = yield.to_json
      redis.set key, data
      redis.expire key, ttl
    end

    JSON.parse(data)
  end

  def redis
    @redis ||= if ENV['REDISCLOUD_URL']
      uri = URI.parse(ENV['REDISCLOUD_URL'])
      Redis.new(
        :host => uri.host,
        :port => uri.port,
        :password => uri.password
      )
    else
      Redis.new
    end
  end
end
