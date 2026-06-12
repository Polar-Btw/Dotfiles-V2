import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    // --- Dark Frosted Theme Palette ---
    property color colBg: "#CC111217"         
    property color colFg: "#e2e8f0"      
    property color colMuted: "#4a5568"  
    property color colAccent: "#60a5fa"      
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 11           

    // --- Dynamic System Data ---
    property int cpuUsage: 0
    property int memUsage: 0

    // Master system ticker
    Timer {
        interval: 2000 // Update statistics every 2 seconds
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuScript.running = true;
            memScript.running = true;
        }
    }

    // Process fetching CPU usage via top
    Process {
        id: cpuScript
        command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | sed \"s/.*, *\\([0-9.]*\\)%* id.*/\\1/\" | awk '{print 100 - $1}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    root.cpuUsage = Math.round(parseFloat(this.text.trim()));
                }
            }
        }
    }

    // Process fetching Memory usage via free
    Process {
        id: memScript
        command: ["sh", "-c", "free | grep Mem | awk '{print $3/$2 * 100.0}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    root.memUsage = Math.round(parseFloat(this.text.trim()));
                }
            }
        }
    }

    // --- Window Settings ---
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 24                    
    color: root.colBg

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12            
        anchors.rightMargin: 12
        spacing: 10                       

        // Workspaces
        RowLayout {
            spacing: 4                    
            Repeater {
                model: 9
                
                Item {
                    property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                    property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                    
                    implicitWidth: wsText.implicitWidth + 8
                    implicitHeight: wsText.implicitHeight + 2

                    Rectangle {
                        anchors.fill: parent
                        color: parent.isActive ? "#2560a5fa" : "transparent"
                        radius: 3
                    }

                    Text {
                        id: wsText
                        anchors.centerIn: parent
                        text: index + 1
                        color: parent.isActive ? root.colAccent : (parent.ws ? root.colFg : root.colMuted)
                        font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch("workspace " + (index + 1))
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // CPU
        Text {
            text: "CPU " + root.cpuUsage + "%"
            color: root.colFg
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }

        Rectangle { width: 1; height: 10; color: root.colMuted } 

        // Memory
        Text {
            text: "MEM " + root.memUsage + "%"
            color: root.colFg
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }

        Rectangle { width: 1; height: 10; color: root.colMuted } 

        // Clock
        Text {
            id: clock
            color: root.colFg
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
            text: Qt.formatDateTime(new Date(), "ddd, MMM dd  ·  HH:mm")
            
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd, MMM dd  ·  HH:mm")
            }
        }
    }
}
