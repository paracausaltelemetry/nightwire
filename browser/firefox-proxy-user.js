// Nightwire proxy browser profile.
// Intended for authorized CTF/lab testing with Burp Suite or OWASP ZAP on 127.0.0.1:8080.
user_pref("network.proxy.type", 1);
user_pref("network.proxy.http", "127.0.0.1");
user_pref("network.proxy.http_port", 8080);
user_pref("network.proxy.ssl", "127.0.0.1");
user_pref("network.proxy.ssl_port", 8080);
user_pref("network.proxy.no_proxies_on", "localhost, 127.0.0.1, ::1");
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("security.enterprise_roots.enabled", true);
user_pref("devtools.toolbox.host", "right");
user_pref("devtools.chrome.enabled", true);
user_pref("devtools.debugger.remote-enabled", true);
