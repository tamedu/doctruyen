# ruby update-content.rb deep
# ruby update-content.rb deep content/song-tu-dao-lu-cua-toi
# ruby update-content.rb deep yeu-than-ky

# remove too small bpg
# list = Dir["content/yeu-than-ky/*/*.bpg"]
# list = list.each do |file|
# `rm #{file}` if File.size(file) <= 35000
# end

require './crawler.rb'

def update_incompleted_chapters(story)
    Dir["#{story}/chapter*"].each do |chapter|
        imgs_count = nil
        md = nil
        if File.size?("#{chapter}/index.md")
            md = File.open("#{chapter}/index.md", "r").read
            # imgs_count = md.scan(/([0-9a-f]+\.bpg|webp)/m).size
            imgs_count = md.scan(/<img/m).size
        end
        next if md && md.match(/"nextchap"/m) && imgs_count > 2
        print " - #{chapter}: "
        print " no index.md. " if md.nil?
        print " #{imgs_count} images. " if imgs_count && imgs_count <= 2
        print " no nextchap. " if md && !md.match(/"nextchap"/m)
        puts "Re-crawling ... "
        if !File.size?("#{chapter}/crawled.html")
            puts "ERROR #{chapter}/crawled.html not cached"
            next
        end
        url = File.open("#{chapter}/crawled.html", 'r').read.match(/og:url" content="[^"]+doc-truyen\/([^"]+).html"/)[1]
        chapnum = chapter.match(/\d+$/)[0].to_i
        Dir.chdir("../"); Crawler.crawl(story, url, chapnum, chapnum); Dir.chdir("./content/")
    end
end

def update_last_chapter(story)
    lastchap = Dir["#{story}/chapter*"].sort_by { |x| x.match(/\d+$/)[0].to_i }.last
    html_file = "#{lastchap}/crawled.html"
    html = nil
    if File.exists?(html_file)
        html = File.open(html_file, 'r').read
        url = html.match(/og:url" content="[^"]+doc-truyen\/([^"]+).html"/)[1]
        lastchap = lastchap.match(/\d+$/)[0].to_i
        Dir.chdir("../"); Crawler.crawl(story, url, lastchap); Dir.chdir("./content/")
    else
        puts "ERROR: #{lastchap} not crawled"
    end
end

BASE_URL = "https://doctruyen.netlify.com/"
def downloads_gen(story)
    list = Dir["#{story}/*/*.webp"] + Dir["#{story}/*/*.bpg"]
    list = list.sort_by { |x| x.match(/[^\/]+?$/)[0]  }
    File.open("#{story}-downloads.txt", 'w').write(BASE_URL + list.join("\n#{BASE_URL}"))
end

Dir.chdir("./content/")
a = ARGV.clone
a.shift if (deep = ARGV[0] == 'deep')

(a.empty? ? Dir["*"] : a).each do |x|
    story = x.sub(/.*content\//, '')
    if File.directory? story
        puts story
        update_incompleted_chapters(story) if deep
        update_last_chapter(story)
        downloads_gen(story)
    end
end
