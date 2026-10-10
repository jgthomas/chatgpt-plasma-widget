(() => {
    if (!["chatgpt.com", "chat.openai.com"].includes(location.hostname)) {
        return;
    }

    const marker = "data-plasma-chatgpt-scroll-focus";
    const style = document.createElement("style");
    // ChatGPT paints its keyboard-focus ring as an inset box shadow.
    style.textContent = `[${marker}]:focus {
        outline: none !important;
        box-shadow: none !important;
    }`;
    document.head.appendChild(style);

    function updateFocusStyle(element) {
        if (!(element instanceof HTMLElement)) {
            return;
        }
        element.removeAttribute(marker);

        // Keep focus indicators on interactive controls, including the composer.
        if (!element.matches("main, div, section, article")
                || element.closest('a, button, input, textarea, select, [role="button"], [role="textbox"], [role="combobox"], [role="listbox"]')
                || element.isContentEditable) {
            return;
        }
        const main = document.querySelector('main, [role="main"]');
        if (!main || !(main.contains(element) || element.contains(main))) {
            return;
        }
        const overflow = getComputedStyle(element).overflowY;
        if (["auto", "scroll"].includes(overflow) && element.scrollHeight > element.clientHeight) {
            // Hide focus decoration without changing focus or native scrolling.
            element.setAttribute(marker, "");
        }
    }

    document.addEventListener("focusin", event => updateFocusStyle(event.target));
    document.addEventListener("focusout", event => {
        if (event.target instanceof HTMLElement) {
            event.target.removeAttribute(marker);
        }
    });
    updateFocusStyle(document.activeElement);
})();
