(function() {
    'use strict';
    function uncheck(toggle) {
        if (toggle.hasAttribute('checked')) {
            toggle.click();
        }
    }

    function disableAfterLoad() {
        var autoplayToggle = document.getElementById('toggle');
        if (autoplayToggle) {
            uncheck(autoplayToggle);
        } else {
            setTimeout(disableAfterLoad, 500);
        }
    }

    disableAfterLoad();
})();