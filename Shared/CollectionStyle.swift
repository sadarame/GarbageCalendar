import SwiftUI

enum CollectionStyle {
    static let accent = Color(red: 0.30, green: 0.39, blue: 0.22)
    static let forest = accent
    static let onboarding = Color(red: 213/255, green: 232/255, blue: 155/255)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let iconTypes = ["燃えるゴミ", "燃えないゴミ", "プラスチック", "ビン・カン", "ペットボトル", "古紙", "ダンボール", "資源ゴミ", "粗大ごみ", "危険・有害", "繊維", "資源（共通）"]

    static func displayType(_ type: String, iconType: String?) -> String {
        guard let iconType, iconTypes.contains(iconType) else { return type }
        return iconType
    }

    /// Choose an explicit icon only from rules occurring on the displayed day.
    static func iconType(for type: String, on date: Date, models: [GarbageRegistModel]) -> String? {
        models.first { $0.garbageType == type && ScheduleEngine.matches($0, on: date)
            && iconTypes.contains($0.iconType ?? "") }?.iconType
    }

    static func normalizedType(_ type: String) -> String {
        let name = type.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "ごみ", with: "ゴミ")
        switch name {
        case "もえるゴミ", "可燃ゴミ", "可燃", "燃やすゴミ", "燃やせるゴミ": return "燃えるゴミ"
        case "もえないゴミ", "不燃ゴミ", "不燃", "燃やさないゴミ", "燃やせないゴミ": return "燃えないゴミ"
        case "びん・かん", "缶・びん", "瓶・缶", "ビン", "カン": return "ビン・カン"
        case "段ボール": return "ダンボール"
        case "粗大ゴミ": return "粗大ごみ"
        default: return name
        }
    }
    static func asset(_ type: String) -> String {
        switch normalizedType(type) {
        case "燃えるゴミ": return "gomi_mark01_moeru"
        case "燃えないゴミ": return "gomi_mark02_moenai"
        case "プラスチック": return "gomi_mark06_plastic"
        case "ビン・カン": return "gomi_mark04_can"
        case "ペットボトル": return "gomi_mark05_petbottle"
        case "古紙": return "gomi_mark11_kami"
        case "ダンボール": return "gomi_mark07_shigen"
        case "資源ゴミ": return "gomi_mark10_kinzoku"
        case "粗大ごみ": return "gomi_mark08_sodai"
        case "危険・有害": return "gomi_mark14"
        case "繊維": return "繊維"
        default: return "gomi_mark13_blank"
        }
    }
    static func symbol(_ type: String) -> String {
        switch normalizedType(type) {
        case "燃えるゴミ": return "flame.fill"
        case "燃えないゴミ": return "trash.fill"
        case "プラスチック", "ペットボトル": return "waterbottle.fill"
        case "ビン・カン": return "mug.fill"
        case "古紙": return "newspaper.fill"
        case "ダンボール": return "shippingbox.fill"
        case "粗大ごみ": return "sofa.fill"
        case "危険・有害": return "exclamationmark.triangle.fill"
        case "繊維": return "tshirt.fill"
        default:
            // Local numbered categories do not imply a particular recyclable material.
            return normalizedType(type).hasPrefix("資源") ? "arrow.3.trianglepath" : "trash.fill"
        }
    }
    static func color(_ type: String) -> Color {
        switch normalizedType(type) {
        case "燃えるゴミ": return .orange
        case "燃えないゴミ": return .indigo
        case "プラスチック", "ペットボトル": return .blue
        case "危険・有害": return .red
        default: return accent
        }
    }
    static func date(_ date: Date, format: String = "M月d日（E）") -> String {
        let formatter = DateFormatter()
        formatter.calendar = ScheduleEngine.calendar
        formatter.timeZone = ScheduleEngine.calendar.timeZone
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

struct CollectionIcon: View {
    let type: String
    var size: CGFloat = 44
    var iconType: String? = nil
    private var displayType: String { CollectionStyle.displayType(type, iconType: iconType) }
    var body: some View {
        Group {
            if CollectionStyle.asset(displayType) != "gomi_mark13_blank",
               let image = UIImage(named: CollectionStyle.asset(displayType)) {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                Image(systemName: CollectionStyle.symbol(displayType))
                    .resizable().scaledToFit().padding(size * 0.18)
                    .foregroundStyle(CollectionStyle.color(displayType))
            }
        }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
