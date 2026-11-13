import UIKit

/// 登录页：照片背景 + 玻璃卡片，原生输入框和按钮，登录成功后进首页。
final class LoginViewController: UIViewController, UITextFieldDelegate {
    private let logoRing = UIView()
    private let logoLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let card = GlassCard()
    private let accountLabel = UILabel()
    private let accountField = UITextField()
    private let passwordLabel = UILabel()
    private let passwordField = UITextField()
    private let loginButton = AccentButton()
    private let hintLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        Theme.installBackground(view)

        logoRing.backgroundColor = UIColor(red: 0.98, green: 0.95, blue: 0.90, alpha: 1)
        logoRing.layer.cornerRadius = 38
        logoRing.layer.cornerCurve = .continuous
        logoRing.layer.borderWidth = 2
        logoRing.layer.borderColor = UIColor(white: 1, alpha: 0.5).cgColor
        view.addSubview(logoRing)

        logoLabel.text = "猫"
        logoLabel.textColor = UIColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 1)
        logoLabel.font = Theme.font(34, true)
        logoLabel.textAlignment = .center
        logoRing.addSubview(logoLabel)

        titleLabel.text = "猫夜"
        titleLabel.textColor = Theme.ink
        titleLabel.font = Theme.font(28, true)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        subtitleLabel.text = "猫猫们的秘密基地 · 原生版"
        subtitleLabel.textColor = Theme.muted
        subtitleLabel.font = Theme.font(13)
        subtitleLabel.textAlignment = .center
        view.addSubview(subtitleLabel)

        view.addSubview(card)

        accountLabel.text = "账号"
        accountLabel.textColor = Theme.ink
        accountLabel.font = Theme.font(12, true)
        card.addSubview(accountLabel)

        style(accountField, placeholder: "请输入账号")
        accountField.keyboardType = .asciiCapable
        accountField.delegate = self
        card.addSubview(accountField)

        passwordLabel.text = "密码"
        passwordLabel.textColor = Theme.ink
        passwordLabel.font = Theme.font(12, true)
        card.addSubview(passwordLabel)

        style(passwordField, placeholder: "请输入密码")
        passwordField.isSecureTextEntry = true
        passwordField.delegate = self
        card.addSubview(passwordField)

        loginButton.setTitle("登录", for: .normal)
        loginButton.addTarget(self, action: #selector(tapLogin), for: .touchUpInside)
        card.addSubview(loginButton)

        hintLabel.text = "账号数据存在云端，可在任意设备登录"
        hintLabel.textColor = Theme.faint
        hintLabel.font = Theme.font(11)
        hintLabel.textAlignment = .center
        view.addSubview(hintLabel)
    }

    private func style(_ field: UITextField, placeholder: String) {
        field.backgroundColor = UIColor(white: 0, alpha: 0.30)
        field.textColor = Theme.ink
        field.font = Theme.font(15)
        field.layer.cornerRadius = Theme.radiusInner
        field.layer.cornerCurve = .continuous
        field.layer.borderWidth = 1
        field.layer.borderColor = Theme.strokeSoft.cgColor
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: Theme.faint]
        )
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.leftView = pad
        field.leftViewMode = .always
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Theme.layoutBackground(view)
        let w = view.bounds.width
        let safeTop = view.safeAreaInsets.top
        logoRing.frame = CGRect(x: w / 2 - 38, y: safeTop + 30, width: 76, height: 76)
        logoLabel.frame = CGRect(x: 0, y: 14, width: 76, height: 48)
        titleLabel.frame = CGRect(x: 24, y: logoRing.frame.maxY + 16, width: w - 48, height: 36)
        subtitleLabel.frame = CGRect(x: 24, y: titleLabel.frame.maxY + 2, width: w - 48, height: 20)
        let cardTop = subtitleLabel.frame.maxY + 26
        let cardW = min(w - 40, 460)
        card.frame = CGRect(x: (w - cardW) / 2, y: cardTop, width: cardW, height: 296)
        let cw = card.bounds.width
        accountLabel.frame = CGRect(x: 20, y: 20, width: cw - 40, height: 18)
        accountField.frame = CGRect(x: 20, y: 42, width: cw - 40, height: 48)
        passwordLabel.frame = CGRect(x: 20, y: 104, width: cw - 40, height: 18)
        passwordField.frame = CGRect(x: 20, y: 126, width: cw - 40, height: 48)
        loginButton.frame = CGRect(x: 20, y: 192, width: cw - 40, height: 52)
        hintLabel.frame = CGRect(x: 24, y: card.frame.maxY + 16, width: w - 48, height: 18)
    }

    @objc private func tapLogin() {
        view.endEditing(true)
        let acc = accountField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let pwd = passwordField.text ?? ""
        if acc.isEmpty || pwd.isEmpty {
            hintLabel.textColor = Theme.warn
            hintLabel.text = "账号和密码都要填"
            return
        }
        loginButton.isEnabled = false
        loginButton.setTitle("正在登录…", for: .normal)
        hintLabel.textColor = Theme.muted
        hintLabel.text = "正在连接猫夜服务器…"
        Api.login(acc: acc, pwd: pwd) { [weak self] ok, error in
            guard let self = self else { return }
            self.loginButton.isEnabled = true
            self.loginButton.setTitle("登录", for: .normal)
            if !ok {
                self.hintLabel.textColor = Theme.error
                self.hintLabel.text = error ?? "登录失败"
                return
            }
            self.enterHome()
        }
    }

    private func enterHome() {
        guard let nav = navigationController else { return }
        nav.setViewControllers([HomeViewController()], animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == accountField {
            passwordField.becomeFirstResponder()
        } else {
            tapLogin()
        }
        return true
    }
}
