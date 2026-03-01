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
        settingKey: "fps"
        label: "Frames per Second (FPS)"
        description: "Choose recording framerate"
        options: [
            {label: "30 FPS", value: "30"},
            {label: "60 FPS", value: "60"}
        ]
        defaultValue: "60"
    }

    SelectionSetting {
        settingKey: "quality"
        label: "Video Quality"
        description: "Choose recording quality setting for h264/av1"
        options: [
            {label: "Medium", value: "medium"},
            {label: "High", value: "high"},
            {label: "Very High", value: "very_high"}
        ]
        defaultValue: "very_high"
    }

    ToggleSetting {
        settingKey: "recordCursor"
        label: "Record Cursor"
        description: "Include the mouse pointer in the recording"
        defaultValue: true
    }
}
