import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Widgets
import QtCore

PluginSettings {
    id: root
    pluginId: "dankGpuRecorder"

    StyledText {
        width: parent.width
        text: "GPU Screen Recorder Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Configure the capture quality and directory. The recording binds to 'Default Audio Output' by default."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    SelectionSetting {
        settingKey: "captureSource"
        label: "Capture Source"
        description: "portal = Window/Screen picker; screen = Entire first monitor"
        options: [
            { label: "Portal (Picker)", value: "portal" },
            { label: "Full Screen", value: "screen" }
        ]
        defaultValue: "portal"
    }

    StringSetting {
        settingKey: "outputDir"
        label: "Recording Directory"
        description: "Absolute path where videos are saved (ex: /home/user/Videos)"
        placeholder: "/home/user/Videos/Screencasting"
        defaultValue: ""
    }

    SliderSetting {
        settingKey: "replaySeconds"
        label: "Replay Buffer (seconds)"
        description: "0 = Normal recording; >0 = Save last N seconds when stopping"
        defaultValue: 0
        minimum: 0
        maximum: 180
        unit: "s"
    }

    StringSetting {
        settingKey: "replayOutputDir"
        label: "Replay Directory"
        description: "If empty, uses the standard Recording Directory"
        placeholder: "/home/user/Videos/Replays"
        defaultValue: ""
    }

    SliderSetting {
        settingKey: "fps"
        label: "FPS"
        description: "Frames per second"
        defaultValue: 60
        minimum: 30
        maximum: 144
        unit: ""
    }

    SelectionSetting {
        settingKey: "quality"
        label: "Video Quality"
        description: "GPU encoding preset for h264/av1"
        options: [
            { label: "Ultra", value: "ultra" },
            { label: "very_high", value: "very_high" },
            { label: "High", value: "high" },
            { label: "Medium", value: "medium" }
        ]
        defaultValue: "very_high"
    }

    SelectionSetting {
        settingKey: "container"
        label: "File Format"
        description: "Video container format"
        options: [
            { label: "MP4", value: "mp4" },
            { label: "MKV", value: "mkv" }
        ]
        defaultValue: "mp4"
    }

    ToggleSetting {
        settingKey: "recordCursor"
        label: "Record Cursor"
        description: "Include the mouse pointer in the recording"
        defaultValue: true
    }
}
