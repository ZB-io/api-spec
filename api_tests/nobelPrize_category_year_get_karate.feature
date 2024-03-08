# ********RoostGPT********

# Test generated by RoostGPT for test karate using AI Type Azure Open AI and AI Model roost-gpt4-32k
# 
# Feature file generated for /nobelPrize/{category}/{year}_get for http method type GET 
# RoostTestHash=9818bf6b39
# 
# 

# ********RoostGPT********
Feature: Validate NobelPrize API behaviour

Background:
  * url target = karate.env.API_HOST
  * def auth_header = { Authorization: '#(token)' }

Scenario Outline: Validate status code and response structure for GET request by category, year

  Given path '2.1/nobelPrize/', '<category>', '<year>'
  And headers auth_header
  And request read('nobelPrize_category_year_get_karate.csv')
  When method get
  Then status 200
  And match header Content-Type contains 'application/json'
  
  * def responseBody = response
  And match responseBody.nobelPrize.awardYear == '<awardYear>'
  And match responseBody.nobelPrize.prizeAmount == '<prizeAmount>'
  And match responseBody.nobelPrize.prizeAmountAdjusted == '<prizeAmountAdjusted>'
  And match each responseBody.nobelPrize.laureates == { id: '#number', portion: '#string', sortOrder: '#string' }

  * def validateString = function(str){ return str != null && str != '' && typeof str == 'string' }
  
  * assert validateString(responseBody.nobelPrize.category.en)
  * assert validateString(responseBody.nobelPrize.category.se)
  * assert validateString(responseBody.nobelPrize.category.no)

  * assert validateString(responseBody.nobelPrize.categoryFullName.en)
  * assert validateString(responseBody.nobelPrize.categoryFullName.se)
  * assert validateString(responseBody.nobelPrize.categoryFullName.no)
  
  * assert validateString(responseBody.nobelPrize.topMotivation.en)
  * assert validateString(responseBody.nobelPrize.topMotivation.se)
  * assert validateString(responseBody.nobelPrize.topMotivation.no)
  
  Examples:
    | category | year | awardYear | prizeAmount | prizeAmountAdjusted |
    | _________| _____| _________ | ___________ | ________________ |
