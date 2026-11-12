/*
    SPDX-FileCopyrightText: 2013 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2022 Nate Graham <nate@kde.org>
    SPDX-FileCopyrightText: 2022 ivan tkachenko <me@ratijas.tk>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg
import org.kde.iconthemes as KIconThemes
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.config as KConfig
import org.kde.plasma.plasmoid

import "code/tools.js" as Tools

KCM.SimpleKCM {
    id: root

    property string cfg_menuLabel: menuLabel.text
    property string cfg_icon: Plasmoid.configuration.icon
    property alias cfg_appNameFormat: appNameFormat.currentIndex
    property int cfg_favoritesDisplay: Plasmoid.configuration.favoritesDisplay
    property int cfg_applicationsDisplay: Plasmoid.configuration.applicationsDisplay
    property alias cfg_alphaSort: alphaSort.checked
    property alias cfg_compactMode: compactModeCheckbox.checked
    property alias cfg_highlightNewlyInstalledApps: highlightNewlyInstalledAppsCheckbox.checked
    property alias cfg_showRecentTab: showRecentTabCheckbox.checked
    property alias cfg_showRecentFilesTab: showRecentFilesTabCheckbox.checked
    property alias cfg_tabLabelStyle: tabLabelStyleCombo.currentIndex
    property alias cfg_popupGap: popupGapSpin.value
    property string cfg_categoryTab: Plasmoid.configuration.categoryTab
    property var cfg_leaveActions: Plasmoid.configuration.leaveActions

    // Same order as the power menu (kicker SystemModel); unavailable ones are hidden there
    readonly property var leaveActionChoices: [
        { id: "lock-screen", text: i18nc("@option:check", "Lock Screen") },
        { id: "logout",      text: i18nc("@option:check", "Log Out") },
        { id: "switch-user", text: i18nc("@option:check", "Switch User") },
        { id: "suspend",     text: i18nc("@option:check", "Sleep") },
        { id: "hibernate",   text: i18nc("@option:check", "Hibernate") },
        { id: "reboot",      text: i18nc("@option:check", "Restart") },
        { id: "shutdown",    text: i18nc("@option:check", "Shut Down") },
    ]


    Kirigami.FormLayout {
        QQC2.Button {
            id: iconButton

            Kirigami.FormData.label: i18nc("@label prefix for icon-only button", "Icon:")

            implicitWidth: previewFrame.width + Kirigami.Units.smallSpacing * 2
            implicitHeight: previewFrame.height + Kirigami.Units.smallSpacing * 2
            hoverEnabled: true

            Accessible.name: i18nc("@action:button", "Change Application Launcher's icon")
            Accessible.description: i18nc("@info:whatsthis", "Current icon is %1. Click to open menu to change the current icon or reset to the default icon.", root.cfg_icon)
            Accessible.role: Accessible.ButtonMenu

            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            QQC2.ToolTip.text: i18nc("@info:tooltip", "Icon name is \"%1\"", root.cfg_icon)
            QQC2.ToolTip.visible: iconButton.hovered && root.cfg_icon.length > 0

            KIconThemes.IconDialog {
                id: iconDialog
                onAccepted: {
                    root.cfg_icon = iconName || Tools.defaultIconName;
                }
            }

            onPressed: iconMenu.opened ? iconMenu.close() : iconMenu.open()

            KSvg.FrameSvgItem {
                id: previewFrame
                anchors.centerIn: parent
                imagePath: Plasmoid.formFactor === PlasmaCore.Types.Vertical || Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                        ? "widgets/panel-background" : "widgets/background"
                width: Kirigami.Units.iconSizes.large + fixedMargins.left + fixedMargins.right
                height: Kirigami.Units.iconSizes.large + fixedMargins.top + fixedMargins.bottom

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.large
                    height: width
                    source: Tools.iconOrDefault(Plasmoid.formFactor, root.cfg_icon)
                }
            }

            QQC2.Menu {
                id: iconMenu

                // Appear below the button
                y: parent.height

                QQC2.MenuItem {
                    text: i18nc("@item:inmenu Open icon chooser dialog", "Choose…")
                    icon.name: "document-open-folder"
                    Accessible.description: i18nc("@info:whatsthis", "Choose an icon for Application Launcher")
                    onClicked: iconDialog.open()
                }
                QQC2.MenuItem {
                    text: i18nc("@item:inmenu Reset icon to default", "Reset to default icon")
                    icon.name: "edit-clear"
                    enabled: root.cfg_icon !== Tools.defaultIconName
                    onClicked: root.cfg_icon = Tools.defaultIconName
                }
                QQC2.MenuItem {
                    text: i18nc("@action:inmenu", "Remove icon")
                    icon.name: "delete"
                    enabled: root.cfg_icon !== "" && menuLabel.text && Plasmoid.formFactor !== PlasmaCore.Types.Vertical
                    onClicked: root.cfg_icon = ""
                }
            }
        }

        Kirigami.ActionTextField {
            id: menuLabel
            enabled: Plasmoid.formFactor !== PlasmaCore.Types.Vertical
            Kirigami.FormData.label: i18nc("@label:textbox", "Text label:")
            text: Plasmoid.configuration.menuLabel
            placeholderText: i18nc("@info:placeholder", "Type here to add a text label")
            onTextEdited: {
                root.cfg_menuLabel = menuLabel.text

                // This is to make sure that we always have a icon if there is no text.
                // If the user remove the icon and remove the text, without this, we'll have no icon and no text.
                // This is to force the icon to be there.
                if (!menuLabel.text) {
                    root.cfg_icon = root.cfg_icon || Tools.defaultIconName
                }
            }
            rightActions: QQC2.Action {
                icon.name: "edit-clear"
                enabled: menuLabel.text !== ""
                text: i18nc("@action:button", "Reset menu label")
                onTriggered: {
                    menuLabel.clear()
                    root.cfg_menuLabel = ""
                    root.cfg_icon = root.cfg_icon || Tools.defaultIconName
                }
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 25
            visible: Plasmoid.formFactor === PlasmaCore.Types.Vertical
            text: i18nc("@info", "A text label cannot be set when the Panel is vertical.")
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: appNameFormat

            Kirigami.FormData.label: i18nc("@label:listbox", "Show applications as:")

            model: [i18nc("@item:inlistbox", "Name only"), i18nc("@item:inlistbox", "Description only"), i18nc("@item:inlistbox", "Name (Description)"), i18nc("@item:inlistbox", "Description (Name)")]
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("General options", "General:")
            spacing: Kirigami.Units.smallSpacing
            QQC2.CheckBox {
                id: alphaSort
                text: i18nc("@option:check", "Sort applications alphabetically")
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18nc("@info:whatsthis", "This doesn't affect how applications are sorted in either search results or the favorites page.")
            }
        }

        QQC2.CheckBox {
            id: compactModeCheckbox
            text: i18nc("@option:check", "Use compact list item style")
            checked: Plasmoid.configuration.compactMode
        }

        QQC2.CheckBox {
            id: highlightNewlyInstalledAppsCheckbox
            text: i18nc("@option:check", "Highlight newly-installed applications")
        }


        QQC2.Button {
            enabled: KConfig.KAuthorized.authorizeControlModule("kcm_plasmasearch")
            icon.name: "settings-configure"
            text: i18nc("@action:button opens plasmasearch kcm", "Configure Search Plugins…")
            onClicked: KCM.KCMLauncher.openSystemSettings("kcm_plasmasearch")
        }

        Item {
            Kirigami.FormData.isSection: true
        }



        QQC2.RadioButton {
            id: showFavoritesInGrid
            Kirigami.FormData.label: i18nc("@title:group prefix for radio button group", "Show favorites:")
            text: i18nc("@option:radio Part of a sentence: 'Show favorites in a grid'", "In a grid")
            QQC2.ButtonGroup.group: favoritesDisplayGroup
            property int index: 0
            checked: Plasmoid.configuration.favoritesDisplay === index
        }

        QQC2.RadioButton {
            id: showFavoritesInList
            text: i18nc("@option:radio Part of a sentence: 'Show favorites in a list'", "In a list")
            QQC2.ButtonGroup.group: favoritesDisplayGroup
            property int index: 1
            checked: Plasmoid.configuration.favoritesDisplay === index
        }

        QQC2.RadioButton {
            id: showAppsInGrid
            Kirigami.FormData.label: i18nc("@title:group prefix for radio button group", "Show All Apps:")
            text: i18nc("@option:radio Part of a sentence: 'Show other applications in a grid'", "In a grid")
            QQC2.ButtonGroup.group: applicationsDisplayGroup
            property int index: 0
            checked: Plasmoid.configuration.applicationsDisplay === index
        }

        QQC2.RadioButton {
            id: showAppsInList
            text: i18nc("@option:radio Part of a sentence: 'Show other applications in a list'", "In a list")
            QQC2.ButtonGroup.group: applicationsDisplayGroup
            property int index: 1
            checked: Plasmoid.configuration.applicationsDisplay === index
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: tabLabelStyleCombo
            Kirigami.FormData.label: i18nc("@label:listbox", "Tab labels:")
            model: [
                i18nc("@item:inlistbox", "Icon and text"),
                i18nc("@item:inlistbox", "Text under icon"),
                i18nc("@item:inlistbox", "Icons only")
            ]
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@label:spinbox", "Gap from panel:")
            spacing: Kirigami.Units.smallSpacing
            QQC2.SpinBox {
                id: popupGapSpin
                from: 0
                to: 40
            }
            QQC2.Label {
                text: i18nc("@label unit", "px (0 = Plasma default, no frame on the panel side)")
                opacity: 0.7
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showRecentTabCheckbox
            Kirigami.FormData.label: i18nc("@label", "Extra tabs:")
            text: i18nc("@option:check", "Recent Apps")
        }

        QQC2.CheckBox {
            id: showRecentFilesTabCheckbox
            text: i18nc("@option:check", "Recent Files")
        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            QQC2.CheckBox {
                id: categoryTabCheckbox
                text: i18nc("@option:check", "Menu category:")
                checked: root.cfg_categoryTab.length > 0
                onToggled: root.cfg_categoryTab = checked ? (categoryField.text.trim() || "Chrome Apps") : ""
            }
            QQC2.TextField {
                id: categoryField
                enabled: categoryTabCheckbox.checked
                placeholderText: "Chrome Apps"
                text: root.cfg_categoryTab.length > 0 ? root.cfg_categoryTab : "Chrome Apps"
                onTextEdited: if (categoryTabCheckbox.checked) root.cfg_categoryTab = text.trim()
            }
            Kirigami.ContextualHelpButton {
                toolTipText: i18nc("@info:whatsthis", "Exact name of a category as it appears in the application menu, e.g. Chrome Apps, Games, Office. The tab is hidden if no such category exists.")
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        Repeater {
            model: root.leaveActionChoices
            delegate: QQC2.CheckBox {
                required property var modelData
                required property int index
                Kirigami.FormData.label: index === 0 ? i18nc("@label", "Power menu:") : ""
                text: modelData.text
                checked: root.cfg_leaveActions.indexOf(modelData.id) >= 0
                onToggled: {
                    const list = root.leaveActionChoices.map(a => a.id)
                        .filter(id => id === modelData.id ? checked : root.cfg_leaveActions.indexOf(id) >= 0)
                    root.cfg_leaveActions = list
                }
            }
        }
    }


    QQC2.ButtonGroup {
        id: favoritesDisplayGroup
        onCheckedButtonChanged: {
            if (checkedButton) {
                root.cfg_favoritesDisplay = checkedButton.index
            }
        }
    }

    QQC2.ButtonGroup {
        id: applicationsDisplayGroup
        onCheckedButtonChanged: {
            if (checkedButton) {
                root.cfg_applicationsDisplay = checkedButton.index
            }
        }
    }

}
