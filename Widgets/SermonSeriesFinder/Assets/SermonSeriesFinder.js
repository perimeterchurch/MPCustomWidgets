function initializeSermonSeriesFinder() {
    var seriesCards = document.querySelectorAll('.series-card');
    var loadMoreButton = document.getElementById('loadMore');
    var maxItems = 12;
    var hideClass = 'hide-sermon';

    seriesCards.forEach(function(card, index) {
        if (index >= maxItems) {
            card.classList.add(hideClass);
        }
    });

    if (loadMoreButton) {
        loadMoreButton.addEventListener('click', function() {
            var hiddenCards = document.querySelectorAll('.' + hideClass);
            for (var i = 0; i < maxItems && i < hiddenCards.length; i++) {
                hiddenCards[i].classList.remove(hideClass);
            }
            if (document.querySelectorAll('.' + hideClass).length === 0) {
                loadMoreButton.style.display = 'none';
            }
        });
    }
}

// Polling function to wait for an element to appear
function waitForElementToDisplay(selector, time) {
    if (document.querySelector(selector) != null) {
        initializeSermonSeriesFinder();
        return;
    }
    else {
        setTimeout(function() {
            waitForElementToDisplay(selector, time);
        }, time);
    }
}

// Start polling for the element
waitForElementToDisplay(".series-card", 200); // Use a selector that matches your dynamic content