require 'json'
require 'httparty'
require 'redis'
require 'dotenv'

Dotenv.load

class Project
  CACHE_TTL = 300
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

  def open_milestones
    get_milestones('open')
  end

  def closed_milestones
    get_milestones('closed')
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
    open_issues_with_tag('3 - review')
  end

  def done_issues
    open_issues_with_tag('4 - done')
  end

  def issues_for_milestone(milestone_title)
    all_issues.find_all { |i| i['milestone'] ? i['milestone']['title'] == milestone_title : false }
  end

  def last_closed_milestone
    closed_milestones[0]
  end

  def second_last_closed_milestone
    closed_milestones[1]
  end

  def clear
    redis.keys("hubcap_cache_#{@repository}*").each do |key|
      redis.del key
    end
  end

  def issue_url(issue_number)
    "https://github.com/#{@organisation}/#{@repository}/issues/#{issue_number}"
  end

  private

  def all_issues
    open_issues + closed_issues
  end

  def open_issues_with_tag(tag)
    open_issues.find_all { |i| i['labels'].find { |l| l['name'] == tag } }
  end

  def api_url
    "https://api.github.com/repos/#{@organisation}/#{@repository}"
  end

  def get_issues(state, label='')
    fetch "issues_#{state}#{label.empty? ? '' : '_' + label}", CACHE_TTL do
      HTTParty.get("#{api_url}/issues?filter=all&labels=#{label}&state=#{state}&per_page=100", @opts).parsed_response
    end
  end

  def get_pull_requests(state)
    fetch "pulls_#{state}", CACHE_TTL do
      HTTParty.get("#{api_url}/pulls?state=#{state}", @opts).parsed_response
    end
  end

  def get_milestones(state)
    fetch "milestones_#{state}", CACHE_TTL do
      HTTParty.get("#{api_url}/milestones?state=#{state}", @opts).parsed_response
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
