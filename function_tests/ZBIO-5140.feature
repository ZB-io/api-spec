Feature: Verify User Registration Functionality
Scenario: User Registration with valid details
Given a new user with 'name', 'email', 'password'
When I send a POST request to '/user/register' with user details
Then the response status code should be 201
And the response should contain 'User registration successful'

Scenario: User Registration with invalid details
Given a new user with missing or incorrect 'name', 'email', 'password'
When I send a POST request to '/user/register' with user details
Then the response status code should be 400
And the response should contain 'Invalid user details'

Scenario: Duplicate User Registration
Given a previously registered user with 'name', 'email', 'password'
When I send a POST request to '/user/register' with the same user details
Then the response status code should be 409
And the response should contain 'User already exists'
