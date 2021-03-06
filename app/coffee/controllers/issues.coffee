# Copyright 2013 Andrey Antukh <niwi@niwi.be>
#
# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

IssuesController = ($scope, $rootScope, $routeParams, $filter, $q, rs, $data, $confirm, $modal, $i18next, $location, SelectedTags) ->
    # Global Scope Variables
    $rootScope.pageTitle = $i18next.t('common.issues')
    $rootScope.pageSection = 'issues'
    $rootScope.pageBreadcrumb = [
        ["", ""],
        [$i18next.t('common.issues'), null]
    ]

    SelectedTags.issues_order.setDefault({field: 'created_date', reverse: true})
    $scope.filtersOpened = false
    $scope.filtersData = {}
    $scope.sortingOrder = SelectedTags.issues_order.getField()
    $scope.sortingReverse = SelectedTags.issues_order.isReverse()
    $scope.page = 1
    $scope.showGraphs = false

    #####
    ## Tags generation functions
    #####

    $scope.selectedTags = -> _.flatten((tags.values() for tags in _.values(SelectedTags.issues)), true)

    generateTagId = (tag) ->
        return "#{tag.type}-#{tag.id or tag.name}"

    isTagSelected = (tag) ->
        return SelectedTags.issues[tag.type].fetch(tag)?

    toggleTag = (tag) ->
        tags = SelectedTags.issues[tag.type]
        if tags.fetch(tag)?
            tags.remove(tag)
        else
            tags.store(tag)

        $scope.currentPage = 0
        filterIssues()

    generateTagsFromList = (list, constants, type, scopeVar) ->
        tags = []
        for value in list
            [id, count] = value
            element = constants[id]
            tag = {
                id: element.id,
                name: element.name,
                count: count,
                type: type,
                color: element.color
            }
            tags.push(tag)

        $scope[scopeVar] = tags

    generateTagsFromUsers = (list, type, scopeVar)->
        tags = []
        for userCounter in list
            if userCounter[0] is null
                tag = {
                    id: "null",
                    name: $i18next.t("common.unassigned"),
                    count: userCounter[1],
                    type: type
                }
            else
                user = $scope.constants.users[userCounter[0]]
                tag = {
                    id: user.id,
                    name: gm.utils.truncate(user.full_name, 17),
                    count: userCounter[1],
                    type: type
                }

            tags.push(tag)

        $scope[scopeVar] = _.sortBy tags, (item) ->
            if item.id == "null"
                # NOTE: This is a hack to order users by full name but set
                #       "Unassigned" as the first element. \o/ \o/ \o/ \o/
                return "0000000000000000"
            return item.name

    generateTagList = ->
        tags = []

        for tagCounter in $scope.filtersData.tags
            tag = {id: tagCounter[0], name: tagCounter[0], count: tagCounter[1], type: "tags"}
            tags.push(tag)

        $scope.tags = tags

    regenerateTags = ->
        generateTagsFromList($scope.filtersData.statuses, $scope.constants.issueStatuses, "status", "statusTags")
        generateTagsFromList($scope.filtersData.types, $scope.constants.types, "type", "$scope.selectedTagstypeTags")
        generateTagsFromList($scope.filtersData.severities, $scope.constants.severities, "severity", "severityTags")
        generateTagsFromList($scope.filtersData.priorities, $scope.constants.priorities, "priority", "priorityTags")
        generateTagsFromUsers($scope.filtersData.owners, "owner", "addedByTags")
        generateTagsFromUsers($scope.filtersData.assigned_to, "assigned_to", "assignedToTags")
        generateTagList()

    getFilterParams = ->

        params = {"page": $scope.page}

        for key, value of _.groupBy($scope.selectedTags(), "type")
            params[key] = _.map(value, "id").join(",")

        params["order_by"] = $scope.sortingOrder
        if $scope.sortingReverse
            params["order_by"] = "-#{params["order_by"]}"

        return params

    filterIssues = ->
        $scope.$emit("spinner:start")

        params = getFilterParams()

        rs.getIssues($scope.projectId, params).then (result) ->
            $scope.issues = result.models
            $scope.count = result.count
            $scope.paginatedBy = result.paginatedBy
            $scope.$emit("spinner:stop")

    loadIssuesData = ->
        promise = rs.getIssuesFiltersData($scope.projectId).then (data) ->
            $scope.filtersData = data
            regenerateTags()
            loadStats()
            return data

        return promise

    loadStats = ->
        rs.getIssuesStats($scope.projectId).then (data) ->
            $scope.issuesStats = data

    # Load initial data
    rs.resolve($routeParams.pslug).then (data) ->
        $rootScope.projectSlug = $routeParams.pslug
        $rootScope.projectId = data.project
        $data.loadProject($scope).then ->
            $data.loadUsersAndRoles($scope).then ->
                loadIssuesData().then ->
                    filterIssues()

    $scope.setPage = (n) ->
        $scope.page = n
        filterIssues()

    $scope.refreshIssues = ->
        $scope.refreshing = true
        loadIssuesData().then ->
            filterIssues().then ->
                $scope.refreshing = false

    $scope.toggleTag = toggleTag
    $scope.isTagSelected = isTagSelected

    $scope.openCreateIssueForm = ->
        promise = $modal.open("issue-form", {'type': 'create'})
        promise.then (issue) ->
            $scope.issues.push(issue)
            regenerateTags()
            loadStats()
            filterIssues()

    $scope.openEditIssueForm = (issue) ->
        promise = $modal.open("issue-form", {'issue': issue, 'type': 'edit'})
        promise.then ->
            regenerateTags()
            loadStats()
            filterIssues()

    $scope.toggleShowGraphs = gm.utils.safeDebounced $scope, 500, ->
        $scope.showGraphs = not $scope.showGraphs

    $scope.updateIssueAssignation = (issue, id) ->
        issue.assigned_to = id || null
        issue.save().then ->
            regenerateTags()
            loadStats()

    $scope.updateIssueStatus = (issue, id) ->
        issue.status = id
        issue.save().then ->
            regenerateTags()
            loadStats()

    $scope.updateIssueSeverity = (issue, id) ->
        issue.severity = id

        issue.save().then ->
            regenerateTags()
            loadStats()

    $scope.updateIssuePriority = (issue, id) ->
        issue.priority = id
        issue.save().then ->
            regenerateTags()
            loadStats()

    $scope.changeSort = (field, reverse) ->
        SelectedTags.issues_order.set field: field, reverse: reverse
        $scope.sortingOrder = field
        $scope.sortingReverse = reverse
        filterIssues()

    $scope.isSortingBy = (field) -> $scope.sortingOrder == field
    $scope.isSortingReverse = (field) -> $scope.sortingOrder == field and $scope.sortingReverse

    $scope.removeIssue = (issue) ->
        issue.remove().then ->
            index = $scope.issues.indexOf(issue)
            $scope.issues.splice(index, 1)

            regenerateTags()
            loadStats()
            filterIssues()

    $scope.openIssue = (projectSlug, issueRef)->
        $location.url("/project/#{projectSlug}/issues/#{issueRef}")

    return


