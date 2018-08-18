# OPTIMIZE FOR 3G

- After Dark Hugo Theme https://git.habd.as/comfusion/after-dark/
- Better Portable Graphics (BPG) image format https://bellard.org/bpg/
- WebP image format for Chrome and Android offline (downloaded) viewing

# OPTIMIZE FOR TOUCH SCREEN

- Pre-load/render next page
- Hold to popup chapters selection
- Touch to scroll
```
+---------+---------+---------+
|         | to      |         |
|         | top     |         |
|         +---------+         |
|          scroll up          |
+- - - - - - - - - - - - - - -+
|                             |
|                             |
|          scroll down (*)    |
|                             |
|                             |
|         +---------+         |
|         | to (*)  |         |
|         | bottom  |         |
+---------+---------+---------+
(*) next chap if at bottom of the page
```
# Let starts
## Init a new hugo site using after-dark theme
- https://themes.gohugo.io/after-dark/
- https://hackcabin.com/
```
hugo new site doctruyen
cd doctruyen
git init .
git submodule add -f https://git.habd.as/comfusion/after-dark.git themes/after-dark
```
## Better Portable Graphics
BPG is smaller and better then WebP, JPG ... [See comparisions]( https://xooyoozoo.github.io/yolo-octo-bugfixes/#vintage-car&webp=s&bpg=t)
- Encoder/decoder https://webencoder.libbpg.org/
- Viewer https://github.com/asimba/pybpgviewer/releases
```
brew info libbpg
# -> found "--with-jctvc" option (Enable built-in JCTVC encoder - Mono threaded, slower but produce smaller file) https://hevc.hhi.fraunhofer.de/
brew search libbpg
brew install libbpg --with-jctvc

git clone https://github.com/mirrorer/libbpg.git
cd libbpg
git checkout 47f4357d6d36e21c5f0949314dcf9d2ecbf8012f
# -> HEAD is now at 47f4357 0.9.6
make install prefix=/usr/local/Cellar/libbpg/0.9.8 CONFIG_APPLE=y USE_JCTVC=y

# https://github.com/def-/libbpg/issues/2
brew reinstall libbpg --with-jctvc
brew install imagemagick
convert 2.jpg -resize 680 2.png
bpgenc -e jctvc -o 2.bpg 2.png
```

## WebP Image Format
- https://caniuse.com/#search=webp not supported by iOS Safari
- https://www.philipstorry.net/thoughts/bpg-vs-jpeg-vs-webp-vs-jpeg-xr
- https://developers.google.com/speed/webp/docs/using
- https://github.com/chase-moskal/webp-hero # javascript polyfill
```
brew install webp
cd doctruyen/content/yeu-than-ky/chapter-1/
convert 600d71ef5e7058d695681a8c8be84df5.jpg -resize 680 600d71ef5e7058d695681a8c8be84df5.png
bpgenc -e jctvc -q 32 600d71ef5e7058d695681a8c8be84df5.png
cwebp -q 80 600d71ef5e7058d695681a8c8be84df5.png -o 600d71ef5e7058d695681a8c8be84df5.webp
ls -lh 600d71ef5e7058d695681a8c8be84df5.* out.*
# webp-q-60: 101K, webp-q-80: 128K, bpg-q-35: 52K, bpg-q-32: 67K, bpg-q-29: 83K, jpg: 839K
```
- _BPG is around %50 smaller than WebP_
- _WebP encoder is 50-100 times faster than BPG_

## Offline?
- https://css-tricks.com/serviceworker-for-offline/
- https://inviqa.com/blog/service-workers-guide-building-offline-web-experiences

Limitation ([link here](https://developers.google.com/web/ilt/pwa/live-data-in-the-service-worker#how_much_can_you_store))
- Mobile Safari: 50MB
- Chrome, Opera, and Samsung Internet: [Up to quota](https://www.html5rocks.com/en/tutorials/offline/quota-research/#toc-android)

_=> Good for offline UX, for caching a lot of images export a download list then import to downloaders_

## Android images downloaders / bpg viewers
- https://play.google.com/store/apps/details?id=com.dv.adm&rdid=com.dv.adm
    - "Advanced Download Manager" support "import list of links from a text file"
- https://play.google.com/store/apps/details?id=com.rookiestudio.perfectviewer.plugin.image
- https://github.com/alexandruc/android-bpg

## Try Djvu for scanned images
Typical DjVu file sizes are as follows:
- bitonal scanned documents: 5 to 30KB per page at 300dpi (3 to 10 times smaller than PDF or TIFF)
- color scanned documents: 30 to 100KB per page at 300dpi (5 to 10 times smaller than JPEG).
```
brew search djvu
# ==> Formulae: djvu2pdf djvulibre minidjvu
# djvulibre: primary DjVu support library
# minidjvu: command line utility which encodes and decodes single page black-and-white DjVu files
brew install djvulibre
brew cask install djview
wget http://1.bp.blogspot.com/-o1AISH0SJ18/WGriT9vRI-I/AAAAAAAABw8/vx4mx6RPyII/s0/22.jpg
convert 22.jpg -resize 680 22.jpg
c44 22.jpg
convert 22.jpg 22.png
bpgenc -e jctvc -q 32 -o 22.bpg 22.png
cwebp -q 60 22.png -o 22.webp
# djvu: 167k, bpg: 89k, webp: 111k, jpg: 224k
```

## Pre-load/render next page
- https://css-tricks.com/prerender-on-hover/
- https://caniuse.com/#feat=link-rel-prerender
- https://jack.ofspades.com/prefetching-preloading-and-prerendering-content-with-html/index.html
- https://stackoverflow.com/questions/10568888/preload-second-page-while-viewing-the-current-page
- https://github.com/dieulot/instantclick
- https://github.com/turbolinks/turbolinks

## Duplicate image detection
- https://www.mikeperham.com/2010/05/21/detecting-duplicate-images-with-phashion/
- https://github.com/toy/pHash
```
cp phash.rb /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/
brew install phash --disable-video-hash --disable-audio-hash
cd resources/junk/
irb
```
```ruby
require 'phash/image'
z = Phash::Image.new('resources/junk/01.jpg')
z.phash.data
x = Phash::Image.new('resources/junk/02.jpg')
z.similarity(x)
z.phash.similarity(x.phash)
z.phash.data # => 1446821432701327343
y = Phash::ImageHash.new(1446821432701327343)
y.similarity(x.phash)
Dir["resources/junk/*.jpg"].each do |jpg|
	puts Phash::Image.new(jpg).phash.data
end
```
```
cd resources/junk/_footers/
convert 0.png -crop 800x100+0+112\! 0_800x100.png
```
# Sources
- https://hamtruyen.com/doc-truyen/bach-luyen-thanh-than-chapter-1.html
- http://truyensieuhay.com/doc-truyen/dau-pha-thuong-khung-chapter-1.html
- http://comicvn.net/truyen-tranh-online/fairy-tail-nhiem-vu-tram-nam/chapter-1-325169

# Utilities
```
git add . && git commit -am "update" && git push
cd public
python -m SimpleHTTPServer
```

https://stackoverflow.com/questions/9683279/make-the-current-commit-the-only-initial-commit-in-a-git-repository
```
rm -rf .git
git init
git add .
git commit -m "update"
git remote add origin https://github.com/tamedu/doctruyen.git
git push -u --force origin master
```

https://git-lfs.github.com/
```
brew install git-lfs
git lfs track "*.webp"
git add .gitattributes

```