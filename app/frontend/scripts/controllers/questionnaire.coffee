angular.module("frontendApp").controller "QuestionnaireController",
["$scope", "$mdDialog", "ServiceMatching", "lodash", ($scope, $mdDialog, ServiceMatching, _) ->
    
    $scope.static = false
    $scope.dynamic = false
    $scope.categoryChosen = false
    $scope.filteredServices = $scope.services
    $scope.selectedValues = []
    $scope.questions = []
    $scope.dynamicQuestions = []
    $scope.dropdownIcon = "keyboard_arrow_down"
    $scope.currentQuestion = ""

    # Dialog of info button in the main questionnaire view
    $scope.showInfo = () ->
        $mdDialog.show $mdDialog.alert({
            clickOutsideToClose: true
            title: "Info"
            content: "A dynamic selection is a questionnnaire
             based on the statistics of services properties.\n
            A static selection is a questionnaire with no
             dependency on the properties statistics."
            ariaLabel: "Alert Dialog Demo"
            ok: "Got it!"
        }).parent(angular.element(document.querySelector("#questionnnaire")))

    # When the type of questionnaire is shown
    # 1. Show this questionnaire
    # 2. Set the corresponding questions and current question
    $scope.showQuestionnaire = (qType) ->
        if (qType == "dynamic")
            $scope.dynamic = true
            $scope.questions = $scope.getDynamicQuestions()
        else if (qType == "static")
            $scope.static = true
            $scope.questions = $scope.getStaticQuestions()
        $scope.getQuestionsValues($scope.questions)
        $scope.currentQuestion = $scope.questions[0].key

    # Set the value of the chosen category and begin the questionnaire
    $scope.setServiceCategory = (category) ->
        $scope.categoryChosen = category
        $scope.updateSelection($scope.questions, $scope.questions[0], category)
        $scope.showNext(0)

    # # Update the array of filtered Serices
    # # Loop over all available services
    # # 1. If no values are selected for any property, services would be added directly
    # # 2. Else, check if service provide all properties that have selected values
    # # 3. If property provides unique answers, check the service value
    # # 4. Else, wait for the whole loop of selectedValues array to be done,
    # # 5. If one at least is equal to the service's value, add it
    # $scope.updateFilteredServices = (selectedValues) ->
    #     filteredServices = []
    #     for service in $scope.services
    #         addService = true
    #         for selectedValue in selectedValues
    #             # convert property key string to service property format
    #             property = (selectedValue.property.replace(/ /g, "_")).toLowerCase()
    #             if (!service[property])
    #                 addService = false
    #                 break
    #             else
    #                 if (selectedValue.uniqueAnswer)
    #                     if (!$scope.isServiceMatching(service, selectedValue))
    #                         addService = false
    #                         break
    #                 else
    #                     if (!$scope.isServiceMatching(service, selectedValue))
    #                         addService = false
    #                     else
    #                         addService = true
    #                         break
    #         if (addService)
    #             filteredServices.push(service)
    #     return filteredServices

    # Initialize the list of static questions
    $scope.getStaticQuestions = () ->
        staticQuestions = [
            {
                key: "Service Categories"
                q: "Choose service category"
                uniqueAnswer: true
                selectedValue: "I don't care"
                values: {}
            },
            {
                key: "Cloud Service Model"
                q: "Choose the cloud service model"
                uniqueAnswer: true
                selectedValue: "I don't care"
                values: {}
            },
            {
                key: "Payment Options"
                q: "Which payment option should the service provide?"
                uniqueAnswer: false
                selectedValue: ""
                values: {}
            },
            {
                key: "Can be used offline"
                q: "Should the cloud service provide offline usage?"
                uniqueAnswer: true
                selectedValue: "I don't care"
                values: {}
            },
            {
                key: "Free Trial"
                q: "Should the cloud service provide free trial?"
                uniqueAnswer: true
                selectedValue: "I don't care"
                values: {}
            },
            {
                key: "Storage Properties"
                q: "What is the maximum storage capacity needed?"
                uniqueAnswer: true
                selectedValue: "I don't care"
                values: {}
            }
        ]
        return staticQuestions

    # Initialize the list of dynamic questions
    $scope.getDynamicQuestions = () ->
        $scope.dynamicQuestions = []
        for key, property of $scope.enumerations
            if (property.statisticsInfo["Average Deviation from Uniform Distribution"])
                uniqueAnswer = ServiceMatching.checkIfUniqueValue(key, $scope.rows.enumRows)
                uniDistributionRatio = 1 - property.statisticsInfo["Average Deviation from Uniform Distribution"]
                providenceRatio = property.numOfServices / $scope.services.length
                rating = (uniDistributionRatio / 2) + (providenceRatio / 2)
                $scope.dynamicQuestions.push({
                    key: key
                    q: property.description
                    selectedValue: ""
                    uniqueAnswer: uniqueAnswer
                    rating: rating
                    uniDistributionRatio: uniDistributionRatio
                    providenceRatio: providenceRatio
                    values: {}
                })
        # Sort the questions in descending order according to the rating value
        $scope.dynamicQuestions.sort((q1, q2) ->
            q2.rating - q1.rating)
        return $scope.dynamicQuestions

    # Get the values of each question
    # 1. If the question key (property) is an enumeration
    # 1.1. Values are stored with numerical keys
    # 1.2. Descriptions of values are stored in an object with numerical key
    # 1.3. If question can have only unique value, add a value of "I don't care"
    # 2. If question key is not an enumeration, but is "storage properties"
    # 2.1. The values of this question are the max storage capacity
    # 3. For any other question
    # 3.1. The answer is yes or no
    $scope.getQuestionsValues = (questions) ->
        for question in questions
            if ($scope.enumerations[question.key])
                for key, value of $scope.enumerations[question.key]
                    if (!isNaN(key))
                        if (typeof value == "string")
                            question.values[value] = { "selected": false }
                        else if (typeof value == "object")
                            for i, item of value.description
                                question.values[i]["description"] = item
                if (ServiceMatching.checkIfUniqueValue(question.key, $scope.rows.enumRows))
                    question.values["None"] = {
                        "selected": true,
                        "description": "I don't care"
                    }
            else if (question.key == "Storage Properties")
                question.values = {
                    "10 GB": {
                        "selected": false,
                        "description": "10 GB"
                    },
                    "50 GB": {
                        "selected": false,
                        "description": "50 GB"
                    },
                    "100 GB": {
                        "selected": false,
                        "description": "100 GB"
                    },
                    "1 TB": {
                        "selected": false,
                        "description": "1 TB"
                    },
                    "5 TB": {
                        "selected": false,
                        "description": "5 TB"
                    },
                    "∞": {
                        "selected": false,
                        "description": "Unlimited"
                    },
                    "None": {
                        "selected": true,
                        "description": "I don't care"
                    }
                }
            else
                question.values = {
                    "Yes": {
                        "selected": false,
                        "description": "Yes"
                    },
                    "No": {
                        "selected": false,
                        "description": "No"
                    },
                    "None": {
                        "selected": true,
                        "description": "I don't care"
                    }
                }

    # Update the list of questions to be shown based on values' selection
    # 1. If no values are selected, start with the initialized array of dynamic questions
    # 2. Else, loop over the array of dynamic questions
    # 2.1. Loop over the array of selected values
    # 2.2. If the question is already in the selected values array, 
    # 2.2.1. add this question to the list, because it's a previous question
    # 2.3. If the question is not in the selected values array,
    # 2.3.1. break the loop as this is the question to considered (save index)
    # 3. Loop over dynamic questions starting from index, while index is < 7,
    # and no service provide the property of the considered question
    # 4. If all filtered services provide the question property, add question to the list
    # 5. Else, dismiss it and check the next
    $scope.updateDynamicQuestions = () ->
        questions = []
        questionSelected = false
        qIndex = 0
        if ($scope.selectedValues.length == 0)
            return $scope.dynamicQuestions
        for question in $scope.dynamicQuestions
            for selectedValue in $scope.selectedValues
                if (question.key == selectedValue.property)
                    questionSelected = true
                    break
            if (questionSelected)
                questions.push(question)
                questionSelected = false
                qIndex++
            else
                break
        propertyProvided = false
        while ((qIndex < $scope.dynamicQuestions.length - 1) && (qIndex < 7) && (!propertyProvided))
            question = $scope.dynamicQuestions[qIndex]
            # convert question key string to service property format
            property = (question.key.replace(/ /g, "_")).toLowerCase()
            for service in $scope.filteredServices
                if (service[property])
                    questions.push(question)
                    propertyProvided = true
                    break
            qIndex++
        return questions

    # When the selection of values for a question/filter property changes,
    # 1. If this question/filter property has unique selection option
    # 1.1. If exists, set previously selected value to false,
    # 1.2. and remove it from the selectedValues array
    # 1.3. Set selected property of the value to true
    # 2. If the property can have multipe values (checkbox)
    # 2.1. If the value is unchecked, remove it from the selectedValues array
    # 3. If a value is selected in any case
    # 3.1.  Add the newly selected value to the selectedValues array
    # 4. Update the number of filtered (rest) services for each value in each property
    # 5. If dynmaic questionnaire, update the list of questions
    # 6. Update the array of filtered services
    # 7. Update the array of shown properties in the filter
    $scope.updateSelection = (properties, property, valueKey) ->
        selected = true
        if (property.uniqueAnswer)
            i = properties.indexOf(property)
            for key, value of properties[i].values
                if (value.selected)
                    value.selected = false
                    j = _.findIndex($scope.selectedValues, {
                        property: property.key
                        value: key
                        uniqueAnswer: property.uniqueAnswer
                    })
                    $scope.selectedValues.splice(j, 1)
            properties[i].values[valueKey].selected = true
            if (valueKey == "None")
                selected = false
        else
            if (!property.values[valueKey].selected)
                selected = false
                j = _.findIndex($scope.selectedValues, {
                    property: property.key
                    value: valueKey
                    uniqueAnswer: property.uniqueAnswer
                })
                $scope.selectedValues.splice(j, 1)
        if (selected)
            $scope.selectedValues.push ({
                property: property.key
                value: valueKey
                uniqueAnswer: property.uniqueAnswer
            })
        for property in properties
            for key, value of property.values
                if (key != "None")
                    value.restServices = ServiceMatching.getRestServices(property, key, $scope.selectedValues, $scope.services, $scope.enumerations)
        if ($scope.dynamic)
            $scope.questions = $scope.updateDynamicQuestions()
        $scope.filteredServices = ServiceMatching.updateFilteredServices($scope.selectedValues, $scope.services, $scope.enumerations)

    # # Check if service matches value of given property
    # # 1. if the property is not an enumeration
    # # 1.1. if property is "storage properties", check sub-property "max_storage_capacity"
    # # 1.1.1. if selection is infinity and service is not, remove it
    # # 1.1.2. if service value is infinity, it won't be deleted at any case
    # # 1.1.3. if service value is less than selected, remove it (parseInt values)
    # # 1.2. Else check for yes or no answers
    # # 1.2.1. "free trial" property is checked through sub-property "has_free_trial"
    # # 1.2.2. If yes, property should be provided with true value
    # # 1.2.3. If no, property should be either null, false, or not provided at all
    # # 2. If service is an enumeration property
    # # 2.1. if the service doesn't provide the property, remove it
    # # 2.2. If service can have only unique value
    # # 2.2.1. check if service value is equal to the selected
    # # 2.3. If service can have multiple values
    # # 2.3.1. Loop over all service values of the property
    # # 2.3.2. Check if one value value at least is equal to the selected
    # $scope.isServiceMatching = (service, selectedValue) ->
    #     propertyKey = selectedValue.property
    #     value = selectedValue.value
    #     # convert question key string to service property format
    #     property = (propertyKey.replace(/ /g, "_")).toLowerCase()
    #     if (!$scope.enumerations[propertyKey])
    #         if (property == "storage_properties")
    #             if (service[property] == undefined)
    #                 return false
    #             else
    #                 serviceValue = service[property].max_storage_capacity
    #                 if (serviceValue == undefined)
    #                     return false
    #                 else if ((value == "∞") && (String(serviceValue) != value))
    #                     return false
    #                 else
    #                     if (String(serviceValue) != "∞")
    #                         serviceMaxStorage = (String(serviceValue).split(" "))
    #                         iServiceMaxStorage = parseInt(serviceMaxStorage[0])
    #                         if (serviceMaxStorage[1] == "TB")
    #                             iServiceMaxStorage = iServiceMaxStorage * 1000
    #                         selectedMaxStorage = value.split(" ")
    #                         iSelectedMaxStorage = parseInt(selectedMaxStorage[0])
    #                         if (selectedMaxStorage[1] == "TB")
    #                             iSelectedMaxStorage = iSelectedMaxStorage * 1000
    #                         if (iSelectedMaxStorage < iSelectedMaxStorage)
    #                             return false
    #         else
    #             if (value == "Yes")
    #                 if (service[property])
    #                     if ((property == "free_trial") && (service[property]["has_free_trial"]))
    #                         return true
    #                     else if ((property != "free_trial") && (service[property]))
    #                         return true
    #                 else
    #                     return false
    #             else # selected answer is "No"
    #                 if (!service[property])
    #                     return true
    #                 else
    #                     if ((property == "free_trial") && (service[property]["has_free_trial"]))
    #                         return false
    #                     else if ((property != "free_trial") && (service[property]))
    #                         return false
    #     else
    #         # check if property is provided by service
    #         if (service[property] == undefined)
    #             return false
    #         else
    #             if (selectedValue.uniqueAnswer)
    #                 if (String(service[property]) != value.toLowerCase())
    #                     return false
    #             else
    #                 for key, item of service[property]
    #                     if (item == value.toLowerCase())
    #                         return true
    #                 return false
    #                 # if (typeof(service[property]) == "Array")
    #     return true

    # Navigate to the next question (or skip)
    $scope.showNext = (index) ->
        if ((index < $scope.questions.length - 1) && (index < 6))
            $scope.currentQuestion = $scope.questions[index + 1].key

    # Navigate back to the previous question
    # 1. Change the value of the current question
    # 2. Going back should deselect the selected value of previous question
    # 3. If questionnaire is static, deselct values of current question as well
    # 4. If questionnaire is dynamic, remove current question from list
    $scope.showPrev = (index) ->
        if (index > 0)
            $scope.currentQuestion = $scope.questions[index - 1].key
            for key, value of $scope.questions[index - 1].values
                value.selected = false
            if (index < $scope.questions.length)
                if ($scope.static)
                    for key, value of $scope.questions[index].values
                        value.selected = false
                if ($scope.dynamic)
                    $scope.questions.splice(index, 1)
            if (index == 1)
                $scope.categoryChosen = false

    # # Check if a property value is unique, or a service can have multiple values
    # # For the given key of the property, check the statistics
    # # Calculate the summation of each value of the property
    # # If it is more than 100, then services can have multiple values,
    # # and the values are not unique
    # $scope.checkIfUniqueValue = (key) ->
    #     statisticsEnum = $scope.rows.enumRows[key]
    #     overallValue = 0
    #     for value in statisticsEnum
    #         overallValue += value.c[1].v
    #     if (overallValue > 100)
    #         return false
    #     return true

    # # Get number of filtered (rest) services if a value is selected
    # # 1. Add the given value to a copy of the selected values list
    # # 2. Get the list of filtered services based on the new selected values list
    # # 3. Return the number of services in the list
    # $scope.getRestServices = (property, valueKey) ->
    #     virtualSelectedValues = []
    #     for value in $scope.selectedValues
    #         virtualSelectedValues.push(value)
    #     virtualSelectedValues.push({
    #         property: property.key
    #         value: valueKey
    #         uniqueAnswer: property.uniqueAnswer
    #     })
    #     virtualFilteredServices = $scope.updateFilteredServices(virtualSelectedValues)
    #     return virtualFilteredServices.length
]