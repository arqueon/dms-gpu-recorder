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
    property string fps: pluginData.fps || "60"
    property string quality: pluginData.quality || "very_high"
    property bool recordCursor: pluginData.recordCursor !== undefined ? pluginData.recordCursor : true

    // -- Internal State ----------------------------------------------------------------------
    // idle, recording, paused
    property string recordState: "idle" 
    property int recordTimerSeconds: 0

    // Control Center Widget Properties
    // Based on the state, we swap the material icon
    ccWidgetIcon: recordState === "idle" ? "videocam" : (recordState === "recording" ? "stop_circle" : "pause_circle")
    ccWidgetPrimaryText: "GPU Recorder"
    ccWidgetSecondaryText: {
        if (recordState === "idle") return "Ready";
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
            let execCmd = ["sh", "-c", "killall -SIGSTOP gpu-screen-recorder"];
            Quickshell.execDetached(execCmd);
            root.recordState = "paused";
            ToastService.showInfo("GPU Recorder", "Recording Paused");
        } else if (root.recordState === "paused") {
            // Resume
            let execCmd = ["sh", "-c", "killall -SIGCONT gpu-screen-recorder"];
            Quickshell.execDetached(execCmd);
            root.recordState = "recording";
            ToastService.showInfo("GPU Recorder", "Recording Resumed");
        }
    }

    function startRecording() {
        // Load plugins data just in case
        if (typeof PluginService !== "undefined" && PluginService) {
            root.fps = PluginService.loadPluginData("dankGpuRecorder", "fps", "60") || "60";
            root.quality = PluginService.loadPluginData("dankGpuRecorder", "quality", "very_high") || "very_high";
            root.recordCursor = PluginService.loadPluginData("dankGpuRecorder", "recordCursor", true);
        }

        let dirCmd = "DIR=\"${XDG_VIDEOS_DIR:-$HOME/Videos}/Screencasting\"; mkdir -p \"$DIR\"; FILE=\"$DIR/$(date +'%Y-%m-%d_%H-%M-%S').mp4\"; ";
        
        let cursorFlag = root.recordCursor ? "yes" : "no";
        let recCmd = "nohup gpu-screen-recorder -w screen -f " + root.fps + " -a default_output -q " + root.quality + " -cursor " + cursorFlag + " -o \"$FILE\" > /dev/null 2>&1 &";

        let execCmd = ["sh", "-c", dirCmd + recCmd];
        Quickshell.execDetached(execCmd);

        root.recordTimerSeconds = 0;
        root.recordState = "recording";
        recordingTimer.start();
        
        ToastService.showInfo("GPU Recorder", "Started capturing Screen");
    }

    function stopRecording() {
        if (root.recordState === "paused") {
            // Must resume before sending SIGINT, otherwise the mp4 closes incorrectly
            Quickshell.execDetached(["sh", "-c", "killall -SIGCONT gpu-screen-recorder"]);
        }

        let execCmd = ["sh", "-c", "sleep 0.2; killall -SIGINT gpu-screen-recorder"];
        Quickshell.execDetached(execCmd);

        root.recordState = "idle";
        recordingTimer.stop();
        root.recordTimerSeconds = 0;

        ToastService.showInfo("GPU Recorder", "Saved to Videos/Screencasting");
    }

    // Required by PluginComponent for the bar itself
    horizontalBarPill: Component {
        MouseArea {
            width: pillRow.width
            height: parent.height
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
        MouseArea {
            width: parent.width
            height: pillCol.height
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
}
