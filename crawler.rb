require 'open-uri'
require 'digest'
require 'phash/image'

module Crawler

JUNK_IMAGE_PHASHES = Dir["resources/junk/*.jpg"].map do |jpg|
    phash_data = nil
    if m = jpg.match(/_(\d+)_/)
        phash_data = Phash::ImageHash.new(m[1].to_i)
    else
        phash_data = Phash::Image.new(jpg).phash
        `mv #{jpg} #{jpg.sub(".jpg", "_#{phash_data.data}_.jpg")}`
    end
    phash_data
end

JUNK_FOOTER_PHASHES = { }
Dir["resources/junk/_footers/*.png"].each do |png|
    w, h, phash_data = nil
    if tmp = png.match(/_(\d+)_(\d+)x(\d+)/)
        phash_data = Phash::ImageHash.new(tmp[1].to_i)
        w = tmp[2].to_i
        h = tmp[3].to_i
    else
        tmp = `identify #{png}`.match(/(JPEG|PNG) (\d+)x(\d+)/).to_a
        w = tmp[2].to_i
        h = tmp[3].to_i
        tmp = png.sub(".png", "_800x200")
        `convert #{png} -crop 800x200+0+#{h-200}\! #{tmp}`
        phash_data = Phash::Image.new(tmp).phash
        `mv #{png} #{png.sub(".png", "_#{phash_data.data}_#{w}x#{h}.png")}`
    end
    JUNK_FOOTER_PHASHES[phash_data] = [w, h]
end

