/*
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.extras as PlasmaExtras

BasePage {
    id: root
    showSideBar: false
    Component.onCompleted: kickoff.applicationsPage = root

    function refreshView(): void {
        const sv = root.contentAreaItem
        if (sv) {
            sv.refreshView()
        }
    }

    // Slim Launcher: called by the footer tabs.
    // kind: "favorites" (row 0), "all" (row 1), "category" (row = category row), "recent", "recentFiles"
    function showTab(kind: string, row: int): void {
        const sv = root.contentAreaItem
        if (!sv || !root.sideBarItem) {
            return
        }
        kickoff.currentTabKind = kind
        if (kind === "recent" || kind === "recentFiles") {
            sv.showRecent(kind)
        } else if (root.sideBarItem.currentIndex !== row) {
            root.sideBarItem.currentIndex = row // triggers syncToSideBar()
        } else {
            sv.syncToSideBar() // e.g. coming back from Recent to the same row
        }
    }

    property real flashFavorite: 0

    // Flash favorites when adding one.
    SequentialAnimation {
        id: flashFavoriteAnimation
        loops: 2
        alwaysRunToEnd: true

        NumberAnimation {
            target: root
            property: "flashFavorite"
            from: 0
            to: 1
            duration: Kirigami.Units.veryLongDuration
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "flashFavorite"
            to: 0
            duration: Kirigami.Units.veryLongDuration
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: kickoff.rootModel.favoritesModel
        function onFavoriteAdded() : void {
            flashFavoriteAnimation.restart();
        }
    }

    sideBarComponent: KickoffListView {
        id: sideBar
        focus: true // needed for Loaders
        model: kickoff.rootModel
        isSidebar: true
        // needed otherwise app displayed at top-level will show a first character as group.
        section.property: ""
        delegate: KickoffListDelegate {
            id: sideBarDelegate
            width: view.availableWidth
            isCategoryListItem: true
            background: PlasmaExtras.Highlight {
                // I have to do this for it to actually fill the item for some reason
                anchors.fill: parent
                active: false
                hovered: sideBarDelegate.mouseArea.containsMouse || (flashFavoriteAnimation.running && sideBarDelegate.index === 0) || ((dropAreaLoader.item as DropArea)?.containsAcceptableDrag ?? false) || sideBarDelegate.ListView.isCurrentItem
                visible: !sideBarDelegate.isSeparator && hovered
                opacity: flashFavoriteAnimation.running && sideBarDelegate.index === 0 ? root.flashFavorite : 1
            }

            component FavoritesDropArea: DropArea {
                // should be  "as AbstractKickoffItemDelegate", but the type system gets confused when changing view style at runtime
                readonly property Item draggedItem: kickoff.dragSource.sourceItem
                readonly property bool acceptableDrag: draggedItem && !kickoff.rootModel.favoritesModel.isFavorite(draggedItem.model.favoriteId)
                readonly property bool containsAcceptableDrag:  acceptableDrag && containsDrag
                function evaluateEvent(event: DragEvent) : void {
                    if (acceptableDrag) {
                        event.accept(Qt.CopyAction)
                    } else {
                        event.accept(Qt.IgnoreAction)
                    }
                }
            }

            Loader {
                id: dropAreaLoader
                anchors.fill: parent
                active: sideBarDelegate.index === 0 && !!kickoff.dragSource.sourceItem
                sourceComponent: FavoritesDropArea {
                    onPositionChanged: event => evaluateEvent(event)
                    onEntered: event =>  evaluateEvent(event)
                    onDropped: event => {
                        if (acceptableDrag && !sideBarDelegate.ListView.isCurrentItem) {
                            kickoff.rootModel.favoritesModel.addFavorite(draggedItem.model.favoriteId, sideBar.model.favoritesModel.count)
                            event.accept(Qt.CopyAction)
                        } else {
                            event.accept(Qt.IgnoreAction)
                        }
                    }
                }
            }
        }
    }

    contentAreaComponent: VerticalStackView {
        id: stackView

        popEnter: Transition {
            NumberAnimation {
                property: "x"
                from: 0.5 * root.width
                to: 0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }

        pushEnter: Transition {
            NumberAnimation {
                property: "x"
                from: 0.5 * -root.width
                to: 0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }

        readonly property string preferredFavoritesViewObjectName: kickoff.favoritesDisplay === 0 ? "favoritesGridView" : "favoritesListView"
        readonly property Component preferredFavoritesViewComponent: kickoff.favoritesDisplay === 0 ? favoritesGridViewComponent : favoritesListViewComponent
        readonly property string preferredAllAppsViewObjectName: kickoff.allAppsDisplay === 0 ? "listOfGridsView" : "applicationsListView"
        readonly property Component preferredAllAppsViewComponent: kickoff.allAppsDisplay === 0 ? listOfGridsViewComponent : applicationsListViewComponent

        readonly property string preferredAppsViewObjectName: kickoff.categoryDisplay === 0 ? "applicationsGridView" : "applicationsListView"
        readonly property Component preferredAppsViewComponent: kickoff.categoryDisplay === 0 ? applicationsGridViewComponent : applicationsListViewComponent
        // NOTE: The 0 index modelForRow isn't supposed to be used. That's just how it works.
        // But to trigger model data update, set initial value to 0
        property int appsModelRow: 0
        readonly property Kicker.AppsModel appsModel: kickoff.rootModel.modelForRow(appsModelRow)
        Connections {
            target: kickoff.rootModel
            function onRefreshed() { // recalculate appsModel binding on rootModel refresh;
                stackView.appsModelRowChanged() // modelForRow does not create dependency
            }
        }
        focus: true
        initialItem: preferredFavoritesViewComponent

        function showSectionView(sectionName: string, parentView: KickoffListView): void {
            stackView.push(applicationsSectionViewComponent, {
                currentSection: sectionName,
                parentView,
            });
        }

        Component {
            id: favoritesListViewComponent
            DropAreaListView {
                id: favoritesListView
                objectName: "favoritesListView"
                mainContentView: true
                focus: true
                model: kickoff.rootModel.favoritesModel
            }
        }

        Component {
            id: favoritesGridViewComponent
            DropAreaGridView {
                id: favoritesGridView
                objectName: "favoritesGridView"
                focus: true
                model: kickoff.rootModel.favoritesModel
            }
        }

        Component {
            id: applicationsListViewComponent

            KickoffListView {
                id: applicationsListView
                objectName: "applicationsListView"
                mainContentView: true
                model: stackView.appsModel
                // we want to semantically switch between group and "", disabling grouping, workaround for QTBUG-121797
                section.property: model && model.description === "KICKER_ALL_MODEL" ? "group" : "_unset"
                section.criteria: ViewSection.FirstCharacter
                hasSectionView: stackView.appsModelRow === 1

                onShowSectionViewRequested: sectionName => {
                    stackView.showSectionView(sectionName, this);
                }
            }
        }

        Component {
            id: applicationsSectionViewComponent

            SectionView {
                id: sectionView
                model: stackView.appsModel.sections

                onHideSectionViewRequested: index => {
                    stackView.pop();
                    stackView.currentItem.view.positionViewAtIndex(index, ListView.Beginning);
                    stackView.currentItem.currentIndex = index;
                }
            }
        }

        Component {
            id: applicationsGridViewComponent
            KickoffGridView {
                id: applicationsGridView
                objectName: "applicationsGridView"
                model: stackView.appsModel
            }
        }

        Component {
            id: listOfGridsViewComponent

            ListOfGridsView {
                id: listOfGridsView
                objectName: "listOfGridsView"
                mainContentView: true
                gridModel: stackView.appsModel

                onShowSectionViewRequested: sectionName => {
                    stackView.showSectionView(sectionName, this);
                }
            }
        }

        onPreferredFavoritesViewComponentChanged: {
            if (root.sideBarItem !== null && !stackView.inRecentView && root.sideBarItem.currentIndex === 0) {
                stackView.replace(stackView.preferredFavoritesViewComponent)
            }
        }
        onPreferredAllAppsViewComponentChanged: {
            if (root.sideBarItem !== null && !stackView.inRecentView && root.sideBarItem.currentIndex === 1) {
                stackView.replace(stackView.preferredAllAppsViewComponent)
            }
        }
        onPreferredAppsViewComponentChanged: {
            if (root.sideBarItem !== null && !stackView.inRecentView && root.sideBarItem.currentIndex > 1) {
                stackView.replace(stackView.preferredAppsViewComponent)
            }
        }

        // Slim Launcher: Recent Apps / Recent Files views (grid or list = "other applications" setting)
        readonly property bool inRecentView: currentItem !== null && currentItem.objectName.startsWith("recent")
        property string recentKind: "recent" // "recent" (apps) or "recentFiles"
        readonly property Component preferredRecentViewComponent: (recentKind === "recentFiles" ? kickoff.recentFilesDisplay : kickoff.recentAppsDisplay) === 0 ? recentGridViewComponent : recentListViewComponent
        Component {
            id: recentGridViewComponent
            KickoffGridView {
                objectName: (stackView.recentKind === "recentFiles" ? "recentFilesView" : "recentAppsView") + "Grid"
                focus: true
                model: stackView.recentKind === "recentFiles" ? kickoff.recentDocsModel : kickoff.recentAppsModel
            }
        }
        Component {
            id: recentListViewComponent
            KickoffListView {
                objectName: (stackView.recentKind === "recentFiles" ? "recentFilesView" : "recentAppsView") + "List"
                focus: true
                mainContentView: true
                model: stackView.recentKind === "recentFiles" ? kickoff.recentDocsModel : kickoff.recentAppsModel
            }
        }
        function recentViewName(kind: string): string {
            const files = kind === "recentFiles"
            const grid = (files ? kickoff.recentFilesDisplay : kickoff.recentAppsDisplay) === 0
            return (files ? "recentFilesView" : "recentAppsView") + (grid ? "Grid" : "List")
        }
        function showRecent(kind: string): void {
            if (stackView.currentItem.objectName !== recentViewName(kind)) {
                stackView.recentKind = kind
                stackView.replace(stackView.preferredRecentViewComponent)
            }
        }
        // Slim Launcher: make the visible view match the current tab's grid/list setting
        function refreshView(): void {
            const kind = kickoff.currentTabKind
            const grid = kickoff.displayFor(kind) === 0
            let name, comp
            if (kind === "recent" || kind === "recentFiles") {
                stackView.recentKind = kind
                name = recentViewName(kind)
                comp = grid ? recentGridViewComponent : recentListViewComponent
            } else if (kind === "favorites") {
                name = grid ? "favoritesGridView" : "favoritesListView"
                comp = grid ? favoritesGridViewComponent : favoritesListViewComponent
            } else if (kind === "all") {
                name = grid ? "listOfGridsView" : "applicationsListView"
                comp = grid ? listOfGridsViewComponent : applicationsListViewComponent
            } else {
                name = grid ? "applicationsGridView" : "applicationsListView"
                comp = grid ? applicationsGridViewComponent : applicationsListViewComponent
            }
            if (currentItem.objectName !== name) {
                stackView.replace(comp)
            }
        }

        onPreferredRecentViewComponentChanged: {
            if (inRecentView) {
                stackView.replace(stackView.preferredRecentViewComponent)
            }
        }

        Connections {
            target: root.sideBarItem
            function onCurrentIndexChanged() { stackView.syncToSideBar() }
        }
        function syncToSideBar(): void {
            {
                // Only update row index if the condition is met.
                // The 0 index modelForRow isn't supposed to be used. That's just how it works.
                if (root.sideBarItem.currentIndex > 0) {
                    stackView.appsModelRow = root.sideBarItem.currentIndex
                }
                if (root.sideBarItem.currentIndex === 0
                    && stackView.currentItem.objectName !== stackView.preferredFavoritesViewObjectName) {
                    stackView.replace(stackView.preferredFavoritesViewComponent)
                } else if (root.sideBarItem.currentIndex === 1
                    && stackView.currentItem.objectName !== stackView.preferredAllAppsViewObjectName) {
                    stackView.replace(stackView.preferredAllAppsViewComponent)
                } else if (root.sideBarItem.currentIndex > 1
                    && stackView.currentItem.objectName !== stackView.preferredAppsViewObjectName) {
                    stackView.replace(stackView.preferredAppsViewComponent)
                }
            }
        }
        Connections {
            target: kickoff
            function onExpandedChanged() {
                if (!kickoff.expanded && kickoff.contentArea.currentItem) {
                    kickoff.contentArea.currentItem.forceActiveFocus()
                }
            }
        }
    }
    // NormalPage doesn't get destroyed when deactivated, so the binding uses
    // StackView.status and visible. This way the bindings are reset when
    // NormalPage is Activated again.
    Binding {
        target: kickoff
        property: "contentArea"
        value: root.contentAreaItem.currentItem // NOT just root.contentAreaItem
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }
}
