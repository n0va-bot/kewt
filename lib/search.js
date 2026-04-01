document.addEventListener("DOMContentLoaded", function () {
  var params = new URLSearchParams(window.location.search);
  var query = params.get("q");
  var box = document.getElementById("search-box");
  var resultsContainer = document.getElementById("search-results-list");

  if (box && query) box.value = query;

  if (!query) {
    resultsContainer.innerHTML = "<p>Enter a search term above.</p>";
    return;
  }

  fetch("/search.json")
    .then(function (response) {
      return response.json();
    })
    .then(function (data) {
      var q = query.toLowerCase();
      var results = data.filter(function (item) {
        return (
          item.title.toLowerCase().indexOf(q) !== -1 ||
          item.content.toLowerCase().indexOf(q) !== -1
        );
      });

      var esc = query.replace(/</g, "&lt;").replace(/>/g, "&gt;");

      if (results.length === 0) {
        resultsContainer.innerHTML =
          '<p>No results found for "<strong>' + esc + '</strong>".</p>';
        return;
      }

      var html =
        "<p>Found " +
        results.length +
        ' result(s) for "<strong>' +
        esc +
        '</strong>":</p>';
      results.forEach(function (result) {
        var snippet = result.content.substring(0, 200);
        if (result.content.length > 200) snippet += "...";
        html += '<div class="search-result">';
        html += '<a href="' + result.url + '">' + result.title + "</a>";
        if (snippet) html += "<p>" + snippet + "</p>";
        html += "</div>";
      });
      resultsContainer.innerHTML = html;
    })
    .catch(function () {
      resultsContainer.innerHTML = "<p>Error loading search index.</p>";
    });
});
