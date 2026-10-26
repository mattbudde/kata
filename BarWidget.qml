pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui as Ui
import qs.Commons
import qs.Commons as Commons

Ui.BarWidget {
    id: root
    // The shell injects a dynamic host; its properties are not in QObject metadata.
    readonly property var hostBar: bar
    readonly property var fonts: Style.font
    property bool opened: false
    function open() { opened = true; run("status") }
    function close() { opened = false }
    function toggle() { opened ? close() : open() }
    property bool popoutSwitchClosing: false
    function closeForPopoutSwitch() {
        popoutSwitchClosing = true
        close()
        Qt.callLater(function() { root.popoutSwitchClosing = false })
    }
    moduleName: "io.github.mattbudde.kata"
    property var audioStatus: ({active: false, connected: false, routeExists: false, output: "", message: "Checking Katana GO…"})
    readonly property string helper: Qt.resolvedUrl("katana-go.py").toString().replace(/^file:\/\//, "")
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    property string currentAction: "status"
    property string pendingAction: ""
    readonly property bool changingMonitoring: pendingAction !== "" || (process.running && currentAction !== "status")

    function run(action) {
        if (process.running) {
            if (action !== "status") pendingAction = action
            return
        }
        currentAction = action
        process.command = ["python3", decodeURIComponent(helper), action]
        process.running = true
    }

    Process {
        id: process
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.audioStatus = JSON.parse(text) }
                catch (e) { root.audioStatus = {error: true, message: "Cannot read Katana GO status"} }
            }
        }
    }
    Timer { interval: 2000; repeat: true; running: true; onTriggered: root.run("status") }
    Component.onCompleted: run("status")

    Ui.WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.hostBar
        text: "型"
        fontSize: root.fonts.iconLarge
        dimmed: !root.audioStatus.active
        tooltipText: "Katana GO · " + root.audioStatus.message
        onPressed: function(buttonCode) {
            if (buttonCode === Qt.LeftButton) root.toggle()
        }
    }
    Connections {
        target: process
        function onExited(exitCode, exitStatus) {
            if (exitCode !== 0 && root.currentAction !== "status")
                Quickshell.execDetached(["notify-send", "Katana GO", root.audioStatus.message])
            if (root.pendingAction !== "") {
                Qt.callLater(function() {
                    var action = root.pendingAction
                    root.pendingAction = ""
                    if (action !== "") root.run(action)
                })
            }
        }
    }

    Ui.KeyboardPanel {
        id: popup
        anchorItem: button
        bar: root.hostBar
        owner: root
        open: root.opened
        contentWidth: popup.fittedContentWidth(Style.space(340))
        contentHeight: popup.fittedContentHeight(details.implicitHeight)

        focusTarget: keyCatcher

        Ui.PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            onCloseRequested: root.close()
            onTabRequested: function(direction) {
                if (root.hostBar && typeof root.hostBar.switchPanelFrom === "function")
                    root.hostBar.switchPanelFrom(root, direction)
            }
            onActivateRequested: if (monitorButton.enabled) root.run("toggle")

            Column {
                id: details
                width: parent.width
                spacing: Style.space(12)

                Text {
                    text: "型  Katana GO"
                    color: root.hostBar ? root.hostBar.foreground : Commons.Color.foreground
                    font.family: root.hostBar ? root.hostBar.fontFamily : "monospace"
                    font.pixelSize: root.fonts.subtitle
                    font.bold: true
                }
                Text {
                    width: parent.width
                    text: root.audioStatus.error ? root.audioStatus.message :
                          (root.audioStatus.connected ? "USB connected · " + root.audioStatus.message : "USB disconnected")
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: root.hostBar ? root.hostBar.foreground : Commons.Color.foreground
                    font.family: root.hostBar ? root.hostBar.fontFamily : root.fonts.family
                    font.pixelSize: root.fonts.body
                }
                Ui.PanelSeparator { width: parent.width; foreground: root.hostBar ? root.hostBar.foreground : Commons.Color.foreground }
                Repeater {
                    model: [
                        {label: "Input", value: root.audioStatus.input || "Connect Katana GO via USB"},
                        {label: root.audioStatus.active ? "Playing through" : "Output", value: root.audioStatus.output || "No output available"},
                        {label: "Audio", value: "Stereo · 20 ms target latency"}
                    ]
                    delegate: Column {
                        id: infoRow
                        required property var modelData
                        width: details.width
                        spacing: Style.space(3)
                        Text {
                            text: infoRow.modelData.label
                            color: root.hostBar ? root.hostBar.foreground : Commons.Color.foreground
                            opacity: 0.6
                            font.family: root.hostBar ? root.hostBar.fontFamily : root.fonts.family
                            font.pixelSize: root.fonts.caption
                        }
                        Text {
                            width: parent.width
                            text: infoRow.modelData.value
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            color: root.hostBar ? root.hostBar.foreground : Commons.Color.foreground
                            font.family: root.hostBar ? root.hostBar.fontFamily : root.fonts.family
                            font.pixelSize: root.fonts.body
                        }
                    }
                }
                Ui.Button {
                    id: monitorButton
                    text: root.changingMonitoring ? "Please wait…" : root.audioStatus.routeExists ? "Stop monitoring" : "Start monitoring"
                    foreground: root.hostBar ? root.hostBar.foreground : Commons.Color.foreground
                    enabled: !root.changingMonitoring && (!!root.audioStatus.routeExists || (!!root.audioStatus.connected && !!root.audioStatus.output))
                    onClicked: root.run("toggle")
                }
                Text {
                    width: parent.width
                    text: "Choose speakers or headphones in the audio menu. Restart monitoring to apply an output change."
                    wrapMode: Text.Wrap
                    color: root.hostBar ? root.hostBar.foreground : Commons.Color.foreground
                    opacity: 0.6
                    font.family: root.hostBar ? root.hostBar.fontFamily : root.fonts.family
                    font.pixelSize: root.fonts.caption
                }
            }
        }
    }
}
