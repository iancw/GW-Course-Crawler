require 'open-uri'
require 'rubygems'
require 'hpricot'

class Course
  attr_accessor :name, :number, :url, :prereqs

  def initialize(name, number, url)
    @name=name
    @number=number
    @url=url
    @prereqs=Array.new
  end

  def readDetails
    doc=open(@url){|f| doc = Hpricot( f.read )}
    #first one's staff, second one's credits, third one's the description
    #pre-reqs need to be parsed from the description
    paras=doc/"td.center_frame//p"
    @profs = paras[0].inner_text.strip
	puts "profs-"+@profs
    @credits = paras[1].inner_text.match(/[0-9]+/).to_s	
	puts "creds-"+@credits
    @desc = paras[2].inner_text
	puts "desc-"+@desc
     parsePrereqs.each do |pre|
       @prereqs << pre
     end
  end

  def parsePrereqs
    @desc.match(/Prerequisite:.*\z/).to_s.split(/,/)
  end

  def to_s
    @name + " (" + @number+") "+@url
  end
end

class Search
  attr_accessor :courses

  def initialize(url, xpath)
    @root_url=url
    @xpath=xpath
    @courses=Array.new
  end


  def start 
    @doc=open(@root_url){|f| doc = Hpricot( f.read )}
    createCourses
  end

  def createCourses
  # <blockquote><a href="../../course-detail.php?courseCode=173">CSci 173</a> - Continuous Algorithms<br><a href
    (@doc/@xpath).each do |blockquote|
      names = blockquote.inner_html.split(/<br.?.?>/).collect{ |str|
# <a href="../../course-detail.php?courseCode=399">CSci 399</a> - Dissertation Research
	str.match(/[A-Z][\w\s()-]*\z/).to_s
      }
	count=0
      (blockquote/"a").each do |link|
        @courses << Course.new(names[count], link.inner_html.match(/[0-9]+/).to_s, @root_url+link.attributes['href'])
	count=count+1
      end
    end
  end
end


s = Search.new("http://cs.seas.gwu.edu/academics/graduate/courses/", "td.center_frame/blockquote")
#"/html/body/table[2]/tr[1]/td[2]/blockquote")
s.start
s.courses.each do |course| 
 puts course
 course.readDetails
end
