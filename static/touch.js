if (window.innerWidth >= 800) {
    var imgs = document.getElementsByTagName("img")
    for (var x, i = 0; i < imgs.length; i++) {
        x = imgs[i].getAttribute("origin")
        if (x) { imgs[i].src = x }
        console.log(imgs[i].src)
    }
}

var atBottom = false

function toNextchap() {
    document.location.href = document.getElementsByClassName("nextchap")[0].href
}

// document.getElementsByTagName("main")[0]
document.documentElement.addEventListener("click", function (event) {
    if (event.clientY < window.innerHeight*0.20 &&
        event.clientX > window.innerWidth*0.40 &&
        event.clientX < window.innerWidth*0.60 ) { // scroll to top
        window.scrollTo(0, 0)
    }
    if (event.clientY > window.innerHeight*0.80 &&
        event.clientX > window.innerWidth*0.40 &&
        event.clientX < window.innerWidth*0.60 ) { // scroll to bottom
        if (atBottom) { toNextchap() }
        window.scrollTo(0, document.documentElement.scrollHeight)
    }
    if (event.clientY < window.innerHeight*0.33) { // scroll up
        window.scrollBy(0, -window.innerHeight*0.75)
    } else { // scroll down
        if (atBottom) { toNextchap() }
        window.scrollBy(0, window.innerHeight*0.75)
    }
})

window.onscroll = function() {
    atBottom = window.innerHeight + window.scrollY >= document.body.offsetHeight
}
