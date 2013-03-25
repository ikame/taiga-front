var IssuesController = function($scope, $rootScope, $routeParams, rs) {
    /* Global Scope Variables */
    $rootScope.pageSection = 'issues';
    $rootScope.pageBreadcrumb = ["Project", "Issues"];

    $scope.filtersOpened = false;
    $scope.issueFormOpened = false;

    /* Load unassigned user stories */

    var onIssuesLoaded = function(data) {
        $scope.issues = data;
        $scope.generateTagList();
        $scope.filterIssues();
    };

    rs.getIssues($routeParams.pid).
        then(onIssuesLoaded);

    /* Pagination variables */

    $scope.filteredItems = [];
    $scope.groupedItems = [];
    $scope.itemsPerPage = 10;
    $scope.pagedItems = [];
    $scope.currentPage = 0;

    $scope.sortingOrder = 'severity';
    $scope.reverse = false;

    /* Pagination methods */

    $scope.generateTagList = function() {
        var tagsDict = {};
        var tags = [];

        _.each($scope.issues, function(us) {
            _.each(us.tags, function(tag) {
                if (tagsDict[tag.id] === undefined) {
                    tagsDict[tag.id] = true;
                    tags.push(tag);
                }
            });
        });

        $scope.tags = tags;
    };

    $scope.filterIssues = function() {
        var selectedTags = _.filter($scope.tags, function(item) { return item.selected });
        var selectedTagsIds = _.map(selectedTags, function(item) { return item.id });

        if (selectedTagsIds.length > 0) {
            $scope.filteredIssues = _.filter($scope.issues, function(item) {
                var itemTagIds = _.map(item.tags, function(tag) { return tag.id; });
                var intersection = _.intersection(selectedTagsIds, itemTagIds);

                if (intersection.length === 0) return false;
                else return true;
            });
        } else {
            $scope.filteredIssues = $scope.issues;
        }

        $scope.groupToPages();
    };


    $scope.groupToPages = function() {
        $scope.pagedItems = [];

        for (var i = 0; i < $scope.filteredIssues.length; i++) {
            if (i % $scope.itemsPerPage === 0) {
                $scope.pagedItems[Math.floor(i / $scope.itemsPerPage)] = [ $scope.filteredIssues[i] ];
            } else {
                $scope.pagedItems[Math.floor(i / $scope.itemsPerPage)].push($scope.filteredIssues[i]);
            }
        }
    };

    $scope.prevPage = function () {
        if ($scope.currentPage > 0) {
            $scope.currentPage--;
        }
    };

    $scope.nextPage = function () {
        if ($scope.currentPage < $scope.pagedItems.length - 1) {
            $scope.currentPage++;
        }
    };

    $scope.setPage = function () {
        $scope.currentPage = this.n;
    };

    $scope.range = function(start, end) {
        var ret = [];
        if (!end) {
            end = start;
            start = 0;
        }
        for (var i = start; i < end; i++) {
            ret.push(i);
        }
        return ret;
    };

    $scope.selectTag = function(tag) {
        if (tag.selected) tag.selected = false;
        else tag.selected = true;

        $scope.currentPage = 0;
        $scope.filterIssues()
    }
};

IssuesController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];


var IssuesViewController = function($scope, $rootScope, $routeParams, resource) {

};

IssuesViewController.$inject = ['$scope', '$rootScope', '$routeParams', 'resource'];