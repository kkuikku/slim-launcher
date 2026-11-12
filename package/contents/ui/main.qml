/*
    SPDX-FileCopyrightText: 2011 Martin Gräßlin <mgraesslin@kde.org>
    SPDX-FileCopyrightText: 2012 Gregor Taetzner <gregor@freenet.de>
    SPDX-FileCopyrightText: 2012 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2013 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg
import org.kde.plasma.components as PC3
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami

import "code/tools.js" as Tools

PlasmoidItem {
    id: kickoff

    width: Kirigami.Units.iconSizes.huge
    height: Kirigami.Units.iconSizes.huge

    switchWidth: fullRepresentationItem ? fullRepresentationItem.Layout.minimumWidth : Kirigami.Units.iconSizes.huge * 10
    switchHeight: fullRepresentationItem ? fullRepresentationItem.Layout.minimumHeight : Kirigami.Units.iconSizes.huge * 10

    // The properties are defined here instead of the singleton because each
    // instance of Kickoff requires different instances of these properties

    readonly property bool inPanel: [
        PlasmaCore.Types.TopEdge,
        PlasmaCore.Types.RightEdge,
        PlasmaCore.Types.BottomEdge,
        PlasmaCore.Types.LeftEdge,
    ].includes(Plasmoid.location)
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // Used to prevent the width from changing frequently when the scrollbar appears or disappears
    readonly property bool mayHaveGridWithScrollBar: allAppsDisplay === 0 || categoryDisplay === 0 || recentAppsDisplay === 0 || recentFilesDisplay === 0
        || (favoritesDisplay === 0 && kickoff.rootModel.favoritesModel.count > minimumGridRowCount * minimumGridRowCount)

    //BEGIN Models
    readonly property Kicker.RootModel rootModel: Kicker.RootModel {
        autoPopulate: false

        // TODO: appletInterface property now can be ported to "applet" and have the real Applet* assigned directly
        appletInterface: kickoff

        appNameFormat: Plasmoid.configuration.appNameFormat
        flat: true // have categories, but no subcategories
        sorted: Plasmoid.configuration.alphaSort
        showSeparators: !sorted && kickoff.allAppsDisplay != 0
        showRootSeparator: true
        showTopLevelItems: true

        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
        showFavoritesPlaceholder: true
        highlightNewlyInstalledApps: Plasmoid.configuration.highlightNewlyInstalledApps

        Component.onCompleted: {
            favoritesModel.initForClient("org.kde.plasma.kickoff.favorites.instance-" + Plasmoid.id)

            if (!Plasmoid.configuration.favoritesPortedToKAstats) {
                if (favoritesModel.count < 1) {
                    favoritesModel.portOldFavorites(Plasmoid.configuration.favorites);
                }
                Plasmoid.configuration.favoritesPortedToKAstats = true;
            }
        }
    }

    readonly property Kicker.RunnerModel runnerModel: Kicker.RunnerModel {
        query: kickoff.searchField ? kickoff.searchField.text : ""
        onRequestUpdateQuery: query => {
            if (kickoff.searchField) {
                kickoff.searchField.text = query;
            }
        }
        appletInterface: kickoff
        mergeResults: true
        favoritesModel: kickoff.rootModel.favoritesModel
    }

    readonly property Kicker.ComputerModel computerModel: Kicker.ComputerModel {
        appletInterface: kickoff
        favoritesModel: kickoff.rootModel.favoritesModel
        systemApplications: Plasmoid.configuration.systemApplications
        Component.onCompleted: {
            //systemApplications = Plasmoid.configuration.systemApplications;
        }
    }

    readonly property alias recentUsageModel: recentUsageModel
    Kicker.RecentUsageModel {
        id: recentUsageModel
        favoritesModel: kickoff.rootModel.favoritesModel
    }

    readonly property alias frequentUsageModel: frequentUsageModel
    Kicker.RecentUsageModel {
        id: frequentUsageModel
        favoritesModel: kickoff.rootModel.favoritesModel
        ordering: 1 // Popular / Frequently Used
    }

    // Slim Launcher: "Recent" tab (applications only, most recent first)
    readonly property alias recentAppsModel: recentAppsModel
    Kicker.RecentUsageModel {
        id: recentAppsModel
        favoritesModel: kickoff.rootModel.favoritesModel
        shownItems: Kicker.RecentUsageModel.OnlyApps
        ordering: 0 // Recent
    }

    // Slim Launcher: "Recent Files" tab
    readonly property alias recentDocsModel: recentDocsModel
    Kicker.RecentUsageModel {
        id: recentDocsModel
        favoritesModel: kickoff.rootModel.favoritesModel
        shownItems: Kicker.RecentUsageModel.OnlyDocs
        ordering: 0 // Recent
    }

    // Slim Launcher: kind of the active footer tab (favorites/all/recent/recentFiles/category)
    property string currentTabKind: "favorites"

    //BEGIN Slim Launcher: per-tab grid (0) / list (1), kept here and saved to the config
    readonly property var displayConfigKeys: ({
        favorites: "favoritesDisplay",
        all: "applicationsDisplay",
        category: "categoryDisplay",
        recent: "recentAppsDisplay",
        recentFiles: "recentFilesDisplay",
    })
    property int favoritesDisplay: Plasmoid.configuration.favoritesDisplay
    property int allAppsDisplay: Plasmoid.configuration.applicationsDisplay
    property int categoryDisplay: Plasmoid.configuration.categoryDisplay
    property int recentAppsDisplay: Plasmoid.configuration.recentAppsDisplay
    property int recentFilesDisplay: Plasmoid.configuration.recentFilesDisplay

    function displayFor(kind: string): int {
        switch (kind) {
        case "favorites": return favoritesDisplay
        case "all": return allAppsDisplay
        case "category": return categoryDisplay
        case "recent": return recentAppsDisplay
        case "recentFiles": return recentFilesDisplay
        }
        return 0
    }
    function toggleDisplay(kind: string): void {
        const v = displayFor(kind) === 0 ? 1 : 0
        switch (kind) {
        case "favorites": favoritesDisplay = v; break
        case "all": allAppsDisplay = v; break
        case "category": categoryDisplay = v; break
        case "recent": recentAppsDisplay = v; break
        case "recentFiles": recentFilesDisplay = v; break
        default: return
        }
        Plasmoid.configuration[displayConfigKeys[kind]] = v // persist
        Qt.callLater(refreshCurrentView)
    }
    property Item applicationsPage: null // set by ApplicationsPage.qml
    function refreshCurrentView(): void {
        if (applicationsPage) {
            applicationsPage.refreshView()
        }
    }
    // keep in sync when changed from the settings dialog
    Connections {
        target: Plasmoid.configuration
        function onValueChanged(key, value) {
            switch (key) {
            case "favoritesDisplay": kickoff.favoritesDisplay = value; break
            case "applicationsDisplay": kickoff.allAppsDisplay = value; break
            case "categoryDisplay": kickoff.categoryDisplay = value; break
            case "recentAppsDisplay": kickoff.recentAppsDisplay = value; break
            case "recentFilesDisplay": kickoff.recentFilesDisplay = value; break
            }
        }
    }
    //END

    //BEGIN Slim Launcher: gap between popup and panel, keep the border on the panel side
    // Plasma (CompactApplet.qml) glues the popup to a non-floating panel with margin 0
    // and removes the border on that side; this pushes it away and keeps the frame.
    property var defaultPopupStyle: null
    function applyPopupStyle(): void {
        const full = kickoff.fullRepresentationItem
        const popup = full ? full.Window.window : null
        if (!popup || !("removeBorderStrategy" in popup) || !("margin" in popup)) {
            return // on the desktop, or not shown in a popup yet
        }
        if (!defaultPopupStyle) {
            defaultPopupStyle = { margin: popup.margin, removeBorderStrategy: popup.removeBorderStrategy }
        }
        const gap = Plasmoid.configuration.popupGap
        if (gap > 0) {
            popup.margin = Math.max(gap, defaultPopupStyle.margin)
            popup.removeBorderStrategy = PlasmaCore.AppletPopup.Never
        } else {
            popup.margin = defaultPopupStyle.margin
            popup.removeBorderStrategy = defaultPopupStyle.removeBorderStrategy
        }
    }
    onExpandedChanged: { if (kickoff.expanded) applyPopupStyle() }
    Connections {
        target: Plasmoid.configuration
        function onValueChanged(key, value) {
            if (key === "popupGap") kickoff.applyPopupStyle()
        }
    }
    //END
    //END

    //BEGIN UI elements
    // Set in FullRepresentation.qml
    property Item header: null

    // Set in Header.qml
    // QTBUG Using PC3.TextField as type makes assignment fail
    // "Cannot assign QObject* to TextField_QMLTYPE_8*"
    property Item searchField: null

    // Set in FullRepresentation.qml, ApplicationPage.qml, PlacesPage.qml
    property Item sideBar: null // is null when searching
    property Item contentArea: null // is searchView when searching

    // Set in NormalPage.qml
    property Item footer: null

    // True when central pane (and header) LayoutMirroring diverges from global
    // LayoutMirroring, in order to achieve the desired sidebar position
    readonly property bool paneSwap: Plasmoid.configuration.paneSwap
    readonly property bool sideBarOnRight: (Application.layoutDirection == Qt.RightToLeft) != paneSwap
    // References to items according to their focus chain order
    readonly property Item firstHeaderItem: header ? (paneSwap ? header.pinButton : header.avatar) : null
    readonly property Item lastHeaderItem: header ? (paneSwap ? header.avatar : header.pinButton) : null
    readonly property Item firstCentralPane: paneSwap ? contentArea : (sideBar ?? contentArea)
    readonly property Item lastCentralPane: paneSwap ? (sideBar ?? contentArea) : contentArea

    readonly property Item dragSource: Item {
        id: dragSource // BUG 449426
        property Item sourceItem
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction | Qt.LinkAction | Qt.MoveAction
    }
    //END

    //BEGIN Metrics
    readonly property KSvg.FrameSvgItem backgroundMetrics: KSvg.FrameSvgItem {
        // Inset defaults to a negative value when not set by margin hints
        readonly property real leftPadding: Math.round(margins.left - Math.max(inset.left, 0))
        readonly property real rightPadding: Math.round(margins.right - Math.max(inset.right, 0))
        readonly property real topPadding: Math.round(margins.top - Math.max(inset.top, 0))
        readonly property real bottomPadding: Math.round(margins.bottom - Math.max(inset.bottom, 0))
        readonly property real spacing: Math.round(leftPadding)
        visible: false
        imagePath: Plasmoid.formFactor === PlasmaCore.Types.Planar ? "widgets/background" : "dialogs/background"
    }

    // This is here rather than in the singleton with the other metrics items
    // because the list delegate's height depends on a configuration setting
    // and the singleton can't access those
    readonly property real listDelegateHeight: listDelegate.height
    KickoffListDelegate {
        id: listDelegate
        visible: false
        enabled: false
        model: null
        index: -1
        text: "asdf"
        url: ""
        decoration: "start-here-kde"
        description: "asdf"
        action: null
        indicator: null
    }

    // Used to show smaller Kickoff on small screens
    readonly property int minimumGridRowCount: Math.min(Screen.desktopAvailableWidth, Screen.desktopAvailableHeight) * Screen.devicePixelRatio < KickoffSingleton.gridCellSize * 4 + (fullRepresentationItem ? fullRepresentationItem.normalPage.preferredSideBarWidth : KickoffSingleton.gridCellSize * 2) ? 2 : 4
    //END

    Plasmoid.icon: Plasmoid.configuration.icon

    preferredRepresentation: compactRepresentation

    fullRepresentation: FullRepresentation { focus: true }

    // Only exists because the default CompactRepresentation doesn't:
    // - open on drag
    // - allow defining a custom drop handler
    // - expose the ability to show text below or beside the icon
    // TODO remove once it gains those features
    compactRepresentation: MouseArea {
        id: compactRoot

        // Taken from DigitalClock to ensure uniform sizing when next to each other
        readonly property bool tooSmall: Plasmoid.formFactor === PlasmaCore.Types.Horizontal && Math.round(2 * (compactRoot.height / 5)) <= Kirigami.Theme.smallFont.pixelSize

        readonly property bool shouldHaveIcon: Plasmoid.formFactor === PlasmaCore.Types.Vertical || Plasmoid.icon !== ""
        readonly property bool shouldHaveLabel: Plasmoid.formFactor !== PlasmaCore.Types.Vertical && Plasmoid.configuration.menuLabel !== ""

        readonly property int iconSize: Kirigami.Units.iconSizes.large

        readonly property var sizing: {
            const displayedIcon = imageFallback.visible ? imageFallback : (buttonIcon.valid ? buttonIcon : buttonIconFallback);

            let impWidth = 0;
            if (shouldHaveIcon) {
                impWidth += displayedIcon.width;
            }
            if (shouldHaveLabel) {
                impWidth += labelTextField.contentWidth + labelTextField.Layout.leftMargin + labelTextField.Layout.rightMargin;
            }
            const impHeight = displayedIcon.height > 0 ? displayedIcon.height : iconSize

            // at least square, but can be wider/taller
            if (kickoff.inPanel) {
                if (kickoff.vertical) {
                    return {
                        preferredWidth: iconSize,
                        preferredHeight: impHeight
                    };
                } else { // horizontal
                    return {
                        preferredWidth: impWidth,
                        preferredHeight: iconSize
                    };
                }
            } else {
                return {
                    preferredWidth: impWidth,
                    preferredHeight: Kirigami.Units.iconSizes.small,
                };
            }
        }

        implicitWidth: iconSize
        implicitHeight: iconSize

        Layout.preferredWidth: sizing.preferredWidth
        Layout.preferredHeight: sizing.preferredHeight
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight

        hoverEnabled: true

        property bool wasExpanded

        Accessible.name: Plasmoid.title
        Accessible.role: Accessible.Button

        onPressed: wasExpanded = kickoff.expanded
        onClicked: kickoff.expanded = !wasExpanded

        DropArea {
            id: compactDragArea
            anchors.fill: parent
            onEntered: drag => {
                if (drag.hasUrls) {
                    expandOnDragTimer.start()
                }
            }
            onExited: expandOnDragTimer.stop()
        }

        Timer {
            id: expandOnDragTimer
            // this is an interaction and not an animation, so we want it as a constant
            interval: 250
            onTriggered: kickoff.expanded = true
        }

        RowLayout {
            id: iconLabelRow
            anchors.fill: parent
            spacing: 0

            Kirigami.Icon {
                id: buttonIcon

                Layout.fillWidth: kickoff.vertical
                Layout.fillHeight: !kickoff.vertical
                Layout.preferredWidth: kickoff.vertical ? -1 : height / (implicitHeight / implicitWidth)
                Layout.preferredHeight: !kickoff.vertical ? -1 : width * (implicitHeight / implicitWidth)
                Layout.maximumHeight: Kirigami.Units.iconSizes.huge
                Layout.maximumWidth: Kirigami.Units.iconSizes.huge
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                source: Tools.iconOrDefault(Plasmoid.formFactor, Plasmoid.icon)
                active: compactRoot.containsMouse || compactDragArea.containsDrag
                roundToIconSize: implicitHeight === implicitWidth
                visible: valid && !imageFallback.visible
            }

            Kirigami.Icon {
                id: buttonIconFallback
                // fallback is assumed to be square
                Layout.fillWidth: kickoff.vertical
                Layout.fillHeight: !kickoff.vertical
                Layout.preferredWidth: kickoff.vertical ? -1 : height
                Layout.preferredHeight: !kickoff.vertical ? -1 : width
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                source: buttonIcon.valid ? null : Tools.defaultIconName
                active: compactRoot.containsMouse || compactDragArea.containsDrag
                visible: !buttonIcon.valid && Plasmoid.icon !== "" && !imageFallback.visible
            }

            Image {
                id: imageFallback

                readonly property bool nonSquareImage: sourceSize.width != sourceSize.height

                visible: nonSquareImage && status == Image.Ready
                source: Plasmoid.icon.startsWith("/") ? "file:" + Plasmoid.icon.split("/").map(encodeURIComponent).join("/") : ""

                Layout.fillWidth: kickoff.vertical
                Layout.fillHeight: !kickoff.vertical
                Layout.preferredWidth: kickoff.vertical ? -1 : height / (implicitHeight / implicitWidth)
                Layout.preferredHeight: !kickoff.vertical ? -1 : width * (implicitHeight / implicitWidth)
                Layout.maximumHeight: kickoff.vertical ? -1 : Kirigami.Units.iconSizes.huge
                Layout.maximumWidth: kickoff.vertical ? Kirigami.Units.iconSizes.huge : -1
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }

            PC3.Label {
                id: labelTextField

                Layout.fillHeight: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing

                text: Plasmoid.configuration.menuLabel
                textFormat: Text.StyledText
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.NoWrap
                fontSizeMode: Text.VerticalFit
                font.pixelSize: compactRoot.tooSmall ? Kirigami.Theme.defaultFont.pixelSize : Kirigami.Units.iconSizes.roundedIconSize(Kirigami.Units.gridUnit * 2)
                minimumPointSize: Kirigami.Theme.smallFont.pointSize
                visible: compactRoot.shouldHaveLabel
            }
        }
    }

    Kicker.ProcessRunner {
        id: processRunner
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18nc("@action:inmenu launches kmenuedit", "Edit Applications…")
            icon.name: "kmenuedit"
            visible: Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
            onTriggered: processRunner.runMenuEditor()
        }
    ]

    Component.onCompleted: {
        Plasmoid.activationTogglesExpanded = true
    }
} // root