IssuesViewController = ($scope, $location, $rootScope, $routeParams, $q, rs, $data,
                        $confirm, $gmFlash, $i18next, SelectedTags) ->
    $rootScope.pageTitle = $i18next.t('common.issues')
    $rootScope.pageSection = 'issues'
    $rootScope.pageBreadcrumb = [
        ["", ""],
        [$i18next.t('common.issues'), null],
    ]

    $scope.issue = {}
    $scope.form = {}
    $scope.updateFormOpened = false
    $scope.newAttachments = []
    $scope.attachments = []

    loadIssue = ->
        params = {}
        tags = SelectedTags.issues.tags.join()
        status = SelectedTags.issues.status.join()
        type = SelectedTags.issues.type.join()
        severity = SelectedTags.issues.severity.join()
        priority = SelectedTags.issues.priority.join()
        owner = SelectedTags.issues.owner.join()
        assigned_to = SelectedTags.issues.assigned_to.join()
        order_by = SelectedTags.issues_order.getField()
        if SelectedTags.issues_order.isReverse()
            order_by = "-#{order_by}"

        params.tags = tags if tags != ""
        params.status = status if status != ""
        params.type = type if type != ""
        params.severity = severity if severity != ""
        params.priority = priority if priority != ""
        params.owner = owner if owner != ""
        params.assigned_to = assigned_to if assigned_to != ""
        params.order_by = order_by

        rs.getIssue($scope.projectId, $scope.issueId, params).then (issue) ->
            $scope.issue = issue
            $scope.form = _.extend({}, $scope.issue._attrs)

            breadcrumb = _.clone($rootScope.pageBreadcrumb)
            breadcrumb[1] = [$i18next.t('common.issues'), $rootScope.urls.issuesUrl($scope.projectSlug)]
            breadcrumb[2] = ["##{issue.ref}", null]
            $rootScope.pageTitle = "#{$i18next.t('common.issues')} - ##{issue.ref}"

            $rootScope.pageBreadcrumb = breadcrumb

    loadHistorical = (page=1) ->
        rs.getIssueHistorical($scope.issueId, {page: page}).then (historical) ->
            if $scope.historical and page != 1
                historical.models = _.union($scope.historical.models, historical.models)

            $scope.showMoreHistoricaButton = historical.models.length < historical.count
            $scope.historical = historical

    $scope.loadMoreHistorical = ->
        page = if $scope.historical then $scope.historical.current + 1 else 1
        loadHistorical(page=page)

    loadProjectTags = ->
        rs.getProjectTags($scope.projectId).then (data) ->
            $scope.projectTags = data

    loadAttachments = ->
        promise = rs.getIssueAttachments($scope.projectId, $scope.issueId)
        promise.then (attachments) ->
            $scope.attachments = attachments

    saveNewAttachments = ->
        if $scope.newAttachments.length == 0
            return

        promises = []
        for attachment in $scope.newAttachments
            promise = rs.uploadIssueAttachment($scope.projectId, $scope.issueId, attachment)
            promises.push(promise)

        promise = $q.all(promises)
        promise.then ->
            gm.safeApply $scope, ->
                $scope.newAttachments = []
                loadAttachments()

    rs.resolve($routeParams.pslug, undefined, undefined, $routeParams.ref).then (data) ->
        $rootScope.projectSlug = $routeParams.pslug
        $rootScope.projectId = data.project
        $rootScope.issueId = data.issue

        $data.loadProject($scope).then ->
            $data.loadUsersAndRoles($scope).then ->
                loadIssue()
                loadAttachments()
                loadHistorical()
                loadProjectTags()

    $scope.isSameAs = (property, id) ->
        return ($scope.issue[property] == parseInt(id, 10))

    $scope.submit = gm.utils.safeDebounced $scope, 400, ->
        for key, value of $scope.form
            $scope.issue[key] = value

        $scope.$emit("spinner:start")

        gm.safeApply $scope, ->
            promise = $scope.issue.save()
            promise.then ->
                $scope.$emit("spinner:stop")
                loadIssue()
                loadHistorical()
                saveNewAttachments()
                $gmFlash.info($i18next.t("issue.issue-saved"))

            promise.then null, (data) ->
                $scope.checksleyErrors = data

    $scope.removeAttachment = (attachment) ->
        promise = $confirm.confirm($i18next.t('common.are-you-sure'))
        promise.then () ->
            $scope.attachments = _.without($scope.attachments, attachment)
            attachment.remove()

    $scope.removeNewAttachment = (attachment) ->
        $scope.newAttachments = _.without($scope.newAttachments, attachment)

    $scope.removeIssue = (issue) ->
        promise = $confirm.confirm($i18next.t('common.are-you-sure'))
        promise.then ->
            issue.remove().then ->
                $location.url("/project/#{$scope.projectSlug}/issues/")

    $scope.$on "select2:changed", (ctx, value) ->
        $scope.form.tags = value

    return


