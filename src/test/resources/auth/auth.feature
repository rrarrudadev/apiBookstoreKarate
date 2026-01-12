Feature: Auth helper (cria usuário e gera token uma vez)

  Scenario: Criar usuário e gerar token
    * def baseUrl = karate.get('baseUrl')
    * def rand = java.util.UUID.randomUUID() + ''
    * def userName = 'user_' + rand
    * def password = 'Test@@123A1!'

    Given url baseUrl
    And path '/Account/v1/User'
    And request { userName: '#(userName)', password: '#(password)' }
    When method post
    Then status 201
    * def userId = response.userID

    Given url baseUrl
    And path '/Account/v1/GenerateToken'
    And request { userName: '#(userName)', password: '#(password)' }
    When method post
    Then status 200
    And match response.token == '#string'
    * def token = response.token
    * def auth =
      """
      {
        userId: "#(userId)",
        token: "#(token)",
        username: "#(userName)",
        password: "#(password)"

      }
      """
