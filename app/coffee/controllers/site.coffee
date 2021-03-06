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

SiteAdminController = ($scope, $rootScope, $routeParams, $data, $gmFlash, $model,
                          rs, $confirm, $location, $i18next, config, $gmUrls) ->
    $rootScope.pageTitle = $i18next.t('common.admin-panel')
    $rootScope.pageSection = 'admin'
    $rootScope.pageBreadcrumb = [
        [$i18next.t('common.administer-site'), null],
    ]
    $scope.activeTab = "data"

    $scope.languageOptions = config.languageOptions

    $scope.isActive = (type) ->
        return type == $scope.activeTab

    $scope.setActive = (type) ->
        $scope.activeTab = type

    $scope.setMemberAs = (mbr, role) ->
        if role == 'owner'
            mbr.is_owner = true
            mbr.is_staff = true
        else if role == 'staff'
            mbr.is_owner = false
            mbr.is_staff = true
        else if role == 'normal'
            mbr.is_owner = false
            mbr.is_staff = false
        mbr.save().then ->
            $gmFlash.info($i18next.t("admin-site.role-changed"))
        mbr.save().then null, ->
            mbr.revert()
            $gmFlash.warn($i18next.t("admin-site.error-changing-the-role"))

    $scope.submit = ->
        extraParams = {
            url: "#{$gmUrls.api('sites')}",
            method: "POST"
        }
        promise = $scope.currentSite.save(false, extraParams)
        promise.then (data) ->
            $gmFlash.info($i18next.t("admin-site.saved-success"))
            $scope.site.data = data
            $rootScope.$broadcast('i18n:change')

        promise.then null, (data) ->
            $scope.checksleyErrors = data

    $scope.deleteProject = (project) ->
        promise = $confirm.confirm($i18next.t('common.are-you-sure'))
        promise.then () ->
            $model.make_model('site-projects', project).remove().then ->
                loadSite()

    $scope.openNewProjectForm = ->
        $scope.addProjectFormOpened = true
        $scope.newProjectName = ""
        $scope.newProjectDescription = ""
        $scope.newProjectSprints = ""
        $scope.newProjectPoints = ""

    $scope.closeNewProjectForm = ->
        $scope.addProjectFormOpened = false

    $scope.submitProject = () ->
        projectData = {
            name: $scope.newProjectName,
            description: $scope.newProjectDescription,
            total_story_points: $scope.newProjectPoints
            total_milestones: $scope.newProjectSprints
        }
        rs.createProject(projectData).then ->
            $gmFlash.info($i18next.t("admin-site.project-created"))
            $scope.addProjectFormOpened = false
            loadSite()

    loadMembers = () ->
        rs.getSiteMembers().then (members) ->
            $scope.members = members

    loadSite = () ->
        rs.getSite().then (site) ->
            $scope.currentSite = site

    loadMembers()
    loadSite()

    return


module = angular.module("taiga.controllers.site", [])
module.controller("SiteAdminController", ["$scope", "$rootScope",
                                          "$routeParams", "$data", "$gmFlash",
                                          "$model", "resource", "$confirm",
                                          "$location", "$i18next", "config",
                                          "$gmUrls", SiteAdminController])
