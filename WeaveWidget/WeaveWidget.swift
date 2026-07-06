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
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Reach out")
        .description("The people who'd love to hear from you.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PersonLine: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let color: Color
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
                PersonLine(name: "Kenji Watanabe", detail: "quiet 3mo", color: .red),
                PersonLine(name: "Sarah Kim", detail: "check in soon", color: .orange),
            ],
            quietCount: 2
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
            PersonLine(
                name: person.name,
                detail: person.overdueLabel ?? "",
                color: person.healthState.color
            )
        }
        return WeaveEntry(date: .now, lines: lines, quietCount: due.count)
    }
}

struct WeaveWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WeaveEntry

    var body: some View {
        if entry.lines.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "heart.circle.fill")
                    .font(.title)
                    .foregroundStyle(.tint)
                Text("Everyone's in touch")
                    .font(.caption.weight(.medium))
                    .multilineTextAlignment(.center)
            }
            .fontDesign(.rounded)
        } else {
            VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 8) {
                Text(headline)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(entry.lines.prefix(family == .systemSmall ? 2 : 3)) { line in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(line.color)
                            .frame(width: 7, height: 7)
                        Text(firstName(line.name))
                            .font(family == .systemSmall ? .caption : .subheadline)
                            .lineLimit(1)
                        if family != .systemSmall {
                            Spacer()
                            Text(line.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .fontDesign(.rounded)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var headline: String {
        entry.quietCount == 1
            ? "1 person misses you"
            : "\(entry.quietCount) people miss you"
    }

    private func firstName(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
}
