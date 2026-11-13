import Foundation

/// 猫夜账号（服务器返回字段，全部用可选值兜底）。
struct Account: Codable {
    var acc: String?
    var nick: String?
    var role: String?
    var coin: Int?
    var fish: Int?
    var title: String?
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
enum Api {
    static let base = URL(string: "https://maoye-api.netlify.app")!

    private static func post(_ path: String, _ body: [String: Any], token: String?,
                             completion: @escaping ([String: Any]?, String?) -> Void) {
        var request = URLRequest(url: base.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = token { request.addValue("Bearer " + t, forHTTPHeaderField: "Authorization") }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, "网络错误：" + error.localizedDescription)
                    return
                }
                guard let data = data,
                      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    completion(nil, "服务器返回格式不对")
                    return
                }
                if let ok = obj["ok"] as? Bool, ok == false {
                    completion(nil, (obj["error"] as? String) ?? "请求失败")
                    return
                }
                completion(obj, nil)
            }
        }.resume()
    }

    /// 登录：成功后存 token 与账号。
    static func login(acc: String, pwd: String, completion: @escaping (Bool, String?) -> Void) {
        let body: [String: Any] = ["acc": acc, "pwd": pwd, "deviceFingerprint": "ios-native"]
        post("/api/login", body, token: nil) { obj, error in
            if let error = error { completion(false, error); return }
            guard let obj = obj,
                  let token = obj["token"] as? String,
                  let accountObj = obj["account"] as? [String: Any] else {
                completion(false, "登录失败：缺少 token")
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
        guard let token = AuthStore.token else { completion(nil); return }
        post("/api/me", [:], token: token) { obj, _ in
            guard let obj = obj,
                  let accountObj = (obj["account"] as? [String: Any]) ?? obj["me"] as? [String: Any] else {
                completion(nil)
                return
            }
            if let data = try? JSONSerialization.data(withJSONObject: accountObj),
               let account = try? JSONDecoder().decode(Account.self, from: data) {
                AuthStore.account = account
                completion(account)
            } else {
                completion(nil)
            }
        }
    }
}
