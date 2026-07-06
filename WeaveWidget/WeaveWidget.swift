import SwiftData
import SwiftUI
import WidgetKit

@main
struct WeaveWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeaveWidget()
    }
}

struct WeaveWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeaveWidget", provider: Provider()) { entry in
            WeaveWidgetView(entry: entry)
                .containerBackground(Theme.canvas, for: .widget)
        }
        .configurationDisplayName("Reach out")
        .description("The people who'd love to hear from you.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PersonLine: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
    let detail: String
    let stateColor: Color
    let ringFraction: Double
    let avatarFill: Color
    let avatarText: Color

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
}

struct WeaveEntry: TimelineEntry {
    let date: Date
    let lines: [PersonLine]
    let quietCount: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WeaveEntry {
        WeaveEntry(
            date: .now,
            lines: [
                placeholderLine(name: "Kenji Watanabe", detail: "quiet 3mo", fraction: 0.08),
                placeholderLine(name: "Sarah Kim", detail: "check in soon", fraction: 0.35),
            ],
            quietCount: 2
        )
    }

    private func placeholderLine(name: String, detail: String, fraction: Double) -> PersonLine {
        let colors = Theme.avatarColors(for: name)
        return PersonLine(
            name: name,
            initials: name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased(),
            detail: detail,
            stateColor: fraction < 0.2 ? HealthState.overdue.color : HealthState.drifting.color,
            ringFraction: fraction,
            avatarFill: colors.fill,
            avatarText: colors.text
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WeaveEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeaveEntry>) -> Void) {
        let refresh = Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now
        completion(Timeline(entries: [makeEntry()], policy: .after(refresh)))
    }

    private func makeEntry() -> WeaveEntry {
        guard let container = try? SharedStore.modelContainer() else {
            return WeaveEntry(date: .now, lines: [], quietCount: 0)
        }
        let context = ModelContext(container)
        let people = (try? context.fetch(FetchDescriptor<Person>())) ?? []
        let due = people
            .filter { $0.healthState == .overdue || $0.healthState == .drifting }
            .sorted { ($0.overdueRatio ?? 0) > ($1.overdueRatio ?? 0) }
        let lines = due.prefix(3).map { person in
            let colors = Theme.avatarColors(for: person.name)
            return PersonLine(
                name: person.name,
                initials: person.initials,
                detail: person.overdueLabel ?? "",
                stateColor: person.healthState.color,
                ringFraction: person.ringFraction,
                avatarFill: colors.fill,
                avatarText: colors.text
            )
        }
        return WeaveEntry(date: .now, lines: lines, quietCount: due.count)
    }
}

struct WeaveWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WeaveEntry

    var body: some View {
        Group {
            if entry.lines.isEmpty {
                emptyState
            } else {
                peopleList
            }
        }
        .fontDesign(.rounded)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "heart.circle.fill")
                .font(.title)
                .foregroundStyle(.tint)
            Text("Everyone's in touch")
                .font(.subheadline)
                .fontDesign(.serif)
                .multilineTextAlignment(.center)
        }
    }

    private var peopleList: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 9) {
            Text(headline)
                .font(family == .systemSmall ? .footnote : .subheadline)
                .fontDesign(.serif)
                .foregroundStyle(.primary)
            ForEach(entry.lines.prefix(family == .systemSmall ? 2 : 3)) { line in
                HStack(spacing: 8) {
                    MiniRing(line: line)
                    Text(line.firstName)
                        .font(family == .systemSmall ? .caption : .subheadline)
                        .lineLimit(1)
                    if family != .systemSmall {
                        Spacer()
                        Text(line.detail)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(line.stateColor)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var headline: String {
        entry.quietCount == 1
            ? "1 person misses you"
            : "\(entry.quietCount) people miss you"
    }
}

private struct MiniRing: View {
    let line: PersonLine
    var size: CGFloat = 26

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.ringTrack, lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: line.ringFraction)
                .stroke(line.stateColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(line.avatarFill)
                .frame(width: size - 8, height: size - 8)
            Text(line.initials)
                .font(.system(size: size * 0.28, weight: .semibold, design: .rounded))
                .foregroundStyle(line.avatarText)
        }
        .frame(width: size, height: size)
    }
}
