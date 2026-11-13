import Foundation
import UIKit

/// 猫夜账号（服务器返回字段，全部用可选值兜底）。
struct Account: Codable {
    var acc: String?
    var account: String?
    var nick: String?
    var role: String?
    var coin: Int?
    var fish: Int?
    var title: String?

    /// 登录名：服务器不同版本用 acc / account 两种字段。
    var loginName: String { return acc ?? account ?? "" }
}

/// 本地会话：token + 账号快照，存 UserDefaults（原生版，不依赖网页存储）。
enum AuthStore {
    private static let tokenKey = "mn.token"
    private static let accountKey = "mn.account"

    static var token: String? {
        get { return UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }

    static var account: Account? {
        get {
            guard let data = UserDefaults.standard.data(forKey: accountKey) else { return nil }
            return try? JSONDecoder().decode(Account.self, from: data)
        }
        set {
            if let v = newValue, let data = try? JSONEncoder().encode(v) {
                UserDefaults.standard.set(data, forKey: accountKey)
            } else {
                UserDefaults.standard.removeObject(forKey: accountKey)
            }
        }
    }

    static var loggedIn: Bool { return token?.isEmpty == false }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: accountKey)
    }
}

/// 猫夜后端接口（和 Windows 原生版同一个服务器）。
/// 返回统一是 `{ ok, data: { ... } }`，这里统一拆掉外层 data。
enum Api {
    static let base = URL(string: "https://maoye-api.netlify.app")!

    private static func deviceId() -> String {
        if let id = UIDevice.current.identifierForVendor?.uuidString { return "ios-" + id }
        return "ios-unknown"
    }

    static func request(_ method: String, _ path: String,
                                body: [String: Any]?,
                                completion: @escaping ([String: Any]?, String?) -> Void) {
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = method
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("MaonightNative-iOS", forHTTPHeaderField: "User-Agent")
        if let token = AuthStore.token, !token.isEmpty {
            req.addValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        req.timeoutInterval = 15
        URLSession.shared.dataTask(with: req) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, "网络错误：" + error.localizedDescription)
                    return
                }
                guard let data = data,
                      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    completion(nil, "服务器返回格式不对")
                    return
                }
                if let ok = root["ok"] as? Bool, ok == false {
                    let msg = (root["msg"] as? String) ?? (root["error"] as? String) ?? (root["message"] as? String) ?? "请求失败"
                    completion(nil, msg)
                    return
                }
                // 统一拆掉外层 data
                if let payload = root["data"] as? [String: Any] {
                    completion(payload, nil)
                } else {
                    completion(root, nil)
                }
            }
        }.resume()
    }

    /// 登录：worker 用 acc/pwd，本机 server.js 用 account/password，四个都发。
    static func login(acc: String, pwd: String, completion: @escaping (Bool, String?) -> Void) {
        let body: [String: Any] = [
            "acc": acc,
            "pwd": pwd,
            "account": acc,
            "password": pwd,
            "deviceFingerprint": deviceId()
        ]
        request("POST", "/api/login", body: body) { payload, error in
            if let error = error { completion(false, error); return }
            guard let payload = payload,
                  let token = payload["token"] as? String, !token.isEmpty,
                  let accountObj = payload["account"] as? [String: Any] else {
                completion(false, "登录失败：服务器没有返回 token")
                return
            }
            AuthStore.token = token
            if let data = try? JSONSerialization.data(withJSONObject: accountObj),
               let account = try? JSONDecoder().decode(Account.self, from: data) {
                AuthStore.account = account
            }
            completion(true, nil)
        }
    }

    /// 拉最新资料（余额、头衔等）。
    static func refreshProfile(completion: @escaping (Account?) -> Void) {
        guard AuthStore.token != nil else { completion(nil); return }
        request("GET", "/api/me", body: nil) { payload, _ in
            guard let payload = payload,
                  let accountObj = payload["account"] as? [String: Any],
                  let data = try? JSONSerialization.data(withJSONObject: accountObj),
                  let account = try? JSONDecoder().decode(Account.self, from: data) else {
                completion(nil)
                return
            }
            AuthStore.account = account
            completion(account)
        }
    }
}
