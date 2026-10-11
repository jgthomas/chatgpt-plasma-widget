import QtQuick
import QtTest
import "../package/contents/code/link-routing.js" as Links

TestCase {
    name: "LinkRouting"

    function test_routes_data() {
        const current = "https://chatgpt.com/c/current"
        return [
            {tag: "same chat fragment", target: current + "#message", expected: "embedded"},
            {tag: "same chat query", target: current + "?foo=bar", expected: "embedded"},
            {tag: "different chat", target: "https://chatgpt.com/c/other", expected: "embedded"},
            {tag: "project chat", target: "https://chatgpt.com/g/project/c/other", expected: "embedded"},
            {tag: "external same window", target: "https://example.org/", expected: "external"},
            {tag: "external new window", target: "https://example.org/", popup: true, expected: "external"},
            {tag: "same chat new window", target: current, popup: true, expected: "external"},
            {tag: "OpenAI ordinary page", target: "https://openai.com/", popup: true, expected: "external"},
            {tag: "ChatGPT ordinary popup", target: "https://chatgpt.com/", popup: true, expected: "external"},
            {tag: "sign in", target: "https://chatgpt.com/auth/login", expected: "embedded"},
            {tag: "auth popup", target: "https://auth.openai.com/authorize", popup: true, expected: "embedded"},
            {tag: "auth callback", target: "https://chatgpt.com/api/auth/callback/google", auth: true, expected: "embedded"},
            {tag: "Google login", target: "https://accounts.google.com/signin", auth: true, expected: "external"},
            {tag: "Apple login", target: "https://appleid.apple.com/auth/authorize", auth: true, expected: "external"},
            {tag: "Microsoft login", target: "https://login.microsoftonline.com/authorize", auth: true, expected: "external"},
            {tag: "Microsoft personal login", target: "https://login.live.com/", auth: true, expected: "external"},
            {tag: "Google ordinary link", target: "https://accounts.google.com/", expected: "external"},
            {tag: "unrecognised federated redirect", target: "https://company.example/login", auth: true, expected: "external"},
            {tag: "scripted external link during auth", target: "https://example.org/privacy", auth: true, expected: "external"},
            {tag: "ordinary link during auth", target: "https://example.org/privacy", auth: true, expected: "external"},
            {tag: "auth return", target: current, auth: true, expected: "embedded"},
            {tag: "pending auth popup return", target: current, auth: true, popup: true, expected: "embedded"},
            {tag: "established popup reload", target: current, expected: "embedded"},
            {tag: "established popup conversation link", target: "https://chatgpt.com/c/other", expected: "embedded"},
            {tag: "Google login popup", target: "https://accounts.google.com/signin", auth: true, popup: true, expected: "external"},
            {tag: "Apple login popup", target: "https://appleid.apple.com/auth/authorize", auth: true, popup: true, expected: "external"},
            {tag: "Microsoft login popup", target: "https://login.microsoftonline.com/authorize", auth: true, popup: true, expected: "external"},
            {tag: "blank popup", target: "about:blank", popup: true, expected: "pending"},
            {tag: "empty popup", target: "", popup: true, expected: "pending"},
            {tag: "mail link", target: "mailto:person@example.org", expected: "external"},
            {tag: "local file", target: "file:///tmp/test", popup: true, expected: "blocked"},
            {tag: "data popup", target: "data:text/html,hello", popup: true, expected: "blocked"},
            {tag: "lookalike domain", target: "https://chatgpt.com.example.org/auth/login", expected: "external"},
            {tag: "credentials", target: "https://chatgpt.com@example.org/auth/login", expected: "external"},
            {tag: "auth lookalike", target: "https://auth.openai.com.example.org/login", expected: "external"}
        ]
    }

    function test_routes(data) {
        compare(Links.route(data.target,
                            data.popup === true, data.auth === true), data.expected)
    }

    function test_popupAuthReturnThenConversationNavigation() {
        const view = {authInProgress: true}
        const popup = {destinationPending: true, visible: false,
                       dismiss: function() { fail("An established ChatGPT popup should stay open") }}
        function navigate(url) {
            Links.navigate({isMainFrame: true, url: url,
                            reject: function() { fail("ChatGPT navigation should be accepted") }},
                           view, popup, function() { fail("ChatGPT navigation should remain embedded") })
        }
        navigate("https://chatgpt.com/c/current")
        compare(view.authInProgress, false)
        compare(popup.destinationPending, false)
        compare(popup.visible, true)
        navigate("https://chatgpt.com/c/current") // Reload after login.
        navigate("https://chatgpt.com/c/other")
    }

    function test_externalNavigationDuringAuth_data() {
        return ["anchor", "script", "redirect", "form", "history", "reload"].map(
            (name, type) => ({tag: name, navigationType: type}))
    }

    function test_externalNavigationDuringAuth(data) {
        let rejected = false
        let dismissed = false
        let opened = ""
        const target = "https://example.org/privacy"
        Links.navigate({isMainFrame: true, url: target, navigationType: data.navigationType,
                        reject: function() { rejected = true }},
                       {authInProgress: true},
                       {destinationPending: false, dismiss: function() { dismissed = true }},
                       function(url) { opened = url })
        compare(rejected, true)
        compare(dismissed, true)
        compare(opened, target)
    }

    function test_pendingBlockedDestinationDismissed() {
        let dismissed = false
        let rejected = false
        Links.navigate({isMainFrame: true, url: "file:///tmp/test",
                        reject: function() { rejected = true }},
                       {authInProgress: false},
                       {destinationPending: true, visible: false,
                        dismiss: function() { dismissed = true }},
                       function() { fail("Blocked URLs must not launch an external handler") })
        compare(rejected, true)
        compare(dismissed, true)
    }
}
