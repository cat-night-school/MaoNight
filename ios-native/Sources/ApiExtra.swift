import Foundation

/// 猫夜后端接口（第二组）：聊天、排行、商城、留言板、好友、在线、赛季、积分、玩家资料、签到等。
/// 统一走 `{ ok, data }` 解包，字段做容错。
extension Api {

    // MARK: - 基础

    /// 通用调用：completion 拿到解包后的 data 字典。
    static func call(_ method: String, _ path: String, _ body: [String: Any]?,
                     completion: @escaping ([String: Any]?, String?) -> Void) {
        request(method, path, body: body, completion: completion)
    }

    static func string(_ map: [String: Any]?, _ key: String) -> String {
        guard let v = map?[key] else { return "" }
        if let s = v as? String { return s }
        if let n = v as? NSNumber { return n.stringValue }
        return String(describing: v)
    }

    static func int(_ map: [String: Any]?, _ key: String) -> Int {
        guard let v = map?[key] else { return 0 }
        if let n = v as? NSNumber { return n.intValue }
        if let s = v as? String { return Int(s) ?? 0 }
        return 0
    }

    static func array(_ map: [String: Any]?, _ key: String) -> [[String: Any]] {
        guard let raw = map?[key] as? [Any] else { return [] }
        return raw.compactMap { $0 as? [String: Any] }
    }

    // MARK: - 聊天室

    static func chat(limit: Int = 80, completion: @escaping ([[String: Any]]?, String?) -> Void) {
        call("GET", "/api/chat?limit=\(limit)", nil) { data, err in
            if let err = err { completion(nil, err); return }
            let list = Api.array(data, "messages")
            if list.isEmpty { completion(Api.array(data, "list"), nil) } else { completion(list, nil) }
        }
    }

    static func sendChat(text: String, completion: @escaping (Bool, String?) -> Void) {
        let me = AuthStore.account?.loginName ?? ""
        call("POST", "/api/chat", ["acc": me, "text": text]) { data, err in
            completion(err == nil, err)
        }
    }

    // MARK: - 排行榜

    static func rank(by: String = "coin", completion: @escaping ([[String: Any]]?, String?) -> Void) {
        call("GET", "/api/rank?by=\(by)", nil) { data, err in
            if let err = err { completion(nil, err); return }
            let list = Api.array(data, "list")
            completion(list.isEmpty ? Api.array(data, "rank") : list, nil)
        }
    }

    // MARK: - 商城

    static func shop(completion: @escaping ([[String: Any]]?, String?) -> Void) {
        call("GET", "/api/shop", nil) { data, err in
            if let err = err { completion(nil, err); return }
            completion(Api.array(data, "items"), nil)
        }
    }

    static func buy(itemId: String, completion: @escaping (Bool, String?) -> Void) {
        let me = AuthStore.account?.loginName ?? ""
        call("POST", "/api/shop/buy", ["acc": me, "id": itemId]) { _, err in
            completion(err == nil, err)
        }
    }

    // MARK: - 留言板

    static func board(completion: @escaping ([[String: Any]]?, String?) -> Void) {
        call("GET", "/api/board", nil) { data, err in
            if let err = err { completion(nil, err); return }
            let list = Api.array(data, "list")
            completion(list.isEmpty ? Api.array(data, "messages") : list, nil)
        }
    }

    static func postBoard(text: String, completion: @escaping (Bool, String?) -> Void) {
        let me = AuthStore.account?.loginName ?? ""
        self.call("POST", "/api/board", ["acc": me, "text": text]) { _, err in
            completion(err == nil, err)
        }
    }

    // MARK: - 好友 / 私聊

    static func friends(completion: @escaping ([[String: Any]]?, String?) -> Void) {
        call("GET", "/api/friends", nil) { data, err in
            if let err = err { completion(nil, err); return }
            let list = Api.array(data, "list")
            completion(list.isEmpty ? Api.array(data, "friends") : list, nil)
        }
    }

    static func friendRequest(acc: String, completion: @escaping (Bool, String?) -> Void) {
        let me = AuthStore.account?.loginName ?? ""
        self.call("POST", "/api/friends/request", ["acc": me, "target": acc]) { _, err in
            completion(err == nil, err)
        }
    }

    static func messages(with acc: String, completion: @escaping ([[String: Any]]?, String?) -> Void) {
        let me = AuthStore.account?.loginName ?? ""
        call("GET", "/api/messages?with=\(acc.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? acc)&acc=\(me.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? me)", nil) { data, err in
            if let err = err { completion(nil, err); return }
            completion(Api.array(data, "messages"), nil)
        }
    }

    static func sendMessage(to: String, text: String, completion: @escaping (Bool, String?) -> Void) {
        let me = AuthStore.account?.loginName ?? ""
        self.call("POST", "/api/messages", ["acc": me, "to": to, "with": to, "text": text]) { _, err in
            completion(err == nil, err)
        }
    }

