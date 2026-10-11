import SwiftUI
import WebKit

struct HealthDashboard: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "pulseHealth")
        // Installed only in the native app, never on the public website.
        let script = """
        (() => {
          const pending = new Map(); let next = 0;
          window.PulseHealth = {
            request(date) {
              const id = String(++next);
              return new Promise((resolve, reject) => {
                const timer = setTimeout(() => { pending.delete(id); reject(new Error('Apple Health antwortet nicht. Bitte erneut versuchen.')); }, 120000);
                pending.set(id, { resolve, reject, timer });
                window.webkit.messageHandlers.pulseHealth.postMessage({ id, date });
              });
            },
            receive(message) {
              const p = pending.get(message.id); if (!p) return;
              clearTimeout(p.timer); pending.delete(message.id);
              message.error ? p.reject(new Error(message.error)) : p.resolve(message.data);
            }
          };
        })();
        """
        controller.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 0.04, green: 0.055, blue: 0.06, alpha: 1)
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.navigationDelegate = context.coordinator
        if let file = Bundle.main.url(forResource: "dashboard", withExtension: "html") {
            web.loadFileURL(file, allowingReadAccessTo: file.deletingLastPathComponent())
        } else {
            web.loadHTMLString("<html><body style='background:#101416;color:white;font-family:system-ui;padding:30px'>Dashboard fehlt. Bitte npm run build:ios ausführen und die App erneut bauen.</body></html>", baseURL: nil)
        }
        return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    static func dismantleUIView(_ web: WKWebView, coordinator: Coordinator) {
        web.configuration.userContentController.removeScriptMessageHandler(forName: "pulseHealth")
    }
    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        private let health = HealthReader()
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.frameInfo.isMainFrame,
                  message.frameInfo.request.url?.isFileURL == true,
                  let body = message.body as? [String: Any],
                  let id = body["id"] as? String,
                  let date = body["date"] as? String,
                  let web = message.webView else { return }
            health.read(dateString: date) { result in
                var response: [String: Any] = ["id": id]
                switch result {
                case .success(let data): response["data"] = data
                case .failure(let error): response["error"] = error.localizedDescription
                }
                guard let json = try? JSONSerialization.data(withJSONObject: response),
                      let text = String(data: json, encoding: .utf8) else { return }
                DispatchQueue.main.async { web.evaluateJavaScript("window.PulseHealth.receive(\(text))", completionHandler: nil) }
            }
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Never load remote content into a web view with the HealthKit bridge.
            guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
            if url.isFileURL || url.scheme == "about" { decisionHandler(.allow); return }
            decisionHandler(.cancel)
            if url.scheme == "https" { UIApplication.shared.open(url) }
        }
    }
}