IssuesModalController = ($scope, $rootScope, $gmOverlay, rs, $gmFlash, $i18next, $confirm, $q) ->
    $scope.type = "create"
    $scope.formOpened = false

    # Load data
    $scope.defered = null
    $scope.context = null

    $scope.newAttachments = []
    $scope.attachments = []

    saveNewAttachments = (projectId, issueId) ->
        if $scope.newAttachments.length == 0
            return

        promises = []
        for attachment in $scope.newAttachments
            promise = rs.uploadIssueAttachment(projectId, issueId, attachment)
            promises.push(promise)

        promise = $q.all(promises)
        promise.then ->
            gm.safeApply $scope, ->
                $scope.newAttachments = []
        return promise

    $scope.removeAttachment = (attachment) ->
        promise = $confirm.confirm($i18next.t('common.are-you-sure'))
        promise.then () ->
            $scope.attachments = _.without($scope.attachments, attachment)
            attachment.remove()

    $scope.removeNewAttachment = (attachment) ->
        $scope.newAttachments = _.without($scope.newAttachments, attachment)

    loadAttachments = (projectId, issueId) ->
        promise = rs.getIssueAttachments(projectId, issueId)
        promise.then (attachments) ->
            $scope.attachments = attachments

    loadProjectTags = ->
        rs.getProjectTags($scope.projectId).then (data) ->
            $scope.projectTags = data

    openModal = ->
        loadProjectTags()
        if $scope.context.issue?
            $scope.form = $scope.context.issue
            loadAttachments($scope.projectId, $scope.form.id)
        else
            $scope.form = {
                status: $scope.project.default_issue_status
                type: $scope.project.default_issue_type
                priority: $scope.project.default_priority
                severity: $scope.project.default_severity
            }
        $scope.formOpened = true

        $scope.$broadcast("checksley:reset")
        $scope.$broadcast("wiki:clean-previews")

        $scope.overlay = $gmOverlay()
        $scope.overlay.open().then ->
            $scope.formOpened = false

    closeModal = ->
        $scope.formOpened = false

    @.initialize = (dfr, ctx) ->
        $scope.defered = dfr
        $scope.context = ctx
        openModal()

    @.delete = ->
        closeModal()
        $scope.form = form
        $scope.formOpened = true

    $scope.submit = gm.utils.safeDebounced $scope, 400, ->
        if $scope.form.id?
            promise = $scope.form.save(false)
        else
            promise = rs.createIssue($rootScope.projectId, $scope.form)
        $scope.$emit("spinner:start")

        promise.then (data) ->
            finishSubmit = ->
                $scope.$emit("spinner:stop")
                closeModal()
                $scope.overlay.close()
                $scope.defered.resolve($scope.form)
                $gmFlash.info($i18next.t('issue.issue-saved'))

            if $scope.newAttachments.length > 0
                saveNewAttachments($scope.projectId, data.id).then ->
                    finishSubmit()
            else
                finishSubmit()

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    $scope.close = ->
        $scope.formOpened = false
        $scope.overlay.close()

        if $scope.form.id?
            $scope.form.revert()
        else
            $scope.form = {}

    $scope.$on "select2:changed", (ctx, value) ->
        $scope.form.tags = value

    return


module = angular.module("taiga.controllers.issues", [])
module.controller("IssuesController", ['$scope', '$rootScope', '$routeParams', '$filter',
                  '$q', 'resource', "$data", "$confirm", "$modal", '$i18next',
                  '$location', 'SelectedTags', IssuesController])
module.controller("IssuesViewController", ['$scope', '$location', '$rootScope',
                  '$routeParams', '$q', 'resource', "$data", "$confirm", "$gmFlash", '$i18next',
                  'SelectedTags', IssuesViewController])
module.controller("IssuesModalController", ['$scope', '$rootScope', '$gmOverlay', 'resource',
                  "$gmFlash", "$i18next", "$confirm", "$q", IssuesModalController])
