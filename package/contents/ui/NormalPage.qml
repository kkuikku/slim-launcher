/*
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 *
 * Slim Launcher: Places page removed; the footer tabs (Favorites / All
 * Applications) drive the hidden category list of ApplicationsPage
 * (row 0 = Favorites, row 1 = All Applications).
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T

EmptyPage {
    id: root
    // Used by the header to size the avatar/name area
    property real preferredSideBarWidth: footer.tabBar.implicitWidth

    function applyTab(): void {
        const t = footer.tabsModel[footer.tabBar.currentIndex]
        if (t) {
            applicationsPage.showTab(t.kind, t.row)
        }
    }

    // Kept inside a stack view: ApplicationsPage publishes kickoff.contentArea
    // only while its StackView.status is Active.
    contentItem: HorizontalStackView {
        id: stackView
        focus: true
        initialItem: ApplicationsPage {
            id: applicationsPage
            preferredSideBarWidth: 0
        }
    }

    Connections {
        target: footer.tabBar
        function onCurrentIndexChanged() { root.applyTab() }
    }
    Connections {
        target: footer
        // the tab list changed (setting toggled / menu rebuilt): re-apply the current tab
        function onTabsModelChanged() { Qt.callLater(root.applyTab) }
    }

    footer: Footer {
        id: footer
        Binding {
            target: kickoff
            property: "footer"
            value: footer
            restoreMode: Binding.RestoreBinding
        }
        // Eat down events to prevent them from reaching the contentArea or searchField
        Keys.onDownPressed: event => {}
    }
}
