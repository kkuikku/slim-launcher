/*
    SPDX-FileCopyrightText: 2020 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Kai Uwe Broulik <kde@broulik.de>

    SPDX-License-Identifier: GPL-2.0-or-later

    Slim Launcher: a single power icon that opens a menu with
    Suspend / Restart / Shut Down / Log Out.
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.private.kicker as Kicker
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PC3
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.plasmoid
import org.kde.kcmutils as KCM

RowLayout {
    id: root

    required property real maximumWidth

    // Action IDs (plasma-workspace applets/kicker/systementry.cpp), chosen in the settings
    readonly property var wantedActions: Array.from(Plasmoid.configuration.leaveActions)
    onWantedActionsChanged: menuModel.invalidateFilter()

    spacing: kickoff.backgroundMetrics.spacing

    Kicker.SystemModel {
        id: systemModel
        favoritesModel: kickoff.rootModel.systemFavoritesModel
    }

    KItemModels.KSortFilterProxyModel {
        id: menuModel
        sourceModel: systemModel
        filterRowCallback: (sourceRow, sourceParent) => {
            const role = sourceModel.KItemModels.KRoleNames.role("favoriteId");
            const id = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), role);
            return root.wantedActions.includes(id);
        }
        function trigger(row) {
            const sourceIndex = mapToSource(index(row, 0));
            systemModel.trigger(sourceIndex.row, "", null);
        }
    }

    Item { Layout.fillWidth: true }

    PC3.ToolButton {
        id: settingsButton
        display: PC3.AbstractButton.IconOnly
        icon.name: "systemsettings"
        icon.width: Kirigami.Units.iconSizes.smallMedium
        icon.height: Kirigami.Units.iconSizes.smallMedium
        text: i18nc("@action:button", "System Settings")
        PC3.ToolTip.text: text
        PC3.ToolTip.visible: hovered || activeFocus
        PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
        Keys.onEnterPressed: clicked()
        Keys.onReturnPressed: clicked()
        onClicked: {
            KCM.KCMLauncher.openSystemSettings("") // empty = default page
            kickoff.expanded = false
        }
    }

    PC3.ToolButton {
        id: powerButton
        visible: menuModel.count > 0
        Accessible.role: Accessible.ButtonMenu
        display: PC3.AbstractButton.IconOnly
        icon.name: "system-shutdown"
        icon.width: Kirigami.Units.iconSizes.smallMedium
        icon.height: Kirigami.Units.iconSizes.smallMedium
        text: i18nc("@action:button", "Leave…")
        down: contextMenu.status === PlasmaExtras.Menu.Open || pressed

        PC3.ToolTip.text: text
        PC3.ToolTip.visible: hovered || activeFocus
        PC3.ToolTip.delay: Kirigami.Units.toolTipDelay

        Keys.onTabPressed: event => kickoff.firstHeaderItem.forceActiveFocus(Qt.TabFocusReason)
        Keys.onLeftPressed: event => {
            if (!mirrored) nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason)
        }
        Keys.onRightPressed: event => {
            if (mirrored) nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason)
        }
        function openMenu() {
            contextMenu.visualParent = this;
            contextMenu.openRelative();
        }
        Keys.onEnterPressed: openMenu()
        Keys.onReturnPressed: openMenu()
        onPressed: openMenu()
    }

    // Items appear in SystemModel order; actions unavailable on this system are omitted
    Instantiator {
        model: menuModel
        delegate: PlasmaExtras.MenuItem {
            required property int index
            required property var model

            text: model.display
            icon: model.decoration
            onClicked: {
                menuModel.trigger(index)
                if (kickoff.hideOnWindowDeactivate) {
                    kickoff.expanded = false;
                }
            }
        }
        onObjectAdded: (index, object) => contextMenu.addMenuItem(object)
        onObjectRemoved: (index, object) => contextMenu.removeMenuItem(object)
    }

    PlasmaExtras.Menu {
        id: contextMenu
        placement: {
            switch (Plasmoid.location) {
            case PlasmaCore.Types.LeftEdge:
            case PlasmaCore.Types.RightEdge:
            case PlasmaCore.Types.TopEdge:
                return PlasmaExtras.Menu.BottomPosedRightAlignedPopup;
            case PlasmaCore.Types.BottomEdge:
            default:
                return PlasmaExtras.Menu.TopPosedRightAlignedPopup;
            }
        }
    }
}
