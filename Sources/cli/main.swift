// MARK: - CLI

import Foundation

func showWelcome() {
    print("---Welcome--- \n")
    print("Please input a FAMIX string \n")
    print("Note: Spaces are important! \n")
    print("Type `help` for more information. \n")
}

func showHelp() {
    print("---Help--- \n")
    print("Type `reset` to reset the input, type :q to quit, \n")
    print("Type `example` to see an example. \n")
}

showWelcome()

var stdIn = ""
var parsedResult: [FamixEntity] = []

while let line = readLine() {
    stdIn.append(line)
    stdIn.append("\n")

    switch line.uppercased() {
    case ":q".uppercased():
        exit(1)
    case "example".uppercased():
        print("---Example---")
        print(famixStrExample)
        print("-------------")
        stdIn = famixStrExample
    case "reset".uppercased():
        stdIn = ""
        parsedResult = []
        print("---Reset---")
    case "help".uppercased():
        showHelp()
    default:
        break
    }

    let result = famixParser.run(stdIn)

    if let unwrappedResult = result.match?.1 {
        parsedResult.append(contentsOf: unwrappedResult)
    }

    if !parsedResult.isEmpty {
        let description = parsedResult
            .map { $0.debugDescription }
            .joined(separator: "\n")
        print("Parsed: \n \(description)")
        print("Rest: \n \(result.rest) \n")

        print("Would you like to see a graph of the result? \n")
        print("y/n")

        let line = readLine()
        switch line?.uppercased() {
        case "y".uppercased():
            showResultUI()
        default:
            showWelcome()
            break
        }
        stdIn = ""
        parsedResult = []

    }
}

// MARK: - Chart mini lib, boilerplate for the UI.

/*
 https://towardsdatascience.com/data-visualization-with-swiftui-bar-charts-599de6c0d79c
 */

import SwiftUI
import AppKit

public func showResultUI() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}

func countOccurrences(_ data: [FamixEntity]) -> ([Double], [String]) {

    let counts = data.reduce(into: [:]) { result, entity in
        result[entity.name, default: 0.0] += 1.0
    }

    return counts.reduce(into: ([], [])) { tuple, dict in
        tuple.0.append(dict.value)
        tuple.1.append(dict.key.appending(" (\(Int(dict.value)))"))
    }
}

struct GraphView: View {
    @State var data: [Double]
    @State var labels: [String]
    var body: some View {
        BarChart(data: $data,
                 labels: $labels,
                 accentColor: .blue,
                 axisColor: .red,
                 showGrid: true,
                 gridColor: .gray,
                 spacing: 1)
    }
}

class WindowDelegate: NSObject, NSWindowDelegate {

    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(0)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let window = NSWindow()
    let windowDelegate = WindowDelegate()

    func applicationDidFinishLaunching(_ notification: Notification) {

        let title = "Famix Chart"

        let appMenu = NSMenuItem()
        appMenu.submenu = NSMenu()
        appMenu.submenu?.addItem(
            NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        )
        let mainMenu = NSMenu(title: title)
        mainMenu.addItem(appMenu)
        NSApplication.shared.mainMenu = mainMenu

        let size = CGSize(width: 480, height: 270)
        window.setContentSize(size)
        window.styleMask = [.closable, .miniaturizable, .resizable, .titled]
        window.delegate = windowDelegate
        window.title = title

        let data = countOccurrences(parsedResult)
        let graphView = GraphView(data: data.0, labels: data.1)
        let view = NSHostingView(rootView: graphView)
        view.frame = CGRect(origin: .zero, size: size)
        view.autoresizingMask = [.height, .width]
        window.contentView?.addSubview(view)
        window.center()
        window.makeKeyAndOrderFront(window)

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct BarChart: View {
    @Binding var data: [Double]
    @Binding var labels: [String]
    let accentColor: Color
    let axisColor: Color
    let showGrid: Bool
    let gridColor: Color
    let spacing: CGFloat

    private var minimum: Double { (data.min() ?? 0) * 0.95 }
    private var maximum: Double { (data.max() ?? 1) * 1.05 }

    var body: some View {
        VStack {
            ZStack {
                if showGrid {
                    BarChartGrid(divisions: 10)
                        .stroke(gridColor.opacity(0.2), lineWidth: 0.5)
                }
                BarStack(data: $data,
                         labels: $labels,
                         accentColor: accentColor,
                         gridColor: gridColor,
                         showGrid: showGrid,
                         min: minimum,
                         max: maximum,
                         spacing: spacing)

                BarChartAxes()
                    .stroke(Color.black, lineWidth: 2)
            }

            LabelStack(labels: $labels, spacing: spacing)
        }
        .padding([.horizontal, .top], 20)
    }
}

struct BarChartGrid: Shape {
    let divisions: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let stepSize = rect.height / CGFloat(divisions)

        (1 ... divisions).forEach { step in
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY - stepSize * CGFloat(step)))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - stepSize * CGFloat(step)))
        }

        return path
    }
}

struct BarChartAxes: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        return path
    }
}

struct BarStack: View {
    @Binding var data: [Double]
    @Binding var labels: [String]
    let accentColor: Color
    let gridColor: Color
    let showGrid: Bool
    let min: Double
    let max: Double
    let spacing: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            ForEach(0 ..< data.count) { index in
                LinearGradient(
                    gradient: .init(
                        stops: [
                            .init(color: Color.secondary.opacity(0.6), location: 0),
                            .init(color: accentColor.opacity(0.6), location: 0.4),
                            .init(color: accentColor, location: 1)
                        ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .clipShape(BarPath(data: data[index], max: max, min: min))
            }
        }
        .shadow(color: .black, radius: 5, x: 1, y: 1)
        .padding(.horizontal, spacing)
    }
}

struct BarPath: Shape {
    let data: Double
    let max: Double
    let min: Double

    func path(in rect: CGRect) -> Path {
        guard min != max else {
            return Path()
        }

        let height = CGFloat((data - min) / (max - min)) * rect.height
        let bar = CGRect(x: rect.minX, y: rect.maxY - (rect.minY + height), width: rect.width, height: height)

        return RoundedRectangle(cornerRadius: 5).path(in: bar)
    }
}

struct LabelStack: View {
    @Binding var labels: [String]
    let spacing: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(labels, id: \.self) { label in
                Text(label)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, spacing)
    }
}