    // MARK: - 在线 / 玩家

    static func online(completion: @escaping ([[String: Any]]?, String?) -> Void) {
        call("GET", "/api/online", nil) { data, err in
            if let err = err { completion(nil, err); return }
            let list = Api.array(data, "list")
            completion(list.isEmpty ? Api.array(data, "online") : list, nil)
        }
    }

    static func player(acc: String, completion: @escaping ([String: Any]?, String?) -> Void) {
        call("GET", "/api/player?acc=\(acc.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? acc)", nil) { data, err in
            completion(data, err)
        }
    }

    // MARK: - 赛季

    static func season(completion: @escaping ([String: Any]?, String?) -> Void) {
        call("GET", "/api/season", nil) { data, err in
            completion(data, err)
        }
    }

    static func seasonMe(completion: @escaping ([String: Any]?, String?) -> Void) {
        let me = AuthStore.account?.loginName ?? ""
        call("GET", "/api/season/me?acc=\(me.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? me)", nil) { data, err in
            completion(data, err)
        }
    }

    static func seasonSignup(completion: @escaping (Bool, String?) -> Void) {
        let me = AuthStore.account?.loginName ?? ""
        call("POST", "/api/season/signup", ["acc": me]) { _, err in
            completion(err == nil, err)
        }
    }

    static func seasonClaim(completion: @escaping (Bool, String?) -> Void) {
        let me = AuthStore.account?.loginName ?? ""
        call("POST", "/api/season/claim", ["acc": me]) { _, err in
            completion(err == nil, err)
        }
    }

    // MARK: - 积分 / 小鱼干

    static func points(completion: @escaping ([String: Any]?, String?) -> Void) {
        let me = AuthStore.account?.loginName ?? ""
        call("GET", "/api/points?acc=\(me.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? me)", nil) { data, err in
            completion(data, err)
        }
    }

    static func pointsSignin(completion: @escaping (Bool, String?) -> Void) {
        let me = AuthStore.account?.loginName ?? ""
        call("POST", "/api/points/signin", ["acc": me]) { _, err in
            completion(err == nil, err)
        }
    }

    static func pointsExchange(amount: Int, completion: @escaping (Bool, String?) -> Void) {
        let me = AuthStore.account?.loginName ?? ""
        call("POST", "/api/points/exchange", ["acc": me, "amount": amount]) { _, err in
            completion(err == nil, err)
        }
    }

    // MARK: - 卡密 / 公告 / 健康

    static func redeem(code: String, completion: @escaping ([String: Any]?, String?) -> Void) {
        let me = AuthStore.account?.loginName ?? ""
        call("POST", "/api/redeem", ["acc": me, "code": code]) { data, err in
            completion(data, err)
        }
    }

    static func notices(completion: @escaping ([[String: Any]]?, String?) -> Void) {
        call("GET", "/api/notices", nil) { data, err in
            if let err = err { completion(nil, err); return }
            completion(Api.array(data, "list"), nil)
        }
    }

    static func health(completion: @escaping (Bool, String, Int) -> Void) {
        let start = Date()
        call("GET", "/api/health", nil) { data, err in
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            let ok = err == nil && data != nil
            completion(ok, err ?? "连接成功", ms)
        }
    }

    static func ping(completion: @escaping (Int) -> Void) {
        let start = Date()
        call("GET", "/api/health", nil) { _, _ in
            completion(Int(Date().timeIntervalSince(start) * 1000))
        }
    }

    static func integrity(completion: @escaping (Bool, String?) -> Void) {
        call("GET", "/api/integrity", nil) { data, err in
            if let err = err { completion(false, err); return }
            let ok = (data?["ok"] as? Bool) ?? true
            completion(ok, Api.string(data, "message"))
        }
    }
}

// MARK: - 联机房间（五子棋）

extension Api {
    static func roomCreate(completion: @escaping ([String: Any]?, String?) -> Void) {
        call("POST", "/api/rooms", nil) { data, err in
            completion((data?["room"] as? [String: Any]), err)
        }
    }

    static func roomJoin(id: String, completion: @escaping ([String: Any]?, String?) -> Void) {
        call("POST", "/api/rooms/join", ["id": id]) { data, err in
            completion((data?["room"] as? [String: Any]), err)
        }
    }

    static func roomState(id: String, completion: @escaping ([String: Any]?, String?) -> Void) {
        call("GET", "/api/rooms/state?id=" + (id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? id), nil) { data, err in
            completion((data?["room"] as? [String: Any]), err)
        }
    }

    static func roomMove(id: String, x: Int, y: Int, completion: @escaping ([String: Any]?, String?) -> Void) {
        call("POST", "/api/rooms/move", ["id": id, "x": x, "y": y]) { data, err in
            completion((data?["room"] as? [String: Any]), err)
        }
    }
}