import AppKit

enum AboutPanel {
    private static let repositoryURL = URL(string: "https://github.com/YPJCoding/app-installer")!

    @MainActor
    static func show() {
        let credits = NSMutableAttributedString(string: "Author: YPJCoding\nGithub: ")
        credits.append(NSAttributedString(
            string: "app-installer",
            attributes: [
                .link: repositoryURL,
                .foregroundColor: NSColor.linkColor,
            ]
        ))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 4
        credits.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: credits.length)
        )

        NSApp.orderFrontStandardAboutPanel(options: [
            .credits: credits,
        ])
        NSApp.activate(ignoringOtherApps: true)
    }
}
