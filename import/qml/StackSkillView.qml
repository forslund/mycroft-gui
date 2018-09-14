import QtQuick 2.4
import QtQuick.Controls 2.4
import org.kde.kirigami 2.4 as Kirigami
import Mycroft 1.0 as Mycroft

StackView {
    id: mainStack

    Component.onCompleted: {
        if (!mainStack.initialItem) {
            mainStack.initialItem = initialPlaceHolder;
        }
    }

    //this is to make the class work wether the user specifies an initialItem or not 
    Item {
        id: initialPlaceHolder
    }

    Mycroft.SkillLoader {
        id: skillLoader
    }

    Connections {
        id: mycroftConnection
        property string metadataType
        target: Mycroft.MycroftController

        function openSkillUi(type, data) {
            if (type == "") {
                return;
            }
            var _url = skillLoader.uiForMetadataType(type);
            if (!_url) {
                return;
            }

            if (mycroftConnection.metadataType == type) {
                var key;
                for (key in data) {
                    if (mainStack.currentItem.hasOwnProperty(key)) {
                        mainStack.currentItem[key] = data[key];
                    }
                }
            } else {
                mycroftConnection.metadataType = type;
                if (mainStack.depth > 1) {
                    mainStack.replace(_url, data);
                } else {
                    mainStack.push(_url, data);
                }
            }

            popTimer.running = false;
            countdownAnim.running = false;
        }

        //These few lines are a cludge to make existing skills work that don't have metadata (yet)
        onFallbackTextRecieved: {
            console.log("Fallback", skill);
            var regex = /(.*)Skill*/;
            var found = skill.match(regex);
            if (found.length > 1) {
//                 openSkillUi(found[1].toLowerCase(), data);
            }
        }

        onSkillDataRecieved: {
            console.log("Skill data", data["type"]);
            if (data["type"] === "stop") {
                //explictly unset
                if (mainStack.depth > 1) {
                    mainStack.pop();
                    mycroftConnection.metadataType = "";
                }
                return;
            }
            openSkillUi(data["type"], data);
        }

//         onSpeakingChanged: {
//             if (!Mycroft.MycroftController.speaking) {
//                 if (mainStack.depth > 1) {
//                     popTimer.restart();
//                     countdownAnim.restart();
//                 }
//             }
//         }
    }

    Timer {
        id: popTimer
        interval: mainStack.currentItem.hasOwnProperty("graceTime") ? mainStack.currentItem.graceTime : 0
        onTriggered: {
            if (mainStack.depth > 1) {
                mainStack.pop(get(0));
                mycroftConnection.metadataType = "";
            }
        }
    }

    Rectangle {
        id: countdownScrollBar
        z: 999
        anchors {
            left: parent.left
            bottom: parent.bottom
        }
        height: Kirigami.Units.smallSpacing
        Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
        color: Kirigami.Theme.textColor
        width: 0
        opacity: countdownAnim.running ? 0.6 : 0
        Behavior on opacity {
            OpacityAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutCubic
            }
        }

        PropertyAnimation {
            id: countdownAnim
            target: countdownScrollBar
            property: "width"
            from: parent.width
            to: 0
            duration: popTimer.interval
        }
    }
}
