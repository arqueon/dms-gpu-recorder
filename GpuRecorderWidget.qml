import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import QtQuick.Layouts
import QtCore

PluginComponent {
    id: root

    // -- Settings ----------------------------------------------------------------------
    property string captureSource: pluginData.captureSource || "portal"
    property string outputDir: pluginData.outputDir || ""
    property int replaySeconds: pluginData.replaySeconds ?? 0
    property string replayOutputDir: pluginData.replayOutputDir || ""
    property string fps: pluginData.fps ? pluginData.fps.toString() : "60"
    property string quality: pluginData.quality || "very_high"
    property string container: pluginData.container || "mp4"
    property bool recordCursor: pluginData.recordCursor !== undefined ? pluginData.recordCursor : true

    // -- Internal State ----------------------------------------------------------------------
    // idle, recording, paused, replay
    property string recordState: "idle" 
    property int recordTimerSeconds: 0

    // Control Center Widget Properties
    ccWidgetIcon: recordState === "idle" ? "videocam" : (recordState === "replay" ? "replay" : (recordState === "recording" ? "stop_circle" : "pause_circle"))
    ccWidgetPrimaryText: "GPU Recorder"
    ccWidgetSecondaryText: {
        if (recordState === "idle") return "Ready";
        if (recordState === "replay") return "Replay Buffer - " + _formatTime(recordTimerSeconds);
        if (recordState === "paused") return "Paused - " + _formatTime(recordTimerSeconds);
        return "Recording - " + _formatTime(recordTimerSeconds);
    }
    ccWidgetIsActive: recordState !== "idle"

    function _formatTime(totalSeconds) {
        var m = Math.floor(totalSeconds / 60);
        var s = totalSeconds % 60;
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    Timer {
        id: recordingTimer
        interval: 1000
        repeat: true
        running: root.recordState === "recording"
        onTriggered: {
            root.recordTimerSeconds += 1;
        }
    }

    onCcWidgetToggled: {
        if (root.recordState === "idle") {
            startRecording();
            if (PopoutService) PopoutService.closeControlCenter();
        } else {
            // If recording or paused, a primary click will stop and save
            stopRecording();
            if (PopoutService) PopoutService.closeControlCenter();
        }
    }

    function togglePause() {
        if (root.recordState === "idle") return;

        if (root.recordState === "recording") {
            // Pause
            let execCmd = ["sh", "-c", "pkill -SIGSTOP -f gpu-screen-recorder"];
            Quickshell.execDetached(execCmd);
            root.recordState = "paused";
            ToastService.showInfo("GPU Recorder", "Recording Paused");
        } else if (root.recordState === "paused") {
            // Resume
            let execCmd = ["sh", "-c", "pkill -SIGCONT -f gpu-screen-recorder"];
            Quickshell.execDetached(execCmd);
            root.recordState = "recording";
            ToastService.showInfo("GPU Recorder", "Recording Resumed");
        }
    }

    function startRecording() {
        if (typeof PluginService !== "undefined" && PluginService) {
            root.captureSource = PluginService.loadPluginData("dankGpuRecorder", "captureSource", "portal") || "portal";
            root.outputDir = PluginService.loadPluginData("dankGpuRecorder", "outputDir", "");
            root.replaySeconds = parseInt(PluginService.loadPluginData("dankGpuRecorder", "replaySeconds", "0")) || 0;
            root.replayOutputDir = PluginService.loadPluginData("dankGpuRecorder", "replayOutputDir", "");
            root.fps = PluginService.loadPluginData("dankGpuRecorder", "fps", "60") || "60";
            root.quality = PluginService.loadPluginData("dankGpuRecorder", "quality", "very_high") || "very_high";
            root.container = PluginService.loadPluginData("dankGpuRecorder", "container", "mp4") || "mp4";
            root.recordCursor = PluginService.loadPluginData("dankGpuRecorder", "recordCursor", true);
        }

        let baseDir = root.outputDir !== "" ? root.outputDir : "${XDG_VIDEOS_DIR:-$HOME/Videos}/Screencasting";
        let outDirCmd = "DIR=\"" + baseDir + "\"; mkdir -p \"$DIR\"; FILE=\"$DIR/$(date +'%Y-%m-%d_%H-%M-%S')." + root.container + "\"; ";
        
        let cursorFlag = root.recordCursor ? "yes" : "no";
        let recCmd = "nohup gpu-screen-recorder -w " + root.captureSource + " -f " + root.fps + " -k h264 -ac opus -a default_output -q " + root.quality + " -cursor " + cursorFlag + " -cr limited ";

        if (root.replaySeconds > 0) {
            let rpDir = root.replayOutputDir !== "" ? root.replayOutputDir : baseDir;
            recCmd += "-r " + root.replaySeconds + " -ro \"" + rpDir + "\" ";
        } else {
            recCmd += "-o \"$FILE\" ";
        }
        recCmd += "> /dev/null 2>&1 &";

        let execCmd = ["sh", "-c", outDirCmd + recCmd];
        Quickshell.execDetached(execCmd);

        root.recordTimerSeconds = 0;
        root.recordState = root.replaySeconds > 0 ? "replay" : "recording";
        recordingTimer.start();
        
        ToastService.showInfo("GPU Recorder", root.replaySeconds > 0 ? "Replay Buffer Started" : "Started capturing Screen");
    }

    function stopRecording() {
        if (root.recordState === "paused") {
            // Must resume before sending SIGINT, otherwise the mp4 closes incorrectly
            Quickshell.execDetached(["sh", "-c", "pkill -SIGCONT -f gpu-screen-recorder"]);
        }

        if (root.recordState === "replay") {
            // Save the shadowplay buffer
            let execCmd = ["sh", "-c", "pkill -SIGUSR1 -f gpu-screen-recorder && sleep 0.5 && pkill -SIGINT -f gpu-screen-recorder"];
            Quickshell.execDetached(execCmd);
            ToastService.showInfo("GPU Recorder", "Replay Saved Successfully");
        } else {
            // Standard stop
            let execCmd = ["sh", "-c", "sleep 0.2; pkill -SIGINT -f gpu-screen-recorder"];
            Quickshell.execDetached(execCmd);
            ToastService.showInfo("GPU Recorder", "Recording Saved");
        }

        root.recordState = "idle";
        recordingTimer.stop();
        root.recordTimerSeconds = 0;
    }

    horizontalBarPill: Component {
        Item {
            width: pillRow.width
            implicitHeight: pillRow.height || 24 // Fallback height

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                
                onClicked: function(mouse) {
                    if (mouse.button === Qt.LeftButton) {
                        if (root.recordState === "idle") {
                            startRecording();
                        } else {
                            stopRecording();
                        }
                    } else if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                        togglePause();
                    }
                }
            }

            Row {
                id: pillRow
                spacing: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter
                
                DankIcon {
                    name: root.recordState === "idle" ? "videocam" : (root.recordState === "recording" ? "stop_circle" : "pause_circle")
                    size: Theme.barIconSize(root.barThickness, -2)
                    color: root.recordState === "idle" ? Theme.widgetIconColor : (root.recordState === "recording" ? Theme.errorText : Theme.warningText)
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                StyledText {
                    visible: root.recordState !== "idle"
                    text: _formatTime(root.recordTimerSeconds)
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            width: parent.width || 24
            implicitHeight: pillCol.height

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                
                onClicked: function(mouse) {
                    if (mouse.button === Qt.LeftButton) {
                        if (root.recordState === "idle") {
                            startRecording();
                        } else {
                            stopRecording();
                        }
                    } else if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                        togglePause();
                    }
                }
            }

            Column {
                id: pillCol
                spacing: Theme.spacingXS
                anchors.horizontalCenter: parent.horizontalCenter
                
                DankIcon {
                    name: root.recordState === "idle" ? "videocam" : (root.recordState === "recording" ? "stop_circle" : "pause_circle")
                    size: Theme.barIconSize(root.barThickness, -2)
                    color: root.recordState === "idle" ? Theme.widgetIconColor : (root.recordState === "recording" ? Theme.errorText : Theme.warningText)
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                StyledText {
                    visible: root.recordState !== "idle"
                    text: _formatTime(root.recordTimerSeconds)
                    color: Theme.surfaceText
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "GPU Recorder"
            detailsText: root.recordState !== "idle" ? "Recording / Replay in progress" : "Powered by gpu-screen-recorder"
            showCloseButton: true
            Column {
                width: parent.width - Theme.spacingL * 2
                spacing: Theme.spacingM
                StyledRect {
                    width: parent.width - Theme.spacingL
                    height: 48
                    radius: Theme.cornerRadius
                    color: root.recordState !== "idle" ? Theme.errorContainer : Theme.primaryContainer
                    StyledText {
                        anchors.centerIn: parent
                        text: root.recordState !== "idle" ? "Stop and Save" : "Start Recording"
                        font.pixelSize: Theme.fontSizeMedium
                        color: root.recordState !== "idle" ? Theme.onErrorContainer : Theme.onPrimaryContainer
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.recordState === "idle") startRecording(); else stopRecording();
                            if (typeof popout.closePopout === "function") popout.closePopout();
                        }
                    }
                }
                StyledText {
                    width: parent.width
                    text: "Source: " + root.captureSource + " · " + root.fps + " fps · " + root.quality + (root.replaySeconds > 0 ? " · Replay: " + root.replaySeconds + "s" : "")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
    popoutWidth: 320
    popoutHeight: 220
}
