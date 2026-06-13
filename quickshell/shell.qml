import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    // --- Theme Palette ---
    property color colBg: "#CC111217"         
    property color colFg: "#f8fafc"      
    property color colMuted: "#475569"  
    property color colAccent: "#60a5fa"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 11           

    // --- Component Accent Colors     
    property color colNet: "#b19cd9"    
    property color colCpu: "#93c5fd"   
    property color colMem: "#f472b6"   
    property color colClock: "#fff9c4"  
    property color colBat: "#a7f3d0"   
    property color colVol: "#fca5a5"   

    // --- Dynamic System Data ---
    property int cpuUsage: 0
    property int memUsage: 0
    property string batUsage: "0%"
    property string netStatus: "Offline"
    property string volStatus: "100%"  

    // Master system ticker
    Timer {
        interval: 500 
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuScript.running = true;
            memScript.running = true;
            batScript.running = true;
            netScript.running = true;
            volScript.running = true; 
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

    // Process fetching Battery percentage and charging status
    Process {
        id: batScript
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity && cat /sys/class/power_supply/BAT0/status"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    var lines = this.text.trim().split("\n");
                    var pct = lines[0] ? lines[0] : "0";
                    var status = lines[1] ? lines[1] : "Discharging";
                    var suffix = (status === "Charging" || status === "Full") ? " ϟ" : "%";
                    root.batUsage = pct + suffix;
                }
            }
        }
    }

    // Process fetching Network status via NetworkManager CLI
    Process {
        id: netScript
        command: ["sh", "-c", "nmcli -t -f TYPE,NAME connection show --active | head -n 1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var output = this.text.trim();
                if (output === "") {
                    root.netStatus = "Offline";
                } else {
                    var parts = output.split(":");
                    var type = parts[0];
                    var name = parts[1];

                    if (type.indexOf("wireless") !== -1) {
                        root.netStatus = "WIFI: " + name;
                    } else if (type.indexOf("ethernet") !== -1) {
                        root.netStatus = "ETH: Connected";
                    } else {
                        root.netStatus = "Connected";
                    }
                }
            }
        }
    }

    // Process fetching native PipeWire volume via wireplumber (wpctl)
    Process {
        id: volScript
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{ if ($3 == \"[MUTED]\") print \"Muted\"; else printf \"%.0f%%\\n\", $2*100 }'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    root.volStatus = this.text.trim();
                }
            }
        }
    }

    // Reusable process runner for mutations
    Process { id: volControl }

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
                        color: parent.isActive ? "#20e8bcf0" : "transparent"
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

        // Network
        Text {
            text: root.netStatus
            color: root.netStatus === "Offline" ? root.colMuted : root.colNet
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }

        Rectangle { width: 1; height: 10; color: root.colMuted } 

        // CPU
        Text {
            text: "CPU " + root.cpuUsage + "%"
            color: root.colCpu
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }

        Rectangle { width: 1; height: 10; color: root.colMuted } 

        // Memory
        Text {
            text: "MEM " + root.memUsage + "%"
            color: root.colMem
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }

        Rectangle { width: 1; height: 10; color: root.colMuted } 

        // Volume (PipeWire Native)
        Text {
            text: "VOL " + root.volStatus
            color: root.volStatus === "Muted" ? root.colMuted : root.colVol
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }

            MouseArea {
                anchors.fill: parent
                scrollGestureEnabled: true
                
                // Click to Toggle Mute
                onClicked: {
                    volControl.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
                    volControl.running = true;
                    volScript.running = true; // Trigger instant panel update
                }
                
                // Scroll up/down to shift volume in 5% steps
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y > 0) {
                        volControl.command = ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", "5%+"];
                    } else {
                        volControl.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"];
                    }
                    volControl.running = true;
                    volScript.running = true; // Trigger instant panel update
                }
            }
        }

        Rectangle { width: 1; height: 10; color: root.colMuted } 

        // Clock
        Text {
            id: clock
            color: root.colClock
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
            text: Qt.formatDateTime(new Date(), "ddd, MMM dd  ·  HH:mm")
            
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd, MMM dd  ·  HH:mm")
            }
        }

        Rectangle { width: 1; height: 10; color: root.colMuted } 

        // Battery
        Text {
            text: "BAT " + root.batUsage
            color: root.colBat
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }
    }
}
