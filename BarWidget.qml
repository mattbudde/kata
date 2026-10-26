import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

Item {
    id: root
    property var bar
    property bool opened: false
    function open() { opened = true; run("status") }
    function close() { opened = false }
    property var settings
    property string moduleName: "local.katana-go"
    property var state: ({active: false, message: "Checking Katana GO…"})
    readonly property string helper: Qt.resolvedUrl("katana-go.py").toString().replace(/^file:\/\//, "")
    implicitWidth: bar && bar.vertical ? 28 : label.implicitWidth + 16
    implicitHeight: bar ? bar.barSize : 26

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
                try { root.state = JSON.parse(text) }
                catch (e) { root.state = {error: true, message: "Cannot read Katana GO status"} }
            }
        }
    }
    Timer { interval: 2000; repeat: true; running: true; onTriggered: root.run("status") }
    Component.onCompleted: run("status")

    Text {
        id: label
        anchors.centerIn: parent
        text: "型"
        color: root.bar ? root.bar.foreground : "white"
        opacity: root.state.active ? 1 : 0.55
        font.family: root.bar ? root.bar.fontFamily : "monospace"
        font.pixelSize: 17
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { if (root.opened) root.close(); else root.open() }
        onEntered: if (root.bar) root.bar.showTooltip(root, "Katana GO · " + root.state.message)
        onExited: if (root.bar) root.bar.hideTooltip(root)
    }
    Connections {
        target: process
        function onExited(exitCode, exitStatus) {
            if (exitCode !== 0 && root.currentAction !== "status")
                Quickshell.execDetached(["notify-send", "Katana GO", root.state.message])
            if (root.pendingAction !== "") {
                Qt.callLater(function() {
                    var action = root.pendingAction
                    root.pendingAction = ""
                    if (action !== "") root.run(action)
                })
            }
        }
    }

    PopupCard {
        id: popup
        anchorItem: root
        bar: root.bar
        owner: root
        open: root.opened
        contentWidth: fittedContentWidth(Style.space(340))
        contentHeight: fittedContentHeight(details.implicitHeight)

        Column {
            id: details
            width: parent.width
            spacing: Style.space(12)

            Text {
                text: "型  Katana GO"
                color: root.bar ? root.bar.foreground : "white"
                font.family: root.bar ? root.bar.fontFamily : "monospace"
                font.pixelSize: Style.font.subtitle
                font.bold: true
            }
            Text {
                width: parent.width
                text: root.state.error ? root.state.message :
                      (root.state.connected ? "USB connected · " + root.state.message : "USB disconnected")
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: root.bar ? root.bar.foreground : "white"
                font.pixelSize: Style.font.body
            }
            PanelSeparator { width: parent.width; foreground: root.bar ? root.bar.foreground : "white" }
            Repeater {
                model: [
                    {label: "Input", value: root.state.input || "Connect Katana GO via USB"},
                    {label: root.state.active ? "Playing through" : "Output", value: root.state.output || "No output available"},
                    {label: "Audio", value: "Stereo · 20 ms target latency"}
                ]
                delegate: Column {
                    required property var modelData
                    width: details.width
                    spacing: Style.space(3)
                    Text {
                        text: modelData.label
                        color: root.bar ? root.bar.foreground : "white"
                        opacity: 0.6
                        font.pixelSize: Style.font.caption
                    }
                    Text {
                        width: parent.width
                        text: modelData.value
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        color: root.bar ? root.bar.foreground : "white"
                        font.pixelSize: Style.font.body
                    }
                }
            }
            Button {
                text: root.changingMonitoring ? "Please wait…" : root.state.routeExists ? "Stop monitoring" : "Start monitoring"
                foreground: root.bar ? root.bar.foreground : "white"
                enabled: !root.changingMonitoring && (root.state.routeExists || (root.state.connected && !!root.state.output))
                onClicked: root.run("toggle")
            }
            Text {
                width: parent.width
                text: "Choose speakers or headphones in the audio menu. Restart monitoring to apply an output change."
                wrapMode: Text.Wrap
                color: root.bar ? root.bar.foreground : "white"
                opacity: 0.6
                font.pixelSize: Style.font.caption
            }
        }
    }
}

