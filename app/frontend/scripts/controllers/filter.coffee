angular.module("frontendApp").controller "FilterController",
["$scope", "$stateParams", "$mdDialog", "ServiceMatching", "lodash",
($scope, $stateParams, $mdDialog, ServiceMatching, _) ->

    $scope.filteredServices = $scope.services
    $scope.selectedValues = $stateParams.selectedValues
    $scope.questions = $stateParams.questions
    $scope.filterProperties = []
    $scope.shownProperties = []
    $scope.filterDroppeddown = false
    $scope.dropdownIcon = "keyboard_arrow_down"
    $scope.currentQuestion = ""

    # Show filter with shown filter properties & filtered cloud services
    $scope.showFilter = () ->
        console.log ($scope.questions)
        $scope.getFilterProperties()
        $scope.updateShownProperties()
        $scope.filteredServices = ServiceMatching.updateFilteredServices(
            $scope.selectedValues, $scope.services, $scope.enumerations)

    # When the selection of values for a question property changes,
    # 1. Get the updated array of selected values by calling service method
    # 2. Update the number of filtered (rest) services for each value in each property
    # 3. Update filtered service according to selected values
    # 4. Update the array of shown properties in the filter
    $scope.updateSelection = (properties, property, valueKey) ->
        $scope.selectedValues = ServiceMatching.updateSelection(
            $scope.selectedValues, properties, property, valueKey)
        for property in properties
            for key, value of property.values
                if (key != "None")
                    value.restServices = ServiceMatching.getRestServices(
                        property, key, $scope.selectedValues, $scope.services, $scope.enumerations)
        $scope.filteredServices = ServiceMatching.updateFilteredServices(
            $scope.selectedValues,$scope.services, $scope.enumerations)
        $scope.updateShownProperties()

    # Initialize the properties with their values of the filter
    # 1. Add all questions to the filter with their selected values
    # 2. Loop over all enumeration properties
    # 2.1. If enumeration is already a question, skip
    # 2.2. Else, create new filter property with unselected values
    $scope.getFilterProperties = () ->
        $scope.filterProperties = []
        for question in $scope.questions
            selectedValue = ""
            values = {}
            for key, value of question.values
                if (key == "None")
                    continue
                else
                    if (value.selected)
                        selectedValue = value.description
                    values[key] = value
            $scope.filterProperties.push({
                "key": question.key
                "uniqueAnswer": question.uniqueAnswer
                "selectedValue": selectedValue
                "values": values
            })
        propertyExists = false
        for key, property of $scope.enumerations
            for question in $scope.questions
                if (key == question.key)
                    propertyExists = true
                    break
            if (propertyExists)
                propertyExists = false
                continue
            else
                isUnique = ServiceMatching.checkIfUniqueValue(key, $scope.rows.enumRows)
                values = {}
                for i, value of property
                    if (!isNaN(i))
                        if (typeof value == "string")
                            values[value] = { "selected": false }
                        else if (typeof value == "object")
                            for j, item of value.description
                                values[j]["description"] = item
                                values[j]["restServices"] = ServiceMatching.getRestServices({
                                    key: key
                                    uniqueAnswer: isUnique
                                }, j, $scope.selectedValues, $scope.services, $scope.enumerations)
                $scope.filterProperties.push({
                    "key": key
                    "uniqueAnswer": isUnique
                    "selectedValue": ""
                    "values": values
                })

    # Check if property should be shown or hidden
    # If dropdown button is clicked, all properties should be shown
    # Else, show it if it is in the array of properties to show
    $scope.isInShownProperties = (property) ->
        if ($scope.filterDroppeddown)
            return true
        for shownProperty in $scope.shownProperties
            if (property.key == shownProperty)
                return true
        return false

    # Check which properties should be shown or hidden
    # In the filter, no more 6 properties should be shown,
    # unless property has selected value(s), or dropdown icon pressed
    # 1. If property has selected values, show it directly
    # 2. Else if questionnaire is static
    # 2.1. check if property is a question, if yes, add it to temp. array
    # 3. If questionnaire is dynamic, check the dynamic questions array
    # 3. If there are less than 6 properties shown,
    # 3.1. add the original questions if available
    # 3.2. or add from filter properties
    $scope.updateShownProperties = () ->
        $scope.shownProperties = []
        unselected = []
        hasPropertySelected = false
        for property in $scope.filterProperties
            for key, value of property.values
                if (value.selected)
                    $scope.shownProperties.push(property.key)
                    hasPropertySelected = true
                    break
            if (hasPropertySelected)
                hasPropertySelected = false
                continue
            else
                for question in $scope.questions
                    if (property.key == question.key)
                        unselected.push(property.key)
                        break
        i = 0
        while ($scope.shownProperties.length < 6)
            if (unselected[i])
                $scope.shownProperties.push(unselected[i])
            else
                if ($scope.shownProperties.indexOf($scope.filterProperties[i].key) < 0)
                    $scope.shownProperties.push($scope.filterProperties[i].key)
            i++

    # Toggle show/hide of filter properties
    # 1. Toggle the show/hide boolean
    # 2. Toggle the icon to be up/down
    $scope.toggleDropdown = () ->
        $scope.filterDroppeddown = !$scope.filterDroppeddown
        if ($scope.dropdownIcon == "keyboard_arrow_down")
            $scope.dropdownIcon = "keyboard_arrow_up"
        else if ($scope.dropdownIcon == "keyboard_arrow_up")
            $scope.dropdownIcon = "keyboard_arrow_down"

    # For questions/properties with unique answers/values,
    # clear selection of correspoding radio buttons
    $scope.clearSelection = (property) ->
        for key, value of property.values
            value.selected = false
        property.selectedValue = ""
        for selectedValue in $scope.selectedValues
            if (selectedValue.property == property.key)
                i = $scope.selectedValues.indexOf(selectedValue)
                $scope.selectedValues.splice(i, 1)
        for filterProperty in $scope.filterProperties
            for key, value of filterProperty.values
                value.restServices = ServiceMatching.getRestServices(filterProperty, key, $scope.selectedValues, $scope.services, $scope.enumerations)
        $scope.filteredServices = ServiceMatching.updateFilteredServices($scope.selectedValues, $scope.services, $scope.enumerations)
        $scope.updateShownProperties()

]