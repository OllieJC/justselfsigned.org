function imgFallback() {
  const r = /\.(avif|heic|webp)$/;
  if (this.src.match(r)) {
    const newSrc = this.src.replace(r, ".png");
    console.log("newSrc:", newSrc);
    this.src = newSrc;
  }
}

function addImgFallback() {
  const eles = document.getElementsByClassName("img-fallback");
  for (var i = 0; i < eles.length; i++) {
    eles[i].onerror = imgFallback;
  }
}

function addCollapsible() {
  var coll = document.getElementsByClassName("collapsible");
  var i;
  for (i = 0; i < coll.length; i++) {
    coll[i].addEventListener("click", function() {
      this.classList.toggle("active");
      var content = this.nextElementSibling;
      if (content.style.display === "block") {
        content.style.display = "none";
      } else {
        content.style.display = "block";
      }
    });
  }
}


function onLoad() {
  document.body.classList.add("js-enabled");
  addImgFallback();
  addCollapsible();
}

onLoad();
