# ********RoostGPT********

# Test generated by RoostGPT for test karate using AI Type Claude AI and AI Model claude-3-opus-20240229
# 
# Feature file generated for /laureates_get for http method type GET 
# RoostTestHash=41cb7e02aa
# 
# 

# ********RoostGPT********
Feature: Nobel Prize Laureates API

Background:
  * url {{ $processEnvironment.API_HOST }}

Scenario: Get all laureates with default parameters
  Given path '/2.1/laureates'
  When method get
  Then status 200
  And match response.laureates == '#array'
  And match each response.laureates contains { id: '#number', laureateIfPerson: '#object', laureateIfOrg: '#object', wikipedia: '#object', wikidata: '#object', sameAs: '#array', links: '#array', nobelPrizes: '#array' }
  And match response.meta == '#object'
  And match response.meta.offset == '#number'
  And match response.meta.limit == '#number'
  And match response.meta.count == '#number'
  And match response.links == '#array'
  And match each response.links contains { first: '#string', prev: '##string', self: '#string', next: '##string', last: '#string' }

Scenario: Get laureates with pagination
  Given path '/2.1/laureates'
  And param offset = 10
  And param limit = 5
  When method get
  Then status 200
  And match response.laureates == '#[5]'
  And match response.meta.offset == 10
  And match response.meta.limit == 5

Scenario: Get laureates with sorting
  Given path '/2.1/laureates'  
  And param sort = 'desc'
  When method get
  Then status 200
  And match response.meta.sort == 'desc'

Scenario: Get laureates by ID
  Given path '/2.1/laureates'
  And param ID = 100
  When method get
  Then status 200
  And match response.laureates[0].id == 100

Scenario: Get laureates by name
  Given path '/2.1/laureates'
  And param name = 'Marie Curie'
  When method get
  Then status 200
  And match response.laureates[*].laureateIfPerson.knownName.en contains 'Marie Curie'

Scenario: Get laureates by gender
  Given path '/2.1/laureates'
  And param gender = 'female'
  When method get
  Then status 200
  And match each response.laureates[*].laureateIfPerson.gender == 'female'

Scenario: Get laureates by Nobel Prize year
  Given path '/2.1/laureates'
  And param nobelPrizeYear = 2020
  When method get
  Then status 200
  And match each response.laureates[*].nobelPrizes[*].awardYear == 2020

Scenario: Get laureates with invalid parameters
  Given path '/2.1/laureates'
  And param invalid = 'test'
  When method get
  Then status 400
  And match response.code == 'Bad Request'
  And match response.message == 'Invalid query parameter'

Scenario: Get laureate with non-existent ID
  Given path '/2.1/laureates'
  And param ID = 999999
  When method get
  Then status 404
  And match response.code == 'Not Found'  
  And match response.message == 'No laureate found for provided ID'