def self.parse(html, story, subdir, x, nextchap = true)
    File.open("#{subdir}/index.tmp", "wt") do |f|
        f.puts "{ \"title\": \"#{story}/chapter-#{x}\", \"weight\": #{x} }"
        nextchap_link = "<a class=\"nextchap\" href=\"/#{story}/chapter-#{x + 1}\">chapter-#{x + 1}</a>"

        m = html.match(/id=['"]content_chap['"](.+?)div_info_bottom/mi)
        unless m
            m = "" if html.include?("thử nghiệm hình thức đọc truyện trên video")
        else
            m = m[1]
        end

        names = []
        matches = m.scan(/<img.+?src=['"]([^'"]+)/mi)
        n = matches.size

        # puts matches

        matches.each_with_index do |m, i|
            # skip cover page
            next if i == 0 && x > 1

            img_url = m[0]            
            if (m = img_url.match(/url=(http.+)$/i))
                print "#{img_url} => "
                img_url = URI.unescape(m[1])
            end
            name = Digest::MD5.hexdigest img_url
            img_url = img_url.strip.gsub("&#10;", "")
            prefix = sprintf("#{story}_%04d_%02d", x, i)


            names << name
            bpg = "#{subdir}/#{prefix}-#{name}.bpg"
            webp = "#{subdir}/#{prefix}-#{name}.webp"
            jpg = Dir["#{subdir}/*-#{name}.jpg"].first || "#{subdir}/#{prefix}-#{name}.jpg"
            png = "#{subdir}/#{prefix}-#{name}.png"


            `wget "#{img_url}" -O #{jpg}` unless File.exists?(jpg)
            w = h = nil
            if tmp = jpg.match(/(\d+)x(\d+)/)
                w = tmp[1].to_i
                h = tmp[2].to_i
                # if w <= 200
                #     `wget "#{img_url}" -O #{jpg}`
                #     tmp = `identify #{jpg}`.match(/(JPEG|PNG) (\d+)x(\d+)/).to_a
                #     w = tmp[2].to_i
                #     h = tmp[3].to_i
                # end
            else
                tmp = `identify #{jpg}`.match(/(JPEG|PNG) (\d+)x(\d+)/).to_a
                w = tmp[2].to_i
                h = tmp[3].to_i
            end

            puts "[#{i}] #{img_url} => #{name}"
            # puts jpg

            if w > 200
            old_jpg = jpg
            jpg = "#{subdir}/#{prefix}-#{w}x#{h}-#{name}.jpg"
            `mv #{old_jpg} #{jpg}` if old_jpg != jpg

            # whole image junk detection
            if (i >= n - 2 || i <= 2  || w >= h) # two first/last images or horizontal images
                phash_data = nil
                if (m = Dir["#{subdir}/_*_#{name}.jpg"].first.to_s.match(/_(\d+)_#{name}/))
                    phash_data = Phash::ImageHash.new(m[1].to_i)
                else
                    if phash_data = Phash::Image.new(jpg).phash
                        `cp #{jpg} #{subdir}/_#{phash_data.data}_#{name}.jpg`
                    end
                end
                if phash_data
                    junk_found = false
                    JUNK_IMAGE_PHASHES.each do |junk|
                        if junk.similarity(phash_data) > 0.85
                            junk_found = true
                            puts "Junk found: #{jpg}"
                            break
                        end
                    end
                    if junk_found
                        if File.size?(webp) ; puts cmd = "rm #{subdir}/*#{name}.webp" ; `#{cmd}` end
                        if File.size?(bpg)  ; puts cmd = "rm #{subdir}/*#{name}.bpg"  ; `#{cmd}` end
                        next
                    end
                end
            end

            # footer image junk detection
            footer_png = Dir["#{subdir}/*-#{name}_*.png"].first || "#{subdir}/#{prefix}-#{name}_.png"
            fh, fphash = nil
            if tmp = footer_png.match(/_(\d+)_(\d+)x(\d+)/)
                fphash = Phash::ImageHash.new(tmp[1].to_i)
                fh = tmp[3].to_i
            else
                fh = (200.0*w/800).round
                `convert #{jpg} -crop #{w}x#{fh}+0+#{h-fh}\! #{footer_png}`
                if fphash = Phash::Image.new(footer_png).phash
                    cmd = "mv #{footer_png} #{footer_png.sub(".png", "#{fphash.data}_#{w}x#{fh}.png")}"
                    `#{cmd}`
                end
            end

            footer_junk_found = nil
            if fphash
                JUNK_FOOTER_PHASHES.each do |p, s|
                    sim = p.similarity(fphash)
                    if sim > 0.83
                        footer_junk_found = s
                        puts "Footer junk found #{sim}: #{jpg} => #{p.data}"
                        break
                    end
                end
            end
            
            cmd = Dir["#{subdir}/*x*-#{name}.webp"]
            if footer_junk_found
                h -= ( footer_junk_found[1].to_f * w / footer_junk_found[0] ).round
                `rm #{webp}` if File.exists?(webp)
                `rm #{bpg}` if File.exists?(bpg)
                webp = "#{subdir}/#{prefix}-#{w}x#{h}-#{name}.webp"
                puts webp, "---\n"
                cmd = cmd.select { |x| !x.include?("#{w}x#{h}") }
            end
            unless cmd.empty?
                puts cmd = "rm #{cmd.join(" ")}"
                `#{cmd}`
            end

            `rm #{bpg}` if File.exists?(bpg) # !!! REMOVE BPG IN-PREFER OF WEBP !!!
           
            if !File.size?(webp) && !File.size?(bpg)
                cmd = "convert #{jpg}"
                cmd += " -crop #{w}x#{h}+0+0\!" if footer_junk_found
                cmd += " -resize 680" if w > 700
                cmd += " -quality 60 #{webp}"
                puts cmd
                `#{cmd}`
            end
            end # w > 200

            img_src = img_url
            img_src = "#{prefix}-#{name}.bpg" if File.size?(bpg)
            img_src = webp.sub("#{subdir}/", "") if File.size?(webp)
            f.puts "<img src=\"#{img_src}\" alt=\"page-#{i}\" origin=\"#{img_url}\"><br/>"
                
        end # html scan

        # raise "ERROR: this chap has only #{names.size} pages"  if names.size <= 3

        ( Dir["#{subdir}/*.jpg"] + 
          Dir["#{subdir}/*.bpg"] + 
          Dir["#{subdir}/*.webp"] ).map { |name|
            name.match(/([0-9a-f]+)\.(jpg|bpg|webp)$/)[1]
        }.uniq.each do |name|
            unless names.include?(name)
                puts cmd = "rm #{subdir}/*#{name}.*"
                `#{cmd}`
            end
        end

        f.puts "<br/>#{nextchap_link}" if nextchap
    end # finish building index.tmp
    `mv #{subdir}/index.tmp #{subdir}/index.md`
end


def self.crawl(story, nextchap, start = nil, max = nil)
puts "ruby crawler.rb #{story} #{nextchap} #{start} #{max}"

base = "https://hamtruyen.com/doc-truyen"
dir = "./content/#{story}"
`mkdir #{dir}` unless File.exists?(dir)

start = (start || 1).to_i
max = (max || 9999).to_i
(start).upto(max) do |x|
    break unless nextchap
    subdir = "#{dir}/chapter-#{x}"
    `mkdir #{subdir}` unless File.exists?(subdir)

    url = "#{base}/#{nextchap}.html"
    html_file = "#{subdir}/crawled.html"

    puts "\n\n[#{subdir}]\n   GET #{url} ..."

    if File.exists?(html_file)
        html = File.open(html_file, 'r').read        
        cached_url = html.match(/"og:url" content="([^"]+)/)[1]
        puts "CACHED #{cached_url}"
        raise "ERROR: cached html not matched" unless cached_url.include?(nextchap)
    else
        html = open(url).read
        File.open(html_file, 'w').write(html)
    end

    m = html.match(/<option\s+value=['"]([^'"]+)['"].+?selected=/mi)
    lastchap = m[1]
    puts nextchap, lastchap

    if lastchap == nextchap || start == max
        puts "RE-GET lastchap ..."
        html = open(url).read
        # m = html.match(/<option\s+value=['"](.+?)['"].+?<option.+?selected=/mi)
        m = html.match(/<option\s+value=['"]([^'"]+)['"].+?selected=/mi)
        lastchap = m[1]
        File.open(html_file, 'w').write(html) if nextchap != lastchap || start == max
        puts nextchap, lastchap
    end

    if nextchap == lastchap
        nextchap = nil
    else
        nextchap = m ? m[0].split(/value=['"]/i)[-2].match(/(.+?)['"]/)[1] : nil
    end

    parse(html, story, subdir, x, nextchap)
end # (start).upto(max)

end # def crawl
end # module Crawler