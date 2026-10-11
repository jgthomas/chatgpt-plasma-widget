.pragma library

function parts(url) {
    // QML supplies absolute QUrls. Reject credentials and explicit ports
    // when deciding whether a URL belongs to the embedded application.
    const match = /^(https?):\/\/([^/?#]+)([^?#]*)(?:\?[^#]*)?(?:#.*)?$/i.exec(String(url))
    if (!match) return null
    return { scheme: match[1].toLowerCase(), host: match[2].toLowerCase(), path: match[3] || "/" }
}

function isChat(url) {
    const p = parts(url)
    return p !== null && p.scheme === "https"
        && ["chatgpt.com", "chat.openai.com"].includes(p.host)
}

function isAuth(url) {
    const p = parts(url)
    if (!p || p.scheme !== "https") return false
    return ["auth.openai.com", "auth0.openai.com"].includes(p.host)
        || (isChat(url) && /^\/(?:auth|api\/auth)(?:\/|$)/i.test(p.path))
}

function isBlank(url) {
    return !String(url) || String(url) === "about:blank"
}

// Returns embedded, external, pending (a destination-less popup), or blocked.
function route(target, newWindow, authContext) {
    if (isBlank(target)) return newWindow ? "pending" : "embedded"
    if (/^(?:javascript|data|file|qrc|blob|about):/i.test(String(target))) return "blocked"
    if (isAuth(target)) return "embedded"
    // Authentication may return to ChatGPT in a pending popup. External
    // providers, scripted navigation and redirects get no embedded exception.
    if (authContext && isChat(target)) return "embedded"
    if (newWindow) return "external"
    if (isChat(target)) return "embedded"
    return "external"
}

function navigate(request, view, popup, openExternal) {
    // Frames (including authentication challenges) do not replace the page.
    if (!request.isMainFrame) return
    const decision = route(request.url, popup !== null && popup.destinationPending,
                           view.authInProgress)
    if (decision === "external" || decision === "blocked") {
        request.reject()
        if (decision === "external") openExternal(request.url)
        if (popup) popup.dismiss()
        return
    }
    if (isBlank(request.url)) return
    view.authInProgress = isAuth(request.url)
    if (popup) {
        popup.destinationPending = false
        popup.visible = true
    }
}
